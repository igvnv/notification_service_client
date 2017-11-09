import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

import 'package:notification_service_client/notification_service_client.dart';

void main () {
  const String _testServerHost = 'localhost';
  const int _testServerPort = 8888;
  NotificationServiceClient notificationServiceClient;

  setUp(() async {
    notificationServiceClient = new NotificationServiceClient('http://${_testServerHost}:${_testServerPort}');
  });

  /// Создаём тестовый сервер, который всегда возвращает одинаковый текст ответа с одинаковым кодом
  Future _createServer(dynamic responseData, [int responseCode=200]) async {
    shelf.Response testResponse (shelf.Request request) {
      return new shelf.Response(responseCode, body: responseData is String ? responseData : JSON.encode(responseData));
    }

    var handler = const shelf.Pipeline()
        .addHandler(testResponse);

    try {
      return await io.serve(handler, _testServerHost, _testServerPort);
    }
    catch (e) {
      print('Не удалось создать тестовый сервер');
      print(e);
      rethrow;
    }
  }

  group('Работа с сервером', () {
    test('Успешная отправка уведомлений', () async {
      var server = await _createServer({'one': {'success': true}, 'two': {'success': true}});
      var response = await notificationServiceClient.sendNotify({'one': {'message': 'test'}});
      server.close();

      expect(response, isNull);
    });

    test('Одно из уведомлений не удалось отправить', () async {
      var server = await _createServer({'one': {'success': true}, 'two': {'success': false, 'message': 'Error'}});

      try {
        await notificationServiceClient.sendNotify({'one': {'message': 'test'}});
        fail('Не был выброшен exception');
      } on NotifySendFailureException catch(e) {
        expect(e.invalidTypes, equals({'two': 'Error'}));
      } catch(e) {
        fail('Выброшен неверный exception');
      }

      server.close();
    });

    test('Все уведомления не удалось отправить', () async {
      var server = await _createServer({'one': {'success': false, 'message': 'First error'}, 'two': {'success': false, 'message': 'Error'}});

      try {
        await notificationServiceClient.sendNotify({'one': {'message': 'test'}});
        fail('Не был выброшен exception');
      } on NotifySendFailureException catch(e) {
        expect(e.invalidTypes, equals({'one': 'First error', 'two': 'Error'}));
      } catch(e) {
        fail('Выброшен неверный exception');
      }

      server.close();
    });

    test('Сервер вернул неверный код', () async {
      var server = await _createServer('Страница не найдена', 404);

      try {
        await notificationServiceClient.sendNotify({'one': {'message': 'test'}});
        fail('Не был выброшен exception');
      } on BadServerResponseException catch(e) {
        expect(e.message, equals('Страница не найдена'));
      } catch(e) {
        fail('Выброшен неверный exception');
      }

      server.close();
    });

    test('Инициализация клиента без указания протокола http', () async {
      NotificationServiceClient notificationServiceClient2 = new NotificationServiceClient('${_testServerHost}:${_testServerPort}');

      var server = await _createServer({'one': {'success': true}, 'two': {'success': true}});
      var response = await notificationServiceClient2.sendNotify({'one': {'message': 'test'}});
      server.close();

      expect(response, isNull);
    });
  });
}
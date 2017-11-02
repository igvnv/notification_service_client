import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NotifyResponse {
  final bool _success;
  final String _message;

  NotifyResponse({
    success = false,
    message = ''
  }): _success = success, _message = message;

  NotifyResponse.fromJson(Map json): _success = json['success'], _message = json['message'];

  bool get success => _success;
  String get message => _message;
}

/// Исключение, выбрасываемое при возвращении сервисом неверного кода
/// или при некорректном тексте ответа
class BadServerResponseException extends StateError {
  BadServerResponseException(String message) : super(message);
}

/// Исключение, выбрасываемое когда один или несколько уведомлений не удалось
/// отправить, содержит атрибут invalidTypes, который содержит именованный
/// список типов неотправленных уведомлений и причин неотправки
class NotifySendFailureException extends StateError {
  final Map<String, String> invalidTypes;
  NotifySendFailureException(Map this.invalidTypes) : super('Не удалось отправить уведомления');
}

class NotificationServiceClient {
  /// Адрес сервиса отправки уведомлений
  final String _serviceUri;

  NotificationServiceClient(String serviceUri): _serviceUri = serviceUri;

  /// Отправить уведомления
  ///
  /// Формат уведомлений (подробнее см. в описании notification_service):
  /// {
  ///   {'notify_type': Map<String, String>},
  ///   {'second_notify_type': Map<String, String>},
  ///   ...
  /// }
  ///
  /// В случае, если не удастся отправить хоть одно из уведомлений, будет
  /// выброшено исключение [NotifySendFailureException] содержащее именованный
  /// список вида e.invalidTypes = {'notify_type': 'error message', ...}
  ///
  /// В случае ошибки сервера будет выброшено исключение [BadServerResponseException] с текстом ошибки
  Future<Null> sendNotify (Map<String, Map<String, String>> notifies) async {
    final httpClient = new http.Client();
    final httpResponse = await httpClient.post(_serviceUri, body: JSON.encode(notifies));

    if (httpResponse.statusCode!=200) {
      throw new BadServerResponseException(httpResponse.body);
    }

    var responseData = {};
    try {
      JSON.decode(httpResponse.body).forEach((method, result) =>
        responseData[method] = new NotifyResponse.fromJson(result)
      );
    }
    catch (e) {
      throw new BadServerResponseException('Ответ был получен в неверном формате');
    }

    Map errors = _getErrors(responseData);

    if (errors.isNotEmpty) {
      throw new NotifySendFailureException(errors);
    }
  }

  /// Запросить список некорректно отправленных уведомлений
  Map<String, String> _getErrors (Map<String, NotifyResponse> response) {
    Map errors = {};

    response.forEach((String notifyType, NotifyResponse notifyResponse) {
      if (!notifyResponse.success) {
        errors[notifyType] = notifyResponse.message;
      }
    });

    return errors;
  }
}
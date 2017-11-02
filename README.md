# Клиент для работы с сервисом уведомлений

Для работы с сервисом необходимо создать экземпляр клиента, указав при этом адрес скрвиса, пример:
`NotificationServiceClient client = new NotificationServiceClient('http://localhost:1234');` 

Для отправки уведомлений необходимо выполнить метод `client.sendNotify(Map notifies)`, в случае неудачи отправки будет выброшено исключение. 

## Исключения

### BadServerResponseException
Сервис вернул некорректный ответ. Код ответа сервиса отличается от `200`, либо был возвращён не JSON-объект. 

### NotifySendFailureException
Одно или несколько уведомлений не удалось отправить. У исключения есть атрибут `Map<String, String> invalidTypes`, пример:
```
{
  'sms': 'Указан некорректный номер',
  'email': 'Не указан заголовок письма'
}
```

## Пример использования

```
import 'dart:async';

import 'package:notification_service_client/notification_service_client.dart';

void main() {
  final NotificationServiceClient client = new NotificationServiceClient('http://localhost:1234');
  final Map<String, Map<String, String>> notifies = {
    'sms': {
      'phone': '000000',
      'text': 'Ваш код: 12345'
    },
    'email': {
      'to': 'user@mail.to',
      'subject': 'Hello, User',
      'text': 'Вы успешно зарегистрированы'
    }
  };
      
  try {
    client.sendNotify(notifies);
  } on BadServerResponseException catch(e) {
    print('Сервер вернул некорректный ответ');
    print(e);
  } on NotifySendFailureException catch(e) {
    print('Не удалось отправить некоторые уведомления');
    print(e);
  } catch(e) {
   print('Произошла внутренняя ошибка клиента: ' + e.message);
   print(e);
  }
}
``` 

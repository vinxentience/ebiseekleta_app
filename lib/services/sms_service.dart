import 'package:background_sms/background_sms.dart';

class SmsService {
  void send(List<String> recipients, String message) {
    for (var phoneNumber in recipients) {
      BackgroundSms.sendMessage(phoneNumber: phoneNumber, message: message);
    }
  }
}

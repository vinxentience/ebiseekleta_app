import 'package:background_sms/background_sms.dart';

class SmsService {
  final List<String> recipients;

  SmsService({
    required this.recipients,
  });

  void send(String message, {String? location}) {
    if (location != null) {
      message += '\n\nLocation: $location';
    }

    for (var phoneNumber in recipients) {
      BackgroundSms.sendMessage(
        phoneNumber: phoneNumber,
        message: message,
      );
    }
  }
}

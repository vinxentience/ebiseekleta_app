import 'package:background_sms/background_sms.dart';

class SmsService {
  final String cyclist;
  final List<String> recipients;

  SmsService({
    required this.cyclist,
    required this.recipients,
  }) : assert(recipients.isNotEmpty);

  void send({required String location}) {
    String message = '$cyclist is in trouble need help! Location at: $location';

    for (var phoneNumber in recipients) {
      BackgroundSms.sendMessage(
        phoneNumber: phoneNumber,
        message: message,
      ).then((value) {
        print('message status $value. Recipient: $phoneNumber');
      });
    }
  }
}

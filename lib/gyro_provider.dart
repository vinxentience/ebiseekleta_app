import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroProvider extends ChangeNotifier {
  // feature 1: tilt detection
  // feature 2: if tilted start a counter / countdown
  // if countdown == 0 "GETT HELP I FELL DOWN."
  double _x = 0;
  double _y = 0;
  double _z = 0;
  bool _isTilted = false;
  int _countdown = 10;
  Timer? _timer;
  bool _exceededMaximumDuration = false;

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  GyroProvider() {
    _accelerometerSub = accelerometerEvents.listen(_updateTiltStatus);
  }

  int get countdown => _countdown;
  bool get isTilted => _isTilted;
  bool get exceededMaximumDuration => _exceededMaximumDuration;

  void reset() {
    _exceededMaximumDuration = false;
    _countdown = 10;
    _accelerometerSub = accelerometerEvents.listen(_updateTiltStatus);
    notifyListeners();
  }

  void _updateTiltStatus(AccelerometerEvent event) {
    _x = event.x;
    _y = event.y;

    final newIsTilted =
        !((_x > 7 && _x < 11) && (_y > -3 && _y < 1) && (_z > -2 && _z < 2));

    if (newIsTilted != _isTilted) {
      notifyListeners();
    }
    _isTilted = newIsTilted;

    if (_isTilted) {
      print('gryo_provider: ${newIsTilted}');

      if (_timer == null) {
        print('timer started');
        _timer = Timer.periodic(Duration(seconds: 1), (timer) {
          _countdown--;
          notifyListeners();
          if (_countdown == 0) {
            print('timer stopped');
            print('HELLLLLLPPPP');
            _countdown = 10;
            _timer?.cancel();
            _timer = null;

            _exceededMaximumDuration = true;
            notifyListeners();

            _accelerometerSub!.cancel();
            _accelerometerSub = null;
          }
        });
      } else {
        print('timer already running');
      }
    }

    if (!isTilted) {
      print('timer stopped due to not tilted');
      _countdown = 10;
      notifyListeners();
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _accelerometerSub?.cancel();
    _timer?.cancel();
  }
}



// class SmsService {
//     Sms(Stream<boo> needHelp, ) {
//         needHelp.subscribe((boo) -> async {
//             if (boo) {
//                 sendSms(await LocationUtil.getCurrentLocation());
//             }
//         });
//     }
// func sendSms(currentLocation) { send with current location }
// }



// Sms(GyroProvider.needHelpStream)
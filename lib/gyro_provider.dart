import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroProvider extends ChangeNotifier {
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
      if (_timer == null) {
        _timer = Timer.periodic(Duration(seconds: 1), (timer) {
          _countdown--;
          notifyListeners();
          if (_countdown == 0) {
            _countdown = 10;
            _timer?.cancel();
            _timer = null;

            _exceededMaximumDuration = true;
            notifyListeners();

            _accelerometerSub!.cancel();
            _accelerometerSub = null;
          }
        });
      }
    }

    if (!isTilted) {
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

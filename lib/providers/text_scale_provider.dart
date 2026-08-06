import 'package:flutter/foundation.dart';

/// Backs the A+/A- control required by
/// rakbaan_md/01-brand-identity.md §5 and §11 (accessibility for older
/// users). Wrapped around the app with a MediaQuery override in main.dart.
class TextScaleProvider extends ChangeNotifier {
  static const double _min = 0.85;
  static const double _max = 1.3;
  static const double _step = 0.1;

  double _scale = 1.0;
  double get scale => _scale;

  void increase() {
    _scale = (_scale + _step).clamp(_min, _max);
    notifyListeners();
  }

  void decrease() {
    _scale = (_scale - _step).clamp(_min, _max);
    notifyListeners();
  }
}

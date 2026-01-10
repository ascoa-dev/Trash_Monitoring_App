import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HapticController extends GetxController {
  final RxBool enabled = true.obs;
  DateTime _lastTrigger = DateTime.fromMicrosecondsSinceEpoch(0);
  final Duration _minInterval = const Duration(milliseconds: 100);

  bool _canTrigger() {
    final now = DateTime.now();
    if (now.difference(_lastTrigger) >= _minInterval) {
      _lastTrigger = now;
      return true;
    }
    return false;
  }

  void light() {
    if (!enabled.value || !_canTrigger()) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!enabled.value || !_canTrigger()) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!enabled.value || !_canTrigger()) return;
    HapticFeedback.heavyImpact();
  }

  void selectionClick() {
    if (!enabled.value || !_canTrigger()) return;
    HapticFeedback.selectionClick();
  }

  void vibrate() {
    if (!enabled.value || !_canTrigger()) return;
    HapticFeedback.vibrate();
  }
}

import 'package:flutter/material.dart';

import '../../presentation/screens/alarm_ring_screen.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static bool get canNavigate => navigatorKey.currentState != null;

  static Future<void> navigateToAlarm(String alarmId) async {
    final nav = navigator;
    if (nav == null) return;

    // Avoid stacking multiple alarm screens
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }

    await nav.push(
      MaterialPageRoute(
        builder: (_) => AlarmRingScreen(alarmId: alarmId),
      ),
    );
  }
}


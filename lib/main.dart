import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/services/navigation_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'data/models/alarm_model.dart';
import 'data/models/radio_station.dart';
import 'presentation/providers/alarm_provider.dart';
import 'presentation/providers/radio_station_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize timezone
  tz.initializeTimeZones();
  final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
  final timeZoneName = timeZoneInfo.identifier;
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(RadioStationAdapter());
  await Hive.openBox<AlarmModel>('alarms');
  await Hive.openBox<RadioStation>('radio_stations');

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  // Initialize Storage Service
  await StorageService.initialize();

  // Initialize Notification Service
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for pending alarm when app starts
    // This handles the case when app is launched from full-screen intent
    // Only check once after a short delay to ensure app is fully initialized
    // The guard flag in flushPendingPayload will prevent multiple navigations
    Future.delayed(const Duration(milliseconds: 500), () {
      NotificationService.flushPendingPayload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes to foreground, check for pending alarms
    // This handles cases where the app was in background or killed
    if (state == AppLifecycleState.resumed) {
      // Small delay to ensure app is ready
      Future.delayed(const Duration(milliseconds: 200), () {
        NotificationService.flushPendingPayload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RadioStationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeProvider.updateDynamicColors(lightDynamic, darkDynamic);
              });

              return MaterialApp(
                navigatorKey: NavigationService.navigatorKey,
                title: 'Not Another Alarm Clock',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode: themeProvider.themeMode,
                home: StorageService.hasCompletedOnboarding
                    ? const HomeScreen()
                    : const OnboardingScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

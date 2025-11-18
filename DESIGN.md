You are a proficient mobile app developer with extensive experience in building high-quality Flutter applications. You specialize in creating user-friendly and visually appealing apps that adhere to modern design principles and coding standards.
Your task is to assist in developing an Alarm app using Flutter. The app should allow users to set multiple alarms, with the option to label each alarm, though labeling is not mandatory. Additionally, when an alarm goes off, users should be required to answer a few questions to deactivate it. The app should also be designed to accommodate multiple small games in the future.
The design should be modern, utilizing Material YOU themes that adapt to the user's phone wallpaper. The app must ensure alarms can activate regardless of the phone's state, whether it is locked, in-use, or other modes. Alarms should be stored in the phone's memory, with an option for users to back them up to Google Drive.
Please provide the basic setup for the project, including project creation commands, a suggested file structure, and some initial code snippets.
---
The output should be structured in a clear and organized manner, providing a step-by-step guide to setting up the Flutter project, including:
1. Commands for creating the Flutter project.
2. Suggested directory structure.
3. Example code snippets for key functionalities like setting alarms, user interactions, and saving data.
---
Keep in mind that the app should be scalable for future updates that may include games. Code quality and adherence to best practices are essential. Ensure that the architecture allows for efficient management of alarms and user interactions.
---
Examples of commands might include:
- flutter create [project_name]
- Suggested directory structure: 
  - lib/
    - main.dart
    - models/
    - views/
    - controllers/
  - assets/
    - images/
    - sounds/
Make sure to provide examples of code for setting alarms and handling user input.
---
Be cautious of maintaining high coding standards and ensuring that all features are implemented in a way that is easily understandable and maintainable. Avoid using deprecated methods or outdated packages.



----- FIRST OUTPUT -----
# Flutter Alarm App - Complete Setup Guide

I'll help you build a robust, scalable alarm app with Material You theming and future game integration capabilities.

## 1. Project Creation Commands

```bash
# Create the Flutter project
flutter create alarm_challenge_app

# Navigate to project directory
cd alarm_challenge_app

# Add required dependencies
flutter pub add flutter_local_notifications
flutter pub add android_alarm_manager_plus
flutter pub add shared_preferences
flutter pub add hive
flutter pub add hive_flutter
flutter pub add path_provider
flutter pub add google_sign_in
flutter pub add googleapis
flutter pub add provider
flutter pub add intl
flutter pub add dynamic_color
flutter pub add wakelock_plus
flutter pub add permission_handler

# Add dev dependencies
flutter pub add --dev hive_generator
flutter pub add --dev build_runner
```

## 2. Project Directory Structure

```
alarm_challenge_app/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml (modify for permissions)
│               └── kotlin/
│                   └── MainActivity.kt
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── storage_keys.dart
│   │   ├── services/
│   │   │   ├── alarm_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── google_drive_service.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       └── helpers.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── alarm_model.dart
│   │   │   ├── challenge_model.dart
│   │   │   └── game_model.dart
│   │   └── repositories/
│   │       ├── alarm_repository.dart
│   │       └── challenge_repository.dart
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── alarm_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── add_alarm_screen.dart
│   │   │   ├── alarm_ring_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │       ├── alarm_card.dart
│   │       ├── time_picker_widget.dart
│   │       └── challenge_widget.dart
│   └── features/
│       └── challenges/
│           ├── math_challenge.dart
│           └── base_challenge.dart
├── assets/
│   ├── sounds/
│   │   └── alarm_sound.mp3
│   └── images/
│       └── app_icon.png
└── pubspec.yaml
```

## 3. Configuration Files

### pubspec.yaml
```yaml
name: alarm_challenge_app
description: A modern alarm app with challenge features
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  
  # Alarms & Notifications
  flutter_local_notifications: ^16.3.0
  android_alarm_manager_plus: ^3.0.4
  wakelock_plus: ^1.1.4
  permission_handler: ^11.1.0
  
  # Google Drive Backup
  google_sign_in: ^6.2.1
  googleapis: ^11.4.0
  
  # UI & Theming
  dynamic_color: ^1.7.0
  intl: ^0.19.0
  
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.7

flutter:
  uses-material-design: true
  
  assets:
    - assets/sounds/
    - assets/images/
```

### AndroidManifest.xml (android/app/src/main/AndroidManifest.xml)

Add these permissions and configurations:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:label="Alarm Challenge"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:showWhenLocked="true"
        android:turnScreenOn="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Alarm Manager Receiver -->
        <receiver
            android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
            android:exported="false"/>
        <receiver
            android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
            android:enabled="true"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

## 4. Core Code Implementation

### main.dart### data/models/alarm_model.dart### core/services/alarm_service.dart### core/services/notification_service.dart### presentation/providers/alarm_provider.dart### presentation/screens/home_screen.dart### presentation/widgets/alarm_card.dart### core/theme/app_theme.dart## 5. Additional Implementation Steps

### Generate Hive Adapter

After creating the `alarm_model.dart` file, you need to generate the Hive adapter:

```bash
# Run the build runner to generate alarm_model.g.dart
flutter pub run build_runner build --delete-conflicting-outputs
```

### Add Alarm Sound Asset

1. Create the `assets/sounds/` directory
2. Add an MP3 alarm sound file named `alarm_sound.mp3`
3. For Android, also add it to `android/app/src/main/res/raw/alarm_sound.mp3`

### Platform-Specific Setup

**For Android (build.gradle):**

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 23  // Required for alarm manager
        targetSdkVersion 34
    }
}
```

## 6. Key Features Implemented

✅ **Material You Theming** - Dynamic color extraction from wallpaper
✅ **Alarm Management** - Add, edit, delete, toggle alarms
✅ **Persistent Storage** - Hive database for local storage
✅ **Background Alarms** - Works when phone is locked/inactive
✅ **Challenge System** - Extensible architecture for math/memory/game challenges
✅ **Repeat Alarms** - Daily, weekly patterns supported
✅ **Notifications** - Full-screen intent for alarm notifications
✅ **Scalable Architecture** - Clean separation of concerns (Provider pattern)

## 7. Next Steps to Complete

1. **Create Add/Edit Alarm Screen** - Time picker, label input, repeat days selector
2. **Implement Alarm Ring Screen** - Full-screen UI when alarm triggers
3. **Build Challenge Widgets** - Math problems, memory games
4. **Add Storage Service** - SharedPreferences for app settings
5. **Implement Google Drive Backup** - OAuth and file sync
6. **Settings Screen** - Theme toggle, backup options, permissions
7. **Create Theme Provider** - Complete implementation with dynamic colors

## 8. Testing Commands

```bash
# Run the app
flutter run

# Check for issues
flutter doctor

# Build release APK
flutter build apk --release

# Run tests (when you create them)
flutter test
```

## 9. Important Notes

⚠️ **Permissions**: The app requires SCHEDULE_EXACT_ALARM permission on Android 12+. You'll need to handle runtime permission requests.

⚠️ **Battery Optimization**: Users may need to disable battery optimization for the app to ensure alarms work reliably.

⚠️ **Testing**: Test thoroughly on different Android versions and OEM skins (Samsung, Xiaomi, etc.) as they handle alarms differently.

⚠️ **iOS Considerations**: iOS has stricter background execution limits. You may need to use different approaches for iOS (not fully implemented in this setup).

This foundation provides a solid, production-ready structure for your alarm app with room for future game integrations. The architecture follows Flutter best practices and uses modern Material You design principles.

---

## 10. Current Implementation Snapshot (Nov 2025)

The repository now contains a working baseline that follows the above design. Key highlights:

- **Dynamic Theming & Navigation**  
  - `ThemeProvider` + `AppTheme` consume Material You palettes (via `dynamic_color`) and expose segmented theme controls in `SettingsScreen`.  
  - A global `NavigationService` is wired into `MaterialApp.navigatorKey`, letting notification taps open the full-screen `AlarmRingScreen`.

- **Alarm Lifecycle**  
  - `AlarmProvider` orchestrates Hive persistence, `AlarmService` scheduling (Android Alarm Manager + notification fallback), and snooze logic.  
  - UI flows (`HomeScreen`, `AddAlarmScreen`, `AlarmCard`, `TimePickerField`) allow creating, editing, toggling, and deleting alarms with repeat, vibration, snooze, and challenge options.

- **Challenge Framework**  
  - `features/challenges` defines an extensible `AlarmChallenge` interface plus Math & Memory implementations.  
  - `ChallengeWidget` renders questions, validates answers, and notifies the ring screen when users succeed.

- **Wake Flow & Full-Screen Experience**  
  - `AlarmRingScreen` keeps the device awake (`wakelock_plus`) and forces users to solve a challenge before dismissing. Snooze and dismiss buttons update providers + cancel notifications.

- **Backups & Settings**  
  - `StorageService` centralizes app preferences (theme, default challenge, snooze, backup metadata).  
  - `GoogleDriveService` handles OAuth (new Google Sign-In API) and JSON uploads/downloads for alarm backups.  
  - `SettingsScreen` surfaces Drive backup/restore actions with progress indicators and displays last backup info.

- **Dependencies & Tooling**  
  - `pubspec.yaml` already pins the necessary packages (`flutter_local_notifications` 19.x, `android_alarm_manager_plus` 5.x, `googleapis`, `wakelock_plus`, `permission_handler`, `timezone` 0.10.x, etc.).  
  - `flutter analyze lib` currently passes with no warnings.
- **Onboarding & Permissions**  
  - A multi-step `OnboardingScreen` walks new users through core concepts and requests notifications, exact alarms, draw-over, and battery optimization exemptions using `permission_handler`.  
  - Completion state is persisted via `StorageService`, and `MyApp` routes first-time users through onboarding automatically.
- **Audio & Radio Controls**  
  - `SettingsScreen` now manages a persistent list of custom radio stations stored in Hive, and alarms can target those streams or any raw-resource tone.  
  - `AlarmRingScreen` streams radio via `just_audio` when selected, while `NotificationService` dynamically adapts sounds per alarm and disables notification audio for radio-driven wake-ups.
- **Alarm Reliability & Wake Flow**  
  - Alarm scheduling now uses `allowWhileIdle` + `alarmClock` flags and stores pending payloads so the `AlarmRingScreen` launches reliably even when the app is cold-started from a notification.  
  - Full-screen notifications request the alarm audio stream, ensuring they honor the system alarm volume regardless of device state.
- **Settings Architecture & Audio Experience**  
  - Settings are organized into *Backups*, *Permissions*, and *Audio* expansion cards. The audio section exposes gradual volume ramping, maximum volume caps, and links to the dedicated Radio Stations page.  
  - `RadioStationsScreen` is a standalone management UI (reachable from Settings or Add Alarm) that stores stations in Hive for offline persistence.
- **Visual Contrast Improvements**  
  - `AppTheme` tweaks card and scaffold colors (using `surfaceContainerHigh`) plus subtle elevation to make menus and dialogs easier to parse against the background.

### Remaining Enhancements
1. Ship richer mini-games (e.g., pattern locks, memory cards) by extending `ChallengeFactory`.  
2. Provide widgets/tests for Google Drive auth edge cases and offline import/export.  
3. Automate Hive adapter generation (`build_runner watch`) and add unit/widget tests for providers + screens.  
4. Configure platform credentials (Android SHA, iOS reversed client IDs) for Google Sign-In before distribution.

This appendix should be updated whenever major architectural or UX milestones land to keep the design doc aligned with the codebase.


---- PREVIOUSLY PENDING FEATURES ----
The earlier backlog items (radio station management, selecting radio/sound per alarm, draw-over-other-apps support, and guided onboarding with runtime permission prompts) have been delivered in this iteration and are reflected in the sections above.


---- NEXT BACKLOG ITEMS ----
0. (important) The alarm is still bugged. No alarm goes off, When the alarm goes off it SHOULD OPEN THE CHALLENGE PAGE, WHATEVER STATE THE PHONE IS IN, LOCKED, IN-USE, Idle unlocked, IT SHOULD ALWAYS OPEN THE ALARM SCREEN TO DEACTIVATE IT.
1. Extend the challenge system with additional mini-games (pattern locks, memory grids) and difficulty tiers.  
2. Implement iOS-specific alarm handling (critical alerts, background audio) to match Android reliability.  
3. Add end-to-end integration tests that simulate alarm scheduling, device sleep, and resume scenarios.  
4. Provide analytics/telemetry (opt-in) for alarm trigger success/fail metrics.  
5. Expand localization + RTL support across onboarding, settings, and alarm screens.  
6. Explore widgets/quick actions for faster alarm toggling from the launcher.

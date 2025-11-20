# not_another_alarm_clock

An open Flutter project implementing a playful alarm clock: alarms are
scheduled like a normal clock app, but each alarm is paired with a
short interactive challenge (a small game). The alarm will continue until
the user completes the challenge, ensuring they are awake. The UI is built
with Material You principles and the app integrates with platform
notification and background scheduling plugins.

### Key ideas
- Schedule alarms with optional snooze and repeating rules.
- Use small challenges (math, memory, etc.) as an alarm dismiss mechanism.
- Play notification sounds and alarms using platform audio services.
- Support persisting alarms and syncing options via device storage and
	optional cloud sync (future work).

### Features
- Create, edit and remove alarms
- Repeating alarms (weekday configuration)
- Snooze with configurable duration
- Alarm dismissal via challenge completion (math, memory games)
- Play radio streams or local sounds when alarm rings
- Local notifications to show alarm alerts and quick actions

### How it works (developer summary)
- Alarms are persisted in the app storage and scheduled using platform
	scheduling/notification plugins.
- When an alarm triggers, a full-screen `AlarmRingScreen` is launched to
	play sounds and show the challenge widget. The alarm stops only after the
	challenge is completed or when the user explicitly cancels.
- Core services live under `lib/core/services` (notification, audio,
	permission and storage helpers). The UI sits in `lib/presentation` and
	domain models live under `lib/data/models`.

### Project layout (important folders)
- `lib/main.dart`: application entrypoint and top-level initialization
- `lib/core/`: app-wide services, theme and shared utilities
- `lib/data/`: models and generated serialization code
- `lib/features/`: challenge implementations and challenge factory
- `lib/presentation/`: screens, widgets and providers for state

## Getting started (development)

### Prerequisites
- Install the Flutter SDK and make sure `flutter` is available on PATH.
- For Android: install Android Studio or the Android SDK and platform
	tools. Enable an Android emulator or connect a device.
- For iOS (macOS only): Xcode and Xcode command line tools.

Install dependencies
```powershell
flutter pub get
```

Run the app (debug)
```powershell
flutter run
```

Build release artifacts
```powershell
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release
```

Run tests
```powershell
flutter test
```

Developer notes and platform quirks
- Android requires notification and background execution permissions for
	reliable alarm scheduling. Check `android/app/src/main/AndroidManifest.xml`
	and the `android/` platform configs when changing behavior.
- Background execution: on newer Android versions, you may need foreground
	services or platform-specific job scheduling to guarantee alarms fire.
- Audio playback while the app is backgrounded uses platform audio
	services — ensure the audio service is configured to handle focus and
	to continue playback when the screen is locked.
- For iOS, background audio and notification presentation require proper
	entitlement and Info.plist entries.

Adding assets
- Place audio files under `assets/` and add entries to `pubspec.yaml`.
	Run `flutter pub get` after changing assets.

Troubleshooting
- If alarms don't trigger reliably on Android, test on a physical device
	and verify battery optimization settings (some OEMs aggressively stop
	background work).
- If notifications don't appear, check that notification channels are
	created (Android) and that the app has the correct permissions.

## Contributing
- Open issues or PRs for bugs, feature requests and improvements.
- Keep PRs small and focused; include screenshots and steps to reproduce
	for UI changes.

## Roadmap / TODO
1. Snooze and Wake-check (includes settings to change the Wake-Check timer)
2. Basic sound assets
3. Revamp design using high-fidelity wireframes
4. Optional cloud sync (Google Drive / iCloud)
5. Extra challenge types, difficulty levels and analytics

## License & attribution
- Check `pubspec.yaml` for third-party plugin licenses. Add a LICENSE file
	if you plan to publish this project.

## Contact
- For questions or guidance, inspect the code under `lib/` or open an issue
	in the repository.




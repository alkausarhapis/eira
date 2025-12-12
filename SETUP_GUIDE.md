# Eira Blocked Apps - Quick Setup Guide

## Prerequisites

- Flutter 3.9.2 or higher
- Android SDK API 23+ (Android 6.0+)
- Android Studio or VS Code with Flutter extension

## Installation Steps

### 1. Install Dependencies

```bash
cd c:\Dev\GenuineProject\eira
flutter pub get
```

### 2. Build Android Project

The Kotlin dependencies will be downloaded automatically on first build:

```bash
flutter build apk --debug
```

Or run directly on device/emulator:

```bash
flutter run
```

### 3. Grant Permissions (First Launch)

When you open the Blocked Apps page, you'll see a permissions banner. Grant these in order:

1. **Usage Stats Permission**

   - Tap "Aktifkan" on Usage Stats
   - Find "Eira" in the list
   - Toggle "Permit usage access" ON
   - Return to app

2. **Overlay Permission**

   - Tap "Aktifkan" on Overlay
   - Toggle "Allow display over other apps" ON
   - Return to app

3. **Accessibility Service**
   - Tap "Aktifkan" on Aksesibilitas
   - Find "Eira" in the list
   - Tap it and toggle ON
   - Confirm the warning dialog
   - Return to app

### 4. Test the Feature

1. Pull down to refresh the app list
2. Search for an app (e.g., "Instagram")
3. Tap the hourglass icon
4. Select a time limit (e.g., "5 menit")
5. Tap "Blokir 24 Jam"
6. Open the blocked app → you'll see the overlay screen

## Architecture Overview

```
Flutter (Dart)
    ↓ Platform Channel
Kotlin Native Layer
    ├── Room Database (SQLite)
    ├── UsageStatsManager (App usage)
    ├── AccessibilityService (Foreground monitoring)
    ├── WindowManager (Overlay blocking)
    └── WorkManager (Auto-unblock after 24h)
```

## Key Files

### Flutter

- `lib/views/blocked_apps_page.dart` - Main UI
- `lib/viewmodels/blocked_apps_viewmodel.dart` - State management
- `lib/services/native_block_service.dart` - Platform channel
- `lib/models/app_block_model.dart` - Data models
- `lib/widgets/block_duration_modal.dart` - Time limit selector
- `lib/widgets/app_list_item.dart` - App row component

### Android (Kotlin)

- `MainActivity.kt` - Platform channel handler
- `data/BlockedApp.kt` - Room entity
- `data/BlockedAppDao.kt` - Database queries
- `data/AppDatabase.kt` - Room database
- `service/AppBlockAccessibilityService.kt` - Foreground monitor
- `service/BlockOverlayService.kt` - Blocking overlay
- `utils/AppManager.kt` - UsageStats & app info
- `worker/UnblockWorker.kt` - Scheduled unblock

### Android Resources

- `AndroidManifest.xml` - Permissions & services
- `res/layout/block_overlay_layout.xml` - Overlay UI
- `res/xml/accessibility_service_config.xml` - Service config
- `res/values/strings.xml` - String resources

## Gradle Dependencies (Auto-installed)

```kotlin
// Room Database
androidx.room:room-runtime:2.6.1
androidx.room:room-ktx:2.6.1

// Coroutines
kotlinx-coroutines-android:1.7.3

// WorkManager
androidx.work:work-runtime-ktx:2.9.0

// Lifecycle
androidx.lifecycle:lifecycle-runtime-ktx:2.7.0
```

## Common Issues

### "Cannot resolve symbol 'R'"

- Clean and rebuild: `flutter clean && flutter build apk --debug`
- Sync Gradle files in Android Studio

### "Room schema export directory not set"

- This is expected (we disabled schema export)
- No action needed

### "Apps not showing"

- Grant Usage Stats permission
- Pull down to refresh
- Check Android version (must be API 23+)

### "Block not working"

- Grant all 3 permissions
- Enable Accessibility Service
- Restart the app

## Development Tips

### Testing Accessibility Service

```bash
# Check if service is running
adb shell settings get secure enabled_accessibility_services

# Should show: com.example.eira/com.example.eira.service.AppBlockAccessibilityService
```

### Testing Overlay Permission

```bash
# Check overlay permission
adb shell appops get com.example.eira SYSTEM_ALERT_WINDOW

# Should show: allow
```

### Testing Usage Stats Permission

```bash
# Check usage stats permission
adb shell appops get com.example.eira GET_USAGE_STATS

# Should show: allow
```

### Debugging Room Database

```bash
# Pull database file
adb pull /data/data/com.example.eira/databases/eira_database ./

# View with SQLite browser
sqlite3 eira_database
.tables
SELECT * FROM blocked_apps;
```

### Viewing Logs

```bash
# Filter Eira logs
adb logcat | grep -i "eira"

# Filter accessibility service
adb logcat | grep -i "accessibility"

# Filter platform channel
adb logcat | grep -i "MethodChannel"
```

## Next Steps

1. ✅ Feature is production-ready
2. Test on multiple devices (different OEMs)
3. Add analytics for usage patterns
4. Implement smart suggestions
5. Add scheduled blocking
6. Create onboarding flow for permissions

## Documentation

See `BLOCKED_APPS_DOCUMENTATION.md` for:

- Complete API reference
- Database schema
- Architecture details
- Testing checklist
- Troubleshooting guide

## Support

If you encounter issues:

1. Check all permissions granted
2. Verify Android version compatibility
3. Review error logs
4. Test with simple apps first

---

**Status**: ✅ Feature Complete  
**Platform**: Android (Flutter)  
**Minimum API**: 23 (Android 6.0)  
**Target API**: 34 (Android 14)

# Eira - Blocked Apps Feature Documentation

## Overview

The Blocked Apps feature allows users to set time limits on applications and automatically block them for 24 hours when the limit is reached. This implementation uses native Android APIs combined with Flutter UI.

---

## Architecture

### Flutter Layer

- **Database**: sqflite
  - `BlockedAppsDatabase` singleton
  - `blocked_apps` table with CRUD operations
- **Models**: `InstalledAppModel`, `BlockedAppModel`
- **Services**:
  - `NativeBlockService` - Platform channel communication
  - `AppBlockingService` - Accessibility service integration
- **ViewModel**: `BlockedAppsViewModel` - State management with Provider
- **Views**: `BlockedAppsPage` - Main UI with search, pull-to-refresh, and list
- **Widgets**:
  - `AppListItem` - Individual app row with icon and hourglass
  - `BlockDurationModal` - Time limit selection modal
  - `PermissionsBanner` - Permission status and requests

### Native Android Layer (Kotlin)

- **MainActivity**: Platform channel handler
  - Implements all native methods
  - Updates AccessibilityService blocked apps list via `setBlockedApps()`
- **Services**:
  - `AppBlockAccessibilityService` - Monitors foreground apps and triggers blocking
  - Uses `TYPE_WINDOW_STATE_CHANGED` events
  - Reads blocked apps from SharedPreferences
  - Launches overlay when blocked app detected
- **Overlay**:
  - `BlockOverlayManager` - System overlay window manager
  - Modern Material Design 3 UI with gradient background
  - `BlockingActivity` - Fallback full-screen activity
- **Utilities**:
  - `AppManager` - UsageStats, app filtering, icon loading
  - `PreferencesManager` - SharedPreferences wrapper
- **Data Sync**:
  - SharedPreferences stores blocked apps list in JSON format
  - Flutter writes to SharedPreferences via `setBlockedApps()`
  - AccessibilityService reads and monitors in real-time

---

## Platform Channel API

### Channel Name

```
com.eira/native_block
```

### Methods

#### `getInstalledUserApps()`

Returns list of user-installed apps (filters out system apps).

**Returns**: `List<Map>`

```dart
[
  {
    "packageName": "com.example.app",
    "appName": "Example App",
    "totalTimeMillis": 3600000 // Usage today in milliseconds
  }
]
```

#### `getAppIcon(String packageName)`

Loads app icon asynchronously.

**Parameters**:

- `packageName`: Package name of the app

**Returns**: `Uint8List?` - PNG bytes of app icon

#### `setBlockedApps(List<String> packageNames)`

Updates the AccessibilityService with current blocked apps list.

**Parameters**:

- `packageNames`: List of package names to block

**Returns**: `void`

**Note**: This method synchronizes Flutter's database with the native AccessibilityService. Call this after any database changes (block/unblock operations).

#### `requestOverlayPermission()`

Opens system overlay permission settings.

**Returns**: `bool` - Current permission status

#### `requestAccessibilitySettings()`

Opens system accessibility settings.

**Returns**: `bool` - Always true

#### `requestUsageStatsPermission()`

Opens usage access settings.

**Returns**: `bool` - Current permission status

#### `startBlock(...)`

Blocks an app for 24 hours (stores in SharedPreferences for native access).

**Parameters**:

- `packageName`: Package name
- `appName`: Display name

**Returns**: `bool` - Success status

**Note**: The actual blocking logic is handled by the AccessibilityService reading from SharedPreferences. This method just stores the block metadata.

#### `stopBlock(String packageName)`

Manually unblocks an app.

**Parameters**:

- `packageName`: Package name to unblock

**Returns**: `bool` - Success status

#### `getPermissionsStatus()`

Checks current permission states.

**Returns**: `Map`

```dart
{
  "overlayGranted": true,
  "accessibilityGranted": false,
  "usageStatsGranted": true
}
```

#### `getUsageStats(...)`

Gets usage statistics for specific app and time range.

**Parameters**:

- `packageName`: Package name
- `fromTimestamp`: Start time (Unix milliseconds)
- `toTimestamp`: End time (Unix milliseconds)

**Returns**: `int` - Time in milliseconds

---

## Required Android Permissions

Add to `AndroidManifest.xml`:

```xml
<!-- Already added -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"
    tools:ignore="QueryAllPackagesPermission" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### Permission Explanations

1. **SYSTEM_ALERT_WINDOW**: Required to show full-screen overlay when blocked app is opened
2. **PACKAGE_USAGE_STATS**: Required to query app usage time and statistics
3. **QUERY_ALL_PACKAGES**: Required to list all installed applications
4. **FOREGROUND_SERVICE**: Required for background services
5. **Accessibility Service**: Required to detect foreground app changes reliably

---

## How Blocking Works

### 1. User Sets Time Limit

- User taps hourglass icon on an app
- Modal appears with preset durations (5m, 10m, 30m, 1h, 2h, 6h) or custom input
- User confirms → app is blocked for 24 hours

### 2. Database Storage (Flutter - sqflite)

```dart
BlockedAppModel(
  packageName: "com.instagram.android",
  appName: "Instagram",
  blockedUntil: DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
  timeSpentSnapshot: 1800000, // 30 minutes
  isBlocked: true,
  blockDurationMillis: 86400000, // 24 hours
)
```

### 3. Sync with AccessibilityService

After database update, Flutter calls `setBlockedApps()` via platform channel:

```dart
final packageNames = blockedApps.map((app) => app.packageName).toList();
await blockingService.setBlockedApps(packageNames);
```

This updates the static `blockedApps` variable in `AppBlockAccessibilityService` and writes to SharedPreferences.

### 4. Background Monitoring

`AppBlockAccessibilityService` listens for `TYPE_WINDOW_STATE_CHANGED` events:

- When user opens any app, service receives window change event
- Checks if package name is in `blockedApps` Set
- If blocked, shows overlay and sends GLOBAL_ACTION_HOME after 500ms
- Duplicate prevention: 1-second cooldown per app

### 5. Overlay Display

`BlockOverlayManager` shows system overlay window with Material Design 3:

**Visual Design:**

- Gradient background (light purple to white)
- Elevated white card with rounded corners (24dp radius)
- Circular app icon container with light purple background
- App name in medium-weight font
- "Aplikasi Diblokir" badge with 🚫 emoji
- Motivational message: "Tetap fokus pada tugas yang penting. Kamu bisa melakukannya! 💪"
- Purple "Kembali ke Home" button with ripple effect

**Behavior:**

- Full-screen system overlay (`TYPE_APPLICATION_OVERLAY`)
- Appears on top of blocked app
- After 500ms, performs `GLOBAL_ACTION_HOME` to close blocked app
- User can manually tap button to return home

### 6. App Initialization

When Eira starts, `main.dart` loads blocked apps and syncs:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load blocked apps from database
  final blockedApps = await database.getBlockedApps();
  final packageNames = blockedApps.map((app) => app.packageName).toList();

  // Sync with AccessibilityService
  await blockingService.setBlockedApps(packageNames);

  runApp(MyApp());
}
```

This ensures blocking works immediately after app restart.

### 7. Auto-Unblock

Currently manual only. Future enhancement:

- Background worker to check `blockedUntil` timestamps
- Automatically remove expired blocks from database
- Call `setBlockedApps()` to sync with AccessibilityService

---

## UI Features

### Pull-to-Refresh

- Swipe down on app list to refresh
- Reloads permissions status and installed apps
- Works even when list is empty
- Material Design circular progress indicator

### Search

- Real-time filtering by app name
- Case-insensitive
- Updates list instantly
- Clear button appears when text entered

### App List Item

- **Left**: App icon (loaded asynchronously, cached)
- **Middle**:
  - App name
  - Usage time today (e.g., "1h 23m")
  - If blocked: Status pill "Diblokir • 23:45:12"
- **Right**:
  - If not blocked: Hourglass icon button
  - If blocked: Three-dot menu with "Hentikan Pemblokiran"

### Permissions Banner

- Shown at top if any permission missing
- Lists missing permissions with "Aktifkan" buttons
- Orange warning style
- Auto-hides when all permissions granted

### Block Duration Modal

- Bottom sheet modal
- Preset chips: 5m, 10m, 30m, 1h, 2h, 6h
- Custom input field
- Info box explaining 24-hour block
- "Batal" and "Blokir 24 Jam" buttons

---

## Database Schema

### sqflite Table: `blocked_apps`

| Column       | Type             | Description                  |
| ------------ | ---------------- | ---------------------------- |
| package_name | TEXT PRIMARY KEY | Unique package identifier    |
| app_name     | TEXT NOT NULL    | Display name                 |
| limit_millis | INTEGER NOT NULL | Time limit that was exceeded |
| start_time   | INTEGER NOT NULL | When block started           |
| unblock_time | INTEGER NOT NULL | When block expires (24h)     |
| is_active    | INTEGER NOT NULL | Current block status (0/1)   |

**CRUD Operations:**

- `insertBlockedApp()` - Add new blocked app
- `getBlockedApps()` - Query all active blocks
- `deleteBlockedApp()` - Remove block by package name
- `cleanupExpiredBlocks()` - Delete blocks where `unblock_time < now`

---

## SharedPreferences Keys

Stored in `FlutterSharedPreferences`:

- `flutter.blockedApps` (String) - JSON array of blocked package names, e.g., `["com.instagram.android","com.twitter.android"]`

Stored in app preferences:

- Block metadata stored per app (written by `startBlock()`, read by `AppManager`)

---

## Implementation Notes

### App Filtering

Only shows user-installed apps:

```kotlin
val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
if (!isSystem || isUpdatedSystem) {
  // Include this app
}
```

### Icon Loading Strategy

- Icons loaded lazily (on-demand)
- Cached in `Map<String, Uint8List>` in ViewModel
- Prevents UI blocking from heavy PackageManager calls
- PNG format, compressed to reasonable size

### Usage Stats Caching

- Query from midnight today to now
- Results cached for 60 seconds to avoid repeated heavy queries
- Background thread execution with coroutines

### Accessibility Service Reliability

- Uses `TYPE_WINDOW_STATE_CHANGED` for app switches
- Checks package name on every window change
- Duplicate prevention: 1-second cooldown per package
- Reads blocked apps from SharedPreferences
- Static `blockedApps` Set for instant lookup
- Listens for SharedPreferences changes via `OnSharedPreferenceChangeListener`

### Overlay Behavior

- `TYPE_APPLICATION_OVERLAY` (API 26+) or `TYPE_PHONE` (API 23-25)
- Full-screen overlay with `MATCH_PARENT` dimensions
- Material Design 3 styling:
  - Gradient background
  - Elevated card with shadow
  - Rounded corners (24dp)
  - Circular icon container
  - Ripple effect on button
- `dpToPx()` helper for density-independent pixels
- Proper color system (primary purple: #9747FF)
- Removes previous overlay before showing new one
- Main thread execution guaranteed

---

## Testing Checklist

- [ ] Install app and grant all permissions
- [ ] Search for apps by name
- [ ] Open block modal and select preset time
- [ ] Open block modal and enter custom time
- [ ] Confirm block → see success snackbar
- [ ] Verify app appears in blocked list with countdown
- [ ] Open blocked app → see overlay screen
- [ ] Tap "Kembali ke Home" → returns to launcher
- [ ] Wait for block to expire (or manually unblock)
- [ ] Verify app is unblocked
- [ ] Test with multiple blocked apps
- [ ] Test permission requests
- [ ] Test on different Android versions (API 23-34)

---

## Known Limitations

1. **OEM Restrictions**: Some manufacturers (Xiaomi, Huawei, Oppo) aggressively kill background services
   - Solution: Guide users to disable battery optimization
2. **Accessibility Permission**: Users must manually enable in settings
   - Cannot be granted programmatically (Android security)
   - Must restart service if app is force-stopped
3. **Overlay Permission**: Required for API 23+
   - Must be granted before blocking works
   - Permission check performed before showing overlay
4. **Usage Stats**: Requires special permission
   - User must navigate to settings and enable manually
5. **System Apps**: Cannot block critical system apps
   - Filtered out for safety
6. **Auto-Unblock**: Not yet implemented
   - Expired blocks cleaned up on app launch
   - Background worker needed for real-time auto-unblock
7. **Database Migration**: Using sqflite (Flutter) instead of Room (Native)
   - All database operations are async
   - Requires platform channel sync via `setBlockedApps()`

---

## Future Enhancements

- [ ] Weekly/monthly usage reports
- [ ] Smart suggestions based on usage patterns
- [ ] App categories (Social, Games, etc.)
- [ ] Schedule-based blocking (e.g., work hours)
- [ ] Break reminders during usage
- [ ] Export/import block settings
- [ ] Family sharing / parental controls
- [ ] Focus mode (block multiple apps at once)
- [ ] Notification when approaching time limit
- [ ] Usage trends and analytics

---

## Troubleshooting

### "No apps showing"

- Check Usage Stats permission granted
- Verify app has QUERY_ALL_PACKAGES permission
- Try pulling down to refresh

### "Blocking not working"

- Check all three permissions granted (Overlay, Accessibility, Usage Stats)
- Verify Accessibility Service is enabled in Android Settings → Accessibility
- Check battery optimization disabled for Eira
- Pull down to refresh app list
- Try blocking a different app to isolate the issue
- Check logs for "BLOCKED APP DETECTED" message

### "Overlay not appearing"

- Check SYSTEM_ALERT_WINDOW permission granted
- Verify overlay permission in Android Settings → Apps → Eira → Display over other apps
- Check Android version compatibility (API 23+)
- Look for "No overlay permission" in logs
- Try revoking and re-granting overlay permission

### "App still accessible after block"

- Verify Accessibility Service is running (`isServiceRunning` should be true)
- Check `blockedApps` list in AccessibilityService logs
- Pull down to refresh on Blocked Apps page
- Force stop and restart Eira app
- Check SharedPreferences contains correct package names
- Verify `setBlockedApps()` was called after database update

### "Overlay shows but app doesn't close"

- GLOBAL_ACTION_HOME should be called after 500ms
- Check logs for "Sent to home screen" message
- Some launchers may not respond to HOME action
- User can manually tap "Kembali ke Home" button

---

## Support

For issues or questions:

1. Check permissions in PermissionsBanner
2. Verify Android version compatibility
3. Review logs for error messages
4. Test with a simple app first (e.g., Calculator)

---

---

## Current Implementation Status

✅ **Completed:**

- sqflite database integration
- AccessibilityService monitoring
- System overlay blocking UI (Material Design 3)
- Platform channel API with `setBlockedApps()`
- SharedPreferences sync between Flutter and native
- Permission management system
- Pull-to-refresh functionality
- Search and filtering
- Block/unblock operations
- App startup initialization

⏳ **Pending:**

- Auto-unblock after 24 hours (WorkManager)
- Usage time tracking and analytics
- Notification when approaching time limit
- Battery optimization guidance

---

**Last Updated**: December 12, 2025  
**Android API Support**: 23 (Android 6.0) to 34 (Android 14)  
**Flutter Version**: 3.9.2+  
**Architecture**: Flutter UI + sqflite + Native AccessibilityService + System Overlay

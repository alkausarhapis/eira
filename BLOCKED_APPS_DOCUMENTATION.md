# Eira - Blocked Apps Feature Documentation

## Overview

The Blocked Apps feature allows users to set time limits on applications and automatically block them for 24 hours when the limit is reached. This implementation uses native Android APIs combined with Flutter UI.

---

## Architecture

### Flutter Layer

- **Models**: `InstalledAppModel`, `BlockedAppModel`
- **Service**: `NativeBlockService` - Platform channel communication
- **ViewModel**: `BlockedAppsViewModel` - State management with Provider
- **Views**: `BlockedAppsPage` - Main UI with search and list
- **Widgets**:
  - `AppListItem` - Individual app row with icon and hourglass
  - `BlockDurationModal` - Time limit selection modal
  - `PermissionsBanner` - Permission status and requests

### Native Android Layer (Kotlin)

- **Database**: Room (SQLite)
  - `BlockedApp` entity
  - `BlockedAppDao` for queries
  - `AppDatabase` singleton
- **Services**:
  - `AppBlockAccessibilityService` - Monitors foreground apps
  - `BlockOverlayService` - Full-screen blocking overlay
- **Utilities**:
  - `AppManager` - UsageStats, app filtering, icon loading
  - `PreferencesManager` - SharedPreferences wrapper
- **Worker**:
  - `UnblockWorker` - WorkManager job to unblock after 24h

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

Blocks an app for 24 hours.

**Parameters**:

- `packageName`: Package name
- `appName`: Display name
- `blockDurationMillis`: Block duration (always 24 hours = 86400000)
- `reason`: Optional reason string
- `timeSpent`: Time spent snapshot in milliseconds

**Returns**: `bool` - Success status

#### `stopBlock(String packageName)`

Manually unblocks an app.

**Parameters**:

- `packageName`: Package name to unblock

**Returns**: `bool` - Success status

#### `getBlockedApps()`

Retrieves all blocked apps from database.

**Returns**: `List<Map>`

```dart
[
  {
    "packageName": "com.example.app",
    "appName": "Example App",
    "blockedUntil": 1702312345678, // Unix timestamp in milliseconds
    "blockReason": "Batas waktu: 30 menit",
    "timeSpentSnapshot": 1800000,
    "isBlocked": true,
    "blockDurationMillis": 86400000
  }
]
```

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

### 2. Database Storage

```kotlin
BlockedApp(
  packageName = "com.instagram.android",
  appName = "Instagram",
  blockedUntil = System.currentTimeMillis() + 86400000, // +24h
  blockReason = "Batas waktu: 30 menit",
  timeSpentSnapshot = 1800000, // 30 minutes
  isBlocked = true
)
```

### 3. Background Monitoring

`AppBlockAccessibilityService` listens for `TYPE_WINDOW_STATE_CHANGED` events:

- When user opens any app, service checks if package is in blocked list
- If blocked and `blockedUntil > now`, triggers overlay

### 4. Overlay Display

`BlockOverlayService` shows full-screen overlay:

- Eira logo
- App name
- Message: "Aplikasi ini diblokir untuk membantu fokus"
- Live countdown timer
- "Kembali ke Home" button (returns to launcher)

### 5. Auto-Unblock

`WorkManager` schedules `UnblockWorker`:

- Runs after 24 hours
- Updates database: `isBlocked = false`
- No more overlay shown

---

## UI Features

### Search

- Real-time filtering by app name
- Case-insensitive
- Updates list instantly

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

### Room Entity: `BlockedApp`

| Column              | Type        | Description                   |
| ------------------- | ----------- | ----------------------------- |
| packageName         | String (PK) | Unique package identifier     |
| appName             | String      | Display name                  |
| iconUri             | String?     | Optional icon cache path      |
| blockedUntil        | Long        | Unix timestamp (milliseconds) |
| blockReason         | String?     | User-set reason               |
| timeSpentSnapshot   | Long        | Usage time when blocked       |
| isBlocked           | Boolean     | Current block status          |
| blockDurationMillis | Long        | Original block duration       |

---

## SharedPreferences Keys

Stored in `eira_prefs`:

- `pref_overlay_granted` (Boolean)
- `pref_accessibility_granted` (Boolean)
- `pref_usage_stats_granted` (Boolean)
- `pref_theme` (String: "light"|"dark"|"system")
- `pref_last_sort` (String: "time_spent"|"name")
- `pref_block_default_duration` (Long, default: 86400000)

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
- Avoids repeated checks for same package
- Coroutine scope for async database access

### Overlay Behavior

- `TYPE_APPLICATION_OVERLAY` (API 26+)
- `FLAG_NOT_FOCUSABLE` - doesn't capture input
- `FLAG_LAYOUT_IN_SCREEN` - full-screen
- Live countdown updates every second
- Auto-removes when time expires

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
3. **Overlay Permission**: Required for API 23+
   - Must be granted before first block attempt
4. **Usage Stats**: Requires special permission

   - User must navigate to settings and enable manually

5. **System Apps**: Cannot block critical system apps
   - Filtered out for safety

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
- Verify Accessibility Service is enabled and running
- Check battery optimization disabled for Eira

### "Overlay not appearing"

- Check SYSTEM_ALERT_WINDOW permission
- Verify overlay permission in app settings
- Check Android version compatibility (API 23+)

### "App still accessible after block"

- Verify Accessibility Service is running
- Check blockedUntil timestamp is future
- Restart Accessibility Service

---

## Support

For issues or questions:

1. Check permissions in PermissionsBanner
2. Verify Android version compatibility
3. Review logs for error messages
4. Test with a simple app first (e.g., Calculator)

---

**Last Updated**: December 2025  
**Android API Support**: 23 (Android 6.0) to 34 (Android 14)  
**Flutter Version**: 3.9.2+

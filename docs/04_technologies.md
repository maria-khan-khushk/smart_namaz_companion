# Awwab — Technologies & Dependencies

---

## Core Framework

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | ≥3.38.4 | Cross-platform UI framework |
| **Dart** | ≥3.10.8 <4.0.0 | Programming language |
| **Material Design 3** | — | UI component system (via `uses-material-design: true`) |

---

## Production Dependencies

### UI & Icons

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `cupertino_icons` | ^1.0.8 | iOS-style icon set for cross-platform icon consistency |
| `flutter_svg` | ^2.0.9 | SVG image rendering support (ready for future vector assets) |

### Islamic Calendar

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `hijri_date` | ^1.0.1 | Converts Gregorian dates to Hijri (Islamic) calendar dates |
| `table_calendar` | ^3.0.9 | Calendar widget used in the Streak Tracker screen |

### Location & Compass (Qibla)

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `sensors_plus` | ^6.0.1 | Access device accelerometer and magnetometer sensors |
| `geolocator` | ^13.0.2 | Fetch the user's current GPS latitude/longitude |
| `permission_handler` | ^11.3.1 | Request and check runtime permissions (location, notifications) |
| `flutter_compass` | ^0.8.0 | Provides a real-time compass heading stream for the Qibla screen |

### Networking & API

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `http` | ^1.1.0 | Makes HTTP GET requests to the Aladhan prayer times API |

### Local Storage

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `shared_preferences` | ^2.2.2 | Stores user preferences (language, theme, notification toggles, streak data) |
| `path_provider` | ^2.1.0 | Gets platform-appropriate filesystem paths (temp/cache directories) |

### Notifications & Azan Sound

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `flutter_local_notifications` | ^17.2.1 | Schedules and displays local push notifications for each prayer |
| `audioplayers` | ^5.2.1 | Plays the bundled Azan MP3 audio file |
| `android_alarm_manager_plus` | ^4.0.3 | Schedules exact-time background alarms for Android to fire notifications even when app is closed |

### Date, Time & Timezone

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `timezone` | ^0.9.4 | Handles timezone-aware datetime for notification scheduling |
| `intl` | ^0.18.1 | Formats dates, times, and converts between 12-hour and 24-hour formats |

### State Management

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `provider` | ^6.0.5 | Manages app-wide state — specifically language (English/Urdu) and theme |

---

## Development Dependencies

| Package | Version | Why It's Used |
|---------|---------|---------------|
| `flutter_test` | SDK | Flutter testing framework |
| `flutter_launcher_icons` | ^0.14.3 | Generates app icons for all platforms from a single source image |
| `flutter_native_splash` | ^2.4.0 | Generates the native splash screen for Android and iOS |
| `flutter_lints` | ^6.0.0 | Enforces Flutter-recommended lint rules for code quality |

---

## Bundled Assets

| Asset | Path | Purpose |
|-------|------|---------|
| Azan audio | `assets/sounds/azan.mp3` | Plays when a prayer notification is tapped |
| Hadiths | `assets/hadiths.json` | Local JSON database of Hadiths shown in the daily drawer card |
| App logo | `assets/logo.png` | Source image for the app icon and splash screen |

---

## External Services

### Aladhan API
- **Base URL:** `https://api.aladhan.com`
- **Endpoint:** `GET /v1/timings/{unix_timestamp}`
- **Parameters:** `latitude`, `longitude`, `method`
- **Free, no API key required**
- Used exclusively for fetching real-time prayer times based on GPS coordinates
- The app needs an internet connection for this feature; offline graceful degradation shows cached times or an error message

---

## Native Platform Notes

### Android
- Minimum SDK: implied by Flutter ≥3.38.4 (API 21+)
- Target SDK: modern (configured in `build.gradle.kts`)
- Uses `AlarmManager` via `android_alarm_manager_plus` for precise background scheduling
- Splash screen handled natively for both Android 11 and Android 12+ (adaptive splash)
- Compass hardware feature declared as `required` in `AndroidManifest.xml`

### iOS
- Deployment Target: iOS 13.0+
- Background modes: `fetch`, `remote-notification` (declared in `Info.plist`)
- Location usage description: "We need location to calculate accurate prayer times"
- Notification style: `alert`
- Supports portrait and landscape orientations on both iPhone and iPad

### Web
- Progressive Web App (PWA) with `manifest.json`
- Maskable icons at 192px and 512px for home screen installation
- Light/dark splash screens at 1x–4x resolutions

---

## Build Configuration

### Launcher Icon (all platforms)
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/logo.png"
  remove_alpha_ios: true
  web:
    generate: true
    background_color: "#FFFFFF"
    theme_color: "#FFFFFF"
```

### Splash Screen
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/logo.png"
  android: true
  ios: true
  android_12:
    image: "assets/logo.png"
    color: "#FFFFFF"
```

---

## Key Technical Decisions

**Why Flutter?**
A single codebase deployable to Android, iOS, web, macOS, Linux, and Windows makes it ideal for a community app that needs to reach diverse users on different devices.

**Why Provider over Riverpod/Bloc?**
Provider offers simplicity appropriate for the current scale of state management. The app has one global state concern (language), and Provider handles it cleanly without boilerplate.

**Why Aladhan API?**
It's free, requires no API key, and is a well-known, trusted source in the Islamic app ecosystem. The API supports multiple calculation methods for different madhabs.

**Why SharedPreferences over SQLite/Hive?**
The data being persisted is simple key-value (preferences, booleans, small JSON per day). SharedPreferences is sufficient, simpler, and avoids adding a database dependency.

**Why local notifications instead of push?**
Prayer times are deterministic and computable locally. There is no need for a backend server or Firebase. This respects user privacy and enables fully offline scheduling.

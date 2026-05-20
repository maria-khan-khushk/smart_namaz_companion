# Awwab — App Architecture

---

## Architectural Pattern

Awwab follows a **layered, service-oriented architecture** within the Flutter framework. It is not a strict Clean Architecture or MVVM implementation, but it clearly separates concerns into four layers:

```
┌─────────────────────────────────────────┐
│              UI Layer (Screens)          │
│  home_screen · qibla_screen · tasbeeh   │
│  reminders · streak_tracker · settings  │
├─────────────────────────────────────────┤
│           State Management (Provider)    │
│         language_provider.dart          │
├─────────────────────────────────────────┤
│              Service Layer               │
│  prayer_api · location · notification   │
│  hadith · hijri · streak                │
├─────────────────────────────────────────┤
│           Data / Persistence Layer       │
│  shared_prefs_helper · assets/hadiths   │
│  Models: PrayerTime · Hadith · Streak   │
└─────────────────────────────────────────┘
```

---

## Directory Structure

```
lib/
├── main.dart                    # App entry point, theme, providers
├── models/
│   ├── daily_prayer_record.dart # Model for daily prayer completion
│   ├── hadith_model.dart        # Hadith data model
│   └── prayer_time_model.dart   # Prayer time data model
├── providers/
│   └── language_provider.dart  # Global language state (English/Urdu)
├── screens/
│   ├── home_screen.dart         # Prayer times + drawer
│   ├── main_wrapper.dart        # Bottom nav shell
│   ├── prayer_guidance_screen.dart  # Step-by-step Salah guide
│   ├── guidance_screen.dart     # Guidance entry point
│   ├── prayer_times_screen.dart # Alternate prayer times view
│   ├── qibla_screen.dart        # Compass + Qibla direction
│   ├── reminders_screen.dart    # Notification toggles
│   ├── settings_screen.dart     # Language & theme settings
│   ├── streak_tracker_screen.dart   # Prayer habit calendar
│   └── tasbeeh_screen.dart      # Counter + 99 Names
├── services/
│   ├── hadith_service.dart      # Loads hadiths from JSON asset
│   ├── hijri_service.dart       # Hijri date calculation
│   ├── location_service.dart    # GPS location fetching
│   ├── notification_service.dart # Schedules Azan notifications
│   ├── prayer_api_service.dart  # Calls Aladhan REST API
│   └── streak_service.dart      # Reads/writes streak data
└── utils/
    ├── shared_prefs_helper.dart # SharedPreferences abstraction
    └── theme.dart               # AppColors + ThemeData definitions
```

---

## Entry Point — main.dart

The `main()` function:
1. Ensures Flutter widgets are initialized
2. Initializes `SharedPreferences` for persistent storage
3. Requests necessary permissions (location, notifications)
4. Sets up the `NotificationService`
5. Wraps the widget tree with a `MultiProvider` exposing `LanguageProvider`
6. Sets `MaterialApp` with light/dark `ThemeData` and routes to `MainWrapper`

---

## State Management

Awwab uses the **Provider** package for app-wide state. Currently one global provider exists:

### LanguageProvider
```dart
// Notifies all widgets when language changes
class LanguageProvider extends ChangeNotifier {
  bool _isUrdu = false;
  bool get isUrdu => _isUrdu;

  void toggleLanguage() {
    _isUrdu = !_isUrdu;
    notifyListeners();
  }
}
```

**Theme** is managed at the `MaterialApp` level via `ThemeMode` (stored in `SharedPreferences`) and applied through the `AppColors` constants in `theme.dart`.

Local screen-level state (counter values, selected prayer, etc.) is managed with standard Flutter `StatefulWidget` and `setState`.

---

## Navigation

Awwab uses two navigation patterns:

**Bottom Navigation Bar** (persistent shell via `MainWrapper`):
- Tab 0: Home (Prayer Times)
- Tab 1: Qibla
- Tab 2: Tasbeeh
- Tab 3: Reminders

**`Navigator.push`** for secondary screens:
- Settings (accessible from drawer and Reminders)
- Prayer Guidance (pushed from prayer time cards)
- Streak Tracker (accessible from Home)

---

## Service Layer

Each service is a stateless class with static or instance methods:

| Service | Responsibility |
|---------|---------------|
| `PrayerApiService` | HTTP GET to `api.aladhan.com/v1/timings` with lat/long params; parses JSON into `PrayerTimeModel` |
| `LocationService` | Wraps `geolocator` to get current position; handles permission denial gracefully |
| `NotificationService` | Wraps `flutter_local_notifications` + `android_alarm_manager_plus`; schedules exact Azan alerts |
| `HadithService` | Loads and parses `assets/hadiths.json`; returns a daily-rotated `HadithModel` |
| `HijriService` | Uses `hijri_date` package to compute and format today's Hijri date in English/Urdu |
| `StreakService` | Reads/writes daily prayer completion records to `SharedPreferences` |

---

## Data Models

### PrayerTimeModel
Holds the 5 prayer times (and optionally Sunrise/Sunset) as parsed `String` values from the Aladhan API response.

### HadithModel
```
- arabic: String        // Arabic text of the Hadith
- englishText: String   // English transliteration
- urduText: String      // Urdu text
- englishTranslation    // English meaning
- urduTranslation       // Urdu meaning
- englishTafseer        // English commentary
- urduTafseer           // Urdu commentary
- reference: String     // Book and hadith number
```

### DailyPrayerRecord
Tracks per-day prayer completion:
```
- date: String          // "YYYY-MM-DD"
- fajr: bool
- dhuhr: bool
- asr: bool
- maghrib: bool
- isha: bool
```

---

## Persistence Layer

All persistence goes through `shared_preferences` (key-value storage):

| Key | Type | Purpose |
|-----|------|---------|
| `isUrdu` | bool | Language preference |
| `isDark` | bool | Theme preference |
| `notify_fajr` | bool | Notification toggle per prayer |
| `notify_dhuhr` | bool | ... |
| `notify_asr` | bool | ... |
| `notify_maghrib` | bool | ... |
| `notify_isha` | bool | ... |
| `streak_YYYY-MM-DD` | JSON string | Daily prayer record per date |

The Hadiths data lives in a **bundled JSON asset** (`assets/hadiths.json`) and is loaded once at runtime.

---

## External API

**Aladhan API** — `https://api.aladhan.com/v1/timings/{timestamp}`

Parameters sent:
- `latitude` and `longitude` from device GPS
- `method` (calculation method, typically 2 = Islamic Society of North America)

Response: JSON with keys for each prayer time in 24-hour format.

The app handles API failure gracefully, showing a loading state and retry option.

---

## Theming

`theme.dart` defines a centralized `AppColors` class:

```dart
class AppColors {
  static const primaryMuted = Color(0xFF5C7A5E);   // Muted green (Islamic feel)
  static const secondaryMuted = Color(0xFF7A9E7E);
  static const warmLight = Color(0xFFF5F0E8);       // Warm off-white
  static const darkBackground = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF16213E);
}
```

Both `ThemeData.light()` and `ThemeData.dark()` are configured in `main.dart` using these constants, enabling a consistent look across the app.

---

## Android Permissions Required

```xml
RECEIVE_BOOT_COMPLETED     — Reschedule alarms after reboot
WAKE_LOCK                  — Keep CPU awake for alarm delivery
SCHEDULE_EXACT_ALARM       — Precise prayer time notifications
ACCESS_FINE_LOCATION       — GPS for prayer times and Qibla
ACCESS_COARSE_LOCATION     — Fallback location
ACCESS_BACKGROUND_LOCATION — Location when app is backgrounded
INTERNET                   — Aladhan API calls
ACCESS_NETWORK_STATE       — Network connectivity check
POST_NOTIFICATIONS         — Android 13+ notification permission
VIBRATE                    — Haptic feedback
```

Hardware feature required: `android.hardware.sensor.compass` (for Qibla screen).

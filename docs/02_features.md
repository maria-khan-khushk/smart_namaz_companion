# Awwab — Features & Functionality

---

## Feature Summary

Awwab is organized around 8 screens accessible via a bottom navigation bar and a side drawer. Together they cover every aspect of a Muslim's daily prayer routine.

---

## 1. Prayer Times (Home Screen)

**The central hub of the app.**

- Displays all **5 daily prayer times** (Fajr, Dhuhr, Asr, Maghrib, Isha) for the user's current GPS location
- Highlights the **next upcoming prayer** with a distinct visual treatment
- Shows a **countdown timer** to the next prayer
- Displays the **Hijri (Islamic) calendar date** alongside the Gregorian date
- Shows the **Azan sound** notification capability — tapping a scheduled alert plays the bundled Azan audio
- Each prayer card is tappable to open full **Prayer Guidance** for that specific Salah

---

## 2. Prayer Guidance

**Step-by-step instructions for each Salah.**

- Available for all 5 prayers: Fajr, Dhuhr, Asr, Maghrib, Isha
- Shows:
  - **Rakat breakdown** (Sunnah, Fardh, Nafl counts)
  - **Step-by-step method** of performing each prayer
  - **Notes** on timing and common considerations
- Fully bilingual — toggle between **English and Urdu** at any time
- Urdu text renders in proper Arabic script (RTL)

---

## 3. Qibla Compass (Qibla Screen)

**Real-time Qibla direction finder.**

- Uses the device's **compass sensor** and **GPS location** to calculate the exact angle to the Kaabah in Makkah
- Animated compass needle points toward Qibla
- Works on any device with a magnetometer
- Prompts for location permission if not already granted
- Shows the bearing in degrees

---

## 4. Tasbih Counter (Tasbeeh Screen)

**A digital prayer bead counter with two modes.**

### Counter Tab
- Tap the large central button to **increment the count**
- Visual **progress ring** fills as you approach the target
- **Haptic feedback** on each tap and completion
- **Pulse animation** on the button with each tap
- **Preset Dhikr** selector (bottom sheet):
  - SubhanAllah — target 33
  - Alhamdulillah — target 33
  - AllahuAkbar — target 34
  - Astaghfirullah — target 100
  - La ilaha illallah — target 100
- **Custom target** — set any number as your personal goal
- **Completion dialog** shown when target is reached
- **Reset button** to start over

### 99 Names of Allah Tab
- Full list of all **99 Names of Allah (Asma ul Husna)**
- Each name shows:
  - Arabic text (large, serif font)
  - English meaning
  - Urdu meaning
- **Live search** — filter by Arabic, English, or Urdu text in real time

---

## 5. Reminders (Reminders Screen)

**Manage Azan notifications for each prayer.**

- Toggle notifications **on/off per prayer**
- Schedules **exact-time local notifications** using the device alarm manager
- When the notification fires, tapping it plays the **Azan audio** (azan.mp3)
- Settings persist across app restarts via `shared_preferences`
- Respects Android 13+ notification permission requirements

---

## 6. Streak Tracker

**Gamified habit tracking for daily prayers.**

- Tracks which of the 5 prayers you performed each day
- Visual **calendar heatmap** (powered by `table_calendar`) showing prayer history
- Current and best **streak counter**
- Per-day checkboxes for each prayer (Fajr, Dhuhr, Asr, Maghrib, Isha)
- Animated checkboxes with green fill on completion
- Data stored locally — no account or cloud required

---

## 7. Guidance Screen

**General Islamic guidance and resources.**

- A centralized screen for accessing prayer instructions
- Entry point to per-prayer `PrayerGuidanceScreen` for any of the 5 prayers
- Accessible from the home screen prayer cards

---

## 8. Settings Screen

**Personalize the app experience.**

- **Language toggle** — switch between English and Urdu (affects the entire app)
- **Theme toggle** — switch between Light and Dark mode
- Preferences are saved to `shared_preferences` and restored on launch

---

## Side Drawer

The home screen features a **slide-out drawer** containing:

- **App branding** header (Smart Namaz / اسمارٹ نماز)
- **Islamic Calendar card** showing today's Hijri and Gregorian date
- **Today's Hadith card** — a daily rotating Hadith with:
  - Arabic text
  - English and Urdu translation
  - Tafseer (commentary)
  - Hadith reference
- Quick link to **Settings**

---

## Bilingual Support

Every user-facing string in the app has both an English and Urdu version. The language is controlled by a global `LanguageProvider` (Provider package), so switching language in Settings instantly updates the entire UI without restarting.

| Feature | English | Urdu |
|---------|---------|------|
| Prayer names | Fajr, Dhuhr, Asr, Maghrib, Isha | فجر، ظہر، عصر، مغرب، عشاء |
| Navigation labels | Namaz, Qibla, Tasbeeh, Reminders | نماز، قبلہ، تسبیح، یاد دہانی |
| Rakat guidance | Full English instructions | Full Urdu instructions |
| 99 Names | English meaning | Urdu meaning |

---

## Sound & Notifications

- Bundled **Azan MP3** (`assets/sounds/azan.mp3`) plays when a prayer notification is tapped
- Notifications use **exact scheduling** via `android_alarm_manager_plus` and `flutter_local_notifications`
- Background fetch is enabled on iOS (`UIBackgroundModes: fetch, remote-notification`)
- Device vibration supported alongside audio

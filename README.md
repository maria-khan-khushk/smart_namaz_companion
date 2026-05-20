<div align="center">
  <img src="assets/logo.png" width="150" alt="Awwab Logo" />
  
  # 🕌 Awwab — Smart Namaz Companion
  
  **An all-in-one digital companion for Muslims to maintain their daily prayer routine, track consistency, and deepen spiritual practice.**
  
  ![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.38.4-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.10.8-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=for-the-badge)
  ![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)
</div>

---

## 📖 What is Awwab?

The name **Awwab** (أَوَّاب) comes from Arabic, meaning "one who frequently returns to Allah." Built entirely in Flutter, Awwab is designed to make daily Islamic practice more accessible, consistent, and spiritually fulfilling through thoughtful technology. 

Unlike generic prayer apps, Awwab provides a clean, zero-ad, distraction-free experience with seamless bilingual support (English & Urdu) and an intuitive progression system to help you build lasting habits.

---

## ✨ Core Pillars & Features

### 1. Accuracy & Timing (Home Screen)
- **Real-Time GPS Sync:** Uses the Aladhan API to calculate precise prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) based on your exact location.
- **Next Prayer Countdown:** A beautiful gradient hero card showing exactly how much time is left until the next Adhan.
- **Hijri & Gregorian Calendar:** Dual date display on the side drawer.
- **Skeleton Loading:** A perfectly smooth skeleton UI on first launch ensures there is never a blank screen while GPS coordinates sync.

### 2. Guidance & Learning
- **Step-by-Step Prayer Guidance:** Detailed Rakat breakdowns (Sunnah, Fardh, Nafl counts) and instructions for all 5 daily prayers.
- **Daily Hadith:** Start your day with a randomly rotating authentic Hadith, complete with Arabic text, full translation, and Tafseer.
- **Qibla Compass:** A responsive, real-time magnetometer compass pointing directly to the Kaabah in Makkah.

### 3. Consistency (Streak Tracker)
- **Gamified Heatmap Calendar:** Visually track your daily prayers.
- **Smart Reminders:** Get actionable notifications at configurable intervals (15, 30, 45, or 60 mins) after the Azan. Simply tap "Prayed" from your notification tray to log your prayer without opening the app!
- **Current & Best Streaks:** Motivate yourself to never miss a day.

### 4. Spirituality (Digital Tasbih)
- **Adaptive Gestures:** An advanced Tasbih counter that registers screen taps, physical phone **shakes**, and proximity **waves**. Sensitivity is fully customizable (Low/Medium/High) with smart debouncing.
- **Preset Dhikrs:** Built-in targets for SubhanAllah, Alhamdulillah, AllahuAkbar, Astaghfirullah, and La ilaha illallah.
- **99 Names of Allah:** A fully searchable index of Asma ul Husna with Arabic text and bilingual meanings.

---

## 🌐 Full Bilingual Support

Every user-facing string in Awwab has both an English and Urdu (اردو) version. The app fully supports Right-to-Left (RTL) rendering for Urdu text, and you can switch the language at any time in the Settings without restarting the app.

---

## 📸 Screenshots

*(Replace these placeholders with actual screenshots of the app)*

<div align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Home+Screen" width="200" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Streak+Tracker" width="200" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Adaptive+Tasbeeh" width="200" />
</div>

---

## 🛠️ Architecture & Tech Stack

Awwab uses a modern Flutter architecture ensuring smooth performance across platforms:
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Local Storage:** `shared_preferences`
- **Background Tasks:** `android_alarm_manager_plus` (for exact background alarms)
- **Notifications:** `flutter_local_notifications` (with interactive background actions)
- **Location:** `geolocator`
- **Sensors:** `sensors_plus` (accelerometer), `proximity_sensor`
- **Calendar Visualization:** `table_calendar`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥3.38.4)
- Android Studio or VS Code
- A physical Android/iOS device (recommended for sensors and exact alarms) or Emulator

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/smart_namaz_companion.git
   cd smart_namaz_companion
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### ⚙️ Important OS Configurations

To ensure Awwab's background alarms and interactive notifications work flawlessly:
1. **Location Permission:** Must be granted to calculate accurate times.
2. **Notification Permission:** Android 13+ requires explicit permission for Azan alerts and reminders.
3. **Battery Optimization:** For exact-time background alarms (Android Alarm Manager) to fire precisely at Azan time when the device is asleep, the user must disable battery optimization/restrictions for the app.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

<div align="center">
  <b>Made with ❤️ for the Ummah.</b>
</div>

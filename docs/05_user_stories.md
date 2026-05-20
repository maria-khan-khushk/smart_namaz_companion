# Awwab — User Stories

---

## Epic 1: Prayer Times

### US-001 — View Today's Prayer Times
**As a** Muslim user,  
**I want to** see all five daily prayer times for my current location,  
**So that** I know exactly when to pray without having to look them up elsewhere.

**Acceptance Criteria:**
- App fetches Fajr, Dhuhr, Asr, Maghrib, and Isha times on launch
- Times are accurate for the device's GPS location
- Times update if I change location
- The next upcoming prayer is visually highlighted
- A countdown to the next prayer is displayed

---

### US-002 — See the Next Prayer at a Glance
**As a** busy user,  
**I want to** immediately know which prayer is coming up next and how much time I have,  
**So that** I can plan my schedule around it.

**Acceptance Criteria:**
- Next prayer card is visually distinct from past prayers
- A live countdown timer shows hours and minutes remaining
- The prayer name is shown in the user's chosen language

---

### US-003 — View Islamic and Gregorian Date
**As a** user who observes Islamic occasions,  
**I want to** see today's Hijri date alongside the regular date,  
**So that** I stay aware of the Islamic calendar without a separate app.

**Acceptance Criteria:**
- Hijri date is shown in the sidebar drawer
- Gregorian date is shown alongside it
- Both dates are displayed in the user's chosen language

---

## Epic 2: Prayer Guidance

### US-004 — Learn How to Perform a Prayer
**As a** beginner or someone who wants to refresh their knowledge,  
**I want to** get step-by-step instructions for each prayer,  
**So that** I perform the Salah correctly.

**Acceptance Criteria:**
- Tapping any prayer card navigates to its guidance screen
- Guidance shows rakat count breakdown (Sunnah, Fardh, Nafl)
- Guidance shows ordered steps for performing the prayer
- A note about timing or common considerations is included
- Content is available in both English and Urdu

---

### US-005 — Read Guidance in Urdu
**As an** Urdu-speaking user,  
**I want to** read all prayer instructions in Urdu,  
**So that** I can understand them in my native language.

**Acceptance Criteria:**
- All guidance text is translated to Urdu
- Urdu text renders correctly in Arabic script (RTL)
- Prayer names are shown in Urdu (فجر، ظہر، عصر، مغرب، عشاء)

---

## Epic 3: Qibla Direction

### US-006 — Find the Qibla Direction
**As a** Muslim user in an unfamiliar location,  
**I want to** point my phone in the Qibla direction,  
**So that** I can face the Kaabah during prayer wherever I am.

**Acceptance Criteria:**
- App requests location and compass permissions
- A compass rose and needle animate in real time
- The needle points toward Makkah based on current GPS position
- The bearing angle is displayed numerically

---

## Epic 4: Tasbeeh (Dhikr Counter)

### US-007 — Count Dhikr After Prayer
**As a** user finishing a prayer,  
**I want to** count SubhanAllah 33 times, Alhamdulillah 33 times, and AllahuAkbar 34 times,  
**So that** I can complete the post-prayer Tasbih accurately.

**Acceptance Criteria:**
- A large tap button increments the count
- Selecting a preset (SubhanAllah, Alhamdulillah, AllahuAkbar) sets the target automatically
- A progress ring fills as the count approaches the target
- A haptic pulse happens on each tap
- A completion dialog appears when the target is reached

---

### US-008 — Use a Custom Dhikr Count
**As a** user with a personal Dhikr practice,  
**I want to** set a custom target count,  
**So that** I can count any Dhikr to any number I choose.

**Acceptance Criteria:**
- A "Set Target" option opens a numeric input dialog
- Any positive integer is accepted as a valid target
- The counter resets and the progress ring reflects the new target

---

### US-009 — Browse the 99 Names of Allah
**As a** spiritually curious user,  
**I want to** browse all 99 Names of Allah with their meanings,  
**So that** I can learn and reflect on the attributes of Allah.

**Acceptance Criteria:**
- All 99 Names are listed with Arabic, English, and Urdu text
- Names are searchable by any language
- The list updates in real time as I type in the search box

---

## Epic 5: Azan Reminders

### US-010 — Get Notified at Prayer Time
**As a** user who might miss prayer times,  
**I want to** receive a notification when each prayer time arrives,  
**So that** I never miss a Salah.

**Acceptance Criteria:**
- Each prayer can be toggled on/off for notifications independently
- The notification fires at the scheduled prayer time
- Tapping the notification plays the Azan sound
- Notification settings persist after app restart

---

### US-011 — Manage Notifications Per Prayer
**As a** user who only wants reminders for certain prayers,  
**I want to** enable notifications for specific prayers only,  
**So that** I'm not disturbed during prayers I can always remember.

**Acceptance Criteria:**
- The Reminders screen shows 5 toggles, one per prayer
- Each toggle independently enables or disables that prayer's notification
- Changes take effect immediately without restarting the app

---

## Epic 6: Streak Tracking

### US-012 — Mark Prayers as Completed
**As a** disciplined user,  
**I want to** check off each prayer I complete during the day,  
**So that** I have a record of my daily Salah consistency.

**Acceptance Criteria:**
- The Streak Tracker shows 5 checkboxes per day (one per prayer)
- Tapping a checkbox marks it with a green animated checkmark
- Data is saved automatically and persists between sessions

---

### US-013 — See My Prayer Streak
**As a** user building a habit,  
**I want to** see how many consecutive days I've prayed all 5 prayers,  
**So that** I stay motivated to maintain consistency.

**Acceptance Criteria:**
- A streak counter shows current consecutive prayer days
- A "best streak" counter shows the personal record
- The calendar highlights days with full prayer completion

---

### US-014 — Review Past Prayer History
**As a** user reflecting on my practice,  
**I want to** scroll back through the calendar to see which days I prayed,  
**So that** I can identify patterns and improve.

**Acceptance Criteria:**
- A calendar (monthly view) shows past prayer completion
- Days with full prayer are visually distinguished from partial or missing days
- I can navigate between months

---

## Epic 7: Daily Hadith

### US-015 — Read Today's Hadith
**As a** user seeking daily spiritual enrichment,  
**I want to** read a Hadith of the day when I open the app,  
**So that** I get a moment of reflection as part of my daily routine.

**Acceptance Criteria:**
- A Hadith is shown in the side drawer
- It includes Arabic text, translation, commentary, and reference
- The Hadith is available in both English and Urdu
- A new Hadith appears each day

---

## Epic 8: Personalization

### US-016 — Switch to Urdu Language
**As an** Urdu-speaking user,  
**I want to** switch the app language to Urdu,  
**So that** I can use the entire app comfortably in my native language.

**Acceptance Criteria:**
- Settings screen has a language toggle
- Switching to Urdu instantly updates all labels, guidance, and navigation
- My preference is saved and restored when I reopen the app

---

### US-017 — Use Dark Mode
**As a** user who uses my phone at night,  
**I want to** switch to a dark theme,  
**So that** the app is comfortable to use in low-light environments without straining my eyes.

**Acceptance Criteria:**
- Settings screen has a dark/light mode toggle
- Dark mode applies a dark background with appropriate text contrast
- My theme preference persists between sessions

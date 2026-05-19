import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../services/hadith_service.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level callback — AndroidAlarmManager fires this even when app is closed.
// Used for the 5 daily prayer azan alarms.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> azanAlarmCallback() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('sounds/azan.mp3'));
    await Future.delayed(const Duration(seconds: 30));
    await player.stop();
    await player.dispose();
  } catch (e) {
    print('Error playing azan in background: $e');
  }

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
      const InitializationSettings(android: androidSettings));

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'azan_channel',
    'Azan Notifications',
    channelDescription: 'Prayer time notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: false, // sound already playing via AudioPlayer
    enableVibration: true,
    fullScreenIntent: true,
  );

  await notifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Prayer Time',
    'It is time for prayer.',
    const NotificationDetails(android: androidDetails),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stable alarm IDs for the 5 daily prayers
// ─────────────────────────────────────────────────────────────────────────────
class _AzanIds {
  static const int fajr    = 1001;
  static const int dhuhr   = 1002;
  static const int asr     = 1003;
  static const int maghrib = 1004;
  static const int isha    = 1005;
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
//
// TWO channels:
//   'azan_channel'          → system default sound  (prayer time banners)
//   'reminder_azan_channel' → azan.mp3 auto-plays   (manual reminders)
//
// ONE-TIME SETUP required:
//   mkdir -p android/app/src/main/res/raw
//   cp assets/sounds/azan.mp3 android/app/src/main/res/raw/azan.mp3
//
// Then UNINSTALL the app from device and reinstall so Android picks up the
// new channel sound (Android caches channel settings permanently per install).
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _defaultChannelId  = 'azan_channel';
  static const String _reminderChannelId = 'reminder_azan_channel';

  // ── Initialize ─────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (!tz.timeZoneDatabase.isInitialized) {
      tz.initializeTimeZones();
    }
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Local timezone set to: $timeZoneName');
    } catch (e) {
      print('Error mapping local timezone: $e. Fallback to UTC.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await AndroidAlarmManager.initialize();
    print('NotificationService initialized');
  }

  // ── Tap handler ─────────────────────────────────────────────────────────────
  // Plays azan when user taps a notification (fallback for prayer time banners)

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    if (response.payload == 'azan_reminder' ||
        response.payload == 'manual_reminder') {
      final player = AudioPlayer();
      try {
        await player.play(AssetSource('sounds/azan.mp3'));
        Future.delayed(const Duration(seconds: 30), () => player.stop());
      } catch (e) {
        print('Error playing azan on tap: $e');
      }
    }
  }

  // ── Create channels ─────────────────────────────────────────────────────────
  //
  // Deletes old channels first so Android is forced to re-read the sound setting.
  // Android permanently caches channel config — deletion is the only way to reset.

  static Future<void> createNotificationChannel() async {
    final plugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) return;

    // Delete stale cached channels so sound changes take effect
    await plugin.deleteNotificationChannel(_defaultChannelId);
    await plugin.deleteNotificationChannel(_reminderChannelId);

    // Channel 1 — system default sound (prayer time banner notifications)
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _defaultChannelId,
        'Azan Notifications',
        description: 'Prayer time notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );

    // Channel 2 — azan.mp3 plays automatically when reminder fires
    // Requires: android/app/src/main/res/raw/azan.mp3
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Reminder Azan Sound',
        description: 'Manual reminders that auto-play Azan sound',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azan'), // no extension
        enableVibration: true,
        enableLights: true,
      ),
    );

    print('Notification channels created (azan sound channel ready)');
  }

  static Future<bool> requestAlarmPermissions() async {
    final plugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) return true;

    final notificationsAllowed =
        await plugin.requestNotificationsPermission() ?? true;
    final exactAllowed =
        await plugin.requestExactAlarmsPermission() ?? true;
    return notificationsAllowed && exactAllowed;
  }

  // ── Manual reminder — azan.mp3 plays automatically when notification fires ──
  //
  // Uses reminder_azan_channel which has azan.mp3 at channel level.
  // No tapping needed — sound fires the moment the scheduled time arrives.

  static Future<void> scheduleManualReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    if (!tz.timeZoneDatabase.isInitialized) tz.initializeTimeZones();
    final allowed = await requestAlarmPermissions();
    if (!allowed) {
      throw Exception('Notification and exact alarm permissions are required.');
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _reminderChannelId,               // ← custom azan sound channel
      'Reminder Azan Sound',
      channelDescription: 'Manual reminder with auto Azan sound',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('azan'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'azan.mp3', // place azan.mp3 in Runner/Resources on iOS
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'manual_reminder',
    );

    print('Manual reminder scheduled: id=$id "$title" at $scheduledTime');
  }

  // ── Schedule all 5 prayer azan alarms ──────────────────────────────────────

  static Future<void> scheduleAzanAlarms({
    required String fajr,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
  }) async {
    final prayers = {
      _AzanIds.fajr:    fajr,
      _AzanIds.dhuhr:   dhuhr,
      _AzanIds.asr:     asr,
      _AzanIds.maghrib: maghrib,
      _AzanIds.isha:    isha,
    };

    await cancelAzanAlarms();

    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final entry in prayers.entries) {
      try {
        final prayerTime = DateTime.parse('$today ${entry.value}:00');
        if (prayerTime.isAfter(now)) {
          await AndroidAlarmManager.oneShotAt(
            prayerTime,
            entry.key,
            azanAlarmCallback,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
          );
          print('Azan alarm set: id=${entry.key} at $prayerTime');
        }
      } catch (e) {
        print('Error scheduling azan alarm id=${entry.key}: $e');
      }
    }
  }

  static Future<void> cancelAzanAlarms() async {
    for (final id in [
      _AzanIds.fajr, _AzanIds.dhuhr, _AzanIds.asr,
      _AzanIds.maghrib, _AzanIds.isha,
    ]) {
      await AndroidAlarmManager.cancel(id);
    }
    print('All azan alarms cancelled');
  }

  // ── Generic notification (hadith, test) ─────────────────────────────────────

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    if (!tz.timeZoneDatabase.isInitialized) tz.initializeTimeZones();
    final allowed = await requestAlarmPermissions();
    if (!allowed) {
      throw Exception('Notification and exact alarm permissions are required.');
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _defaultChannelId,
      'Azan Notifications',
      channelDescription: 'Prayer time notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'azan_reminder',
    );
  }

  static Future<void> testNotification() async {
    await scheduleNotification(
      id: 99999,
      title: 'Test Alarm',
      body: 'This is a test notification',
      scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
      soundPath: null,
    );
  }

  // ── Hadith daily notification ───────────────────────────────────────────────

  static Future<void> scheduleDailyHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
    int notificationId = 999,
  }) async {
    try {
      final hadith = await HadithService.getTodaysHadith();
      final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
      final now = DateTime.now();
      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

      await scheduleNotification(
        id: notificationId,
        title: isUrdu ? 'آج کی حدیث' : "Today's Hadith",
        body: isUrdu ? hadith.urduText : hadith.englishText,
        scheduledTime: scheduled,
        soundPath: null,
      );
    } catch (e) {
      print('Error scheduling hadith notification: $e');
    }
  }

  // ── Cancel helpers ──────────────────────────────────────────────────────────

  static Future<void> cancelNotification(int id) async =>
      _notifications.cancel(id);

  static Future<void> cancelAllNotifications() async =>
      _notifications.cancelAll();

  static Future<void> cancelHadithNotification({int notificationId = 999}) async =>
      cancelNotification(notificationId);

  static Future<void> rescheduleHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
  }) async {
    await cancelHadithNotification();
    await scheduleDailyHadithNotification(
        context: context, hour: hour, minute: minute);
  }

  static Future<bool> areNotificationsEnabled() async {
    final enabled = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? true;
  }
}

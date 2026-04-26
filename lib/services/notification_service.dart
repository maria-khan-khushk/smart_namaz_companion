import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../services/hadith_service.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level callback for AndroidAlarmManager (must be a top-level function)
// This fires even when the app is in the background / closed.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> azanAlarmCallback() async {
  // Play azan sound
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('sounds/azan.mp3'));
    // Stop after 30 seconds
    await Future.delayed(const Duration(seconds: 30));
    await player.stop();
    await player.dispose();
  } catch (e) {
    print('Error playing azan in background: $e');
  }

  // Also show a heads-up notification so the user sees which prayer it is
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
      const InitializationSettings(android: androidSettings));

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'azan_channel',
    'Azan Notifications',
    channelDescription: 'Prayer time notifications with Azan sound',
    importance: Importance.max,
    priority: Priority.high,
    playSound: false, // sound handled by AudioPlayer above
    enableVibration: true,
    fullScreenIntent: true,
    ongoing: false,
  );

  await notifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Prayer Time 🕌',
    'It is time for prayer. Tap to open.',
    const NotificationDetails(android: androidDetails),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Alarm IDs for each prayer (stable, won't collide with hadith id=999)
// ─────────────────────────────────────────────────────────────────────────────
class _AzanIds {
  static const int fajr = 1001;
  static const int dhuhr = 1002;
  static const int asr = 1003;
  static const int maghrib = 1004;
  static const int isha = 1005;
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (!tz.timeZoneDatabase.isInitialized) {
      tz.initializeTimeZones();
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Initialize alarm manager (Android background execution)
    await AndroidAlarmManager.initialize();

    print('NotificationService initialized');
  }

  // ── Notification tap (fallback — user taps notification) ─────────────────

  static Future<void> _onNotificationTap(
      NotificationResponse response) async {
    if (response.payload == 'azan_reminder') {
      final player = AudioPlayer();
      try {
        await player.play(AssetSource('sounds/azan.mp3'));
        Future.delayed(const Duration(seconds: 30), () => player.stop());
      } catch (e) {
        print('Error playing azan on tap: $e');
      }
    }
  }

  // ── Notification channel ──────────────────────────────────────────────────

  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'azan_channel',
      'Azan Notifications',
      description: 'Prayer time notifications with Azan sound',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Schedule Azan for all 5 prayers ──────────────────────────────────────
  //
  // Call this from HomeScreen after fetching fresh prayer times.
  // prayerTimes map: { 'Fajr': '05:12', 'Dhuhr': '12:30', ... }
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> scheduleAzanAlarms({
    required String fajr,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
  }) async {
    final prayers = {
      _AzanIds.fajr: fajr,
      _AzanIds.dhuhr: dhuhr,
      _AzanIds.asr: asr,
      _AzanIds.maghrib: maghrib,
      _AzanIds.isha: isha,
    };

    // Cancel previous alarms before rescheduling
    await cancelAzanAlarms();

    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final entry in prayers.entries) {
      final id = entry.key;
      final timeStr = entry.value; // e.g. "05:12"

      try {
        final prayerTime =
            DateTime.parse('$today $timeStr:00');

        // Only schedule if the prayer time is in the future
        if (prayerTime.isAfter(now)) {
          await AndroidAlarmManager.oneShotAt(
            prayerTime,
            id,
            azanAlarmCallback,
            exact: true,
            wakeup: true,         // wakes device from sleep
            rescheduleOnReboot: true,
          );
          print('Azan alarm set: id=$id at $prayerTime');
        }
      } catch (e) {
        print('Error scheduling azan alarm id=$id: $e');
      }
    }
  }

  static Future<void> cancelAzanAlarms() async {
    for (final id in [
      _AzanIds.fajr,
      _AzanIds.dhuhr,
      _AzanIds.asr,
      _AzanIds.maghrib,
      _AzanIds.isha,
    ]) {
      await AndroidAlarmManager.cancel(id);
    }
    print('All azan alarms cancelled');
  }

  // ── Generic one-off notification (used by manual reminders) ──────────────

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    if (!tz.timeZoneDatabase.isInitialized) tz.initializeTimeZones();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'azan_channel',
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
      // iOS: put azan.mp3 (≤30s) in Runner/Resources and reference it here
      // sound: 'azan.mp3',
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
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'azan_reminder',
    );
  }

  static Future<void> scheduleManualReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        soundPath: soundPath);
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

  // ── Hadith daily notification ─────────────────────────────────────────────

  static Future<void> scheduleDailyHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
    int notificationId = 999,
  }) async {
    try {
      final hadith = await HadithService.getTodaysHadith();
      final isUrdu =
          Provider.of<LanguageProvider>(context, listen: false).isUrdu;
      final String title = isUrdu ? 'آج کی حدیث' : "Today's Hadith";
      final String body =
          isUrdu ? hadith.urduText : hadith.englishText;

      final now = DateTime.now();
      DateTime scheduledDateTime =
          DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime =
            scheduledDateTime.add(const Duration(days: 1));
      }

      await scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduledDateTime,
        soundPath: null,
      );
    } catch (e) {
      print('Error scheduling hadith notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelHadithNotification(
      {int notificationId = 999}) async {
    await cancelNotification(notificationId);
  }

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
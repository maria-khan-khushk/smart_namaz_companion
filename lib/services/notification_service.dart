import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../services/hadith_service.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

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

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Set callback when notification is tapped
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    print("Notification service initialized");
  }

  // Play Azan when user taps the notification
  static Future<void> _onNotificationTap(NotificationResponse response) async {
    print("Notification tapped: ${response.payload}");
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/azan.mp3'));
      print("Playing Azan from assets");
      // Stop after 30 seconds
      Future.delayed(Duration(seconds: 30), () => player.stop());
    } catch (e) {
      print("Error playing Azan: $e");
    }
  }

  static Future<void> testNotification() async {
    await scheduleNotification(
      id: 99999,
      title: "Test Alarm",
      body: "This is a test notification",
      scheduledTime: DateTime.now().add(Duration(seconds: 10)),
      soundPath: null, // default system sound
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
      soundPath: soundPath,
    );
  }

  static Future<bool> areNotificationsEnabled() async {
    final enabled = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? true;
  }

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

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    print("Notification channel created");
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    try {
      if (!tz.timeZoneDatabase.isInitialized) {
        tz.initializeTimeZones();
      }

      // Always use default system sound for reliability
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'azan_channel',
        'Azan Notifications',
        channelDescription: 'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: null, // default sound
        enableVibration: true,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(body),
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: null,
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime tzScheduledTime =
          tz.TZDateTime.from(scheduledTime, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'azan_reminder', // optional payload
      );

      print("Notification scheduled: id=$id, title=$title, time=$scheduledTime");
    } catch (e) {
      print("Error scheduling notification: $e");
      rethrow;
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print("Notification cancelled: id=$id");
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print("All notifications cancelled");
  }

  // HADITH NOTIFICATIONS (same as before, but without custom sound)
  static Future<void> scheduleDailyHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
    int notificationId = 999,
  }) async {
    try {
      final hadith = await HadithService.getTodaysHadith();
      final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
      final String title = isUrdu ? 'آج کی حدیث' : "Today's Hadith";
      final String body = isUrdu ? hadith.urduText : hadith.englishText;

      final now = DateTime.now();
      DateTime scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
      }

      await scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduledDateTime,
        soundPath: null,
      );
      print('Daily Hadith notification scheduled at ${scheduledDateTime.toLocal()}');
    } catch (e) {
      print('Error scheduling hadith notification: $e');
    }
  }

  static Future<void> cancelHadithNotification({int notificationId = 999}) async {
    await cancelNotification(notificationId);
  }

  static Future<void> rescheduleHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
  }) async {
    await cancelHadithNotification();
    await scheduleDailyHadithNotification(context: context, hour: hour, minute: minute);
  }
}
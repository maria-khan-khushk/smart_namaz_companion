import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../services/hadith_service.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone database (only once)
    if (!tz.timeZoneDatabase.isInitialized) {
      tz.initializeTimeZones();
    }

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
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

    await _notifications.initialize(settings);
    print("Notification service initialized");
  }
  
static Future<void> scheduleManualReminder({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
  String? soundPath = 'azan',
}) async {
  await scheduleNotification(
    id: id,
    title: title,
    body: body,
    scheduledTime: scheduledTime,
    soundPath: soundPath,
  );
}
  // Check if notifications are enabled (Android)
  static Future<bool> areNotificationsEnabled() async {
    final enabled = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? true;
  }

  // Create notification channel (Android)
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

  // Schedule notification at specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath, // e.g., 'azan' for raw resource
  }) async {
    try {
      // Ensure timezone is initialized
      if (!tz.timeZoneDatabase.isInitialized) {
        tz.initializeTimeZones();
      }

      // Create notification details
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'azan_channel',
        'Azan Notifications',
        channelDescription: 'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: soundPath != null
            ? RawResourceAndroidNotificationSound(soundPath)
            : null,
        enableVibration: true,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(body),
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: soundPath != null ? '$soundPath.caf' : null,
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert to TZDateTime
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
      );

      print("Notification scheduled: id=$id, title=$title, time=$scheduledTime");
    } catch (e) {
      print("Error scheduling notification: $e");
      rethrow;
    }
  }

  // // Play Azan sound using audioplayers (for foreground/background)
  // static Future<void> playAzanSound() async {
  //   final AudioPlayer player = AudioPlayer();
  //   try {
  //     await player.play(AssetSource('azan.mp3'));
  //     // Stop after 30 seconds
  //     Future.delayed(Duration(seconds: 30), () {
  //       player.stop();
  //     });
  //   } catch (e) {
  //     print('Error playing Azan: $e');
  //   }
  // }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print("Notification cancelled: id=$id");
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print("All notifications cancelled");
  }

  // ==================== HADITH NOTIFICATION METHODS ====================

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
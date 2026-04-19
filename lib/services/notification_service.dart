import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../services/hadith_service.dart';        // add this
import '../providers/language_provider.dart';   // add this
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Timezone initialize
    tz.initializeTimeZones();

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
  }

  // Notification channel create (Android)
  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'azan_channel', // channel id
      'Azan Notifications', // channel name
      description: 'Prayer time notifications with Azan sound',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  // Schedule notification at specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    // Android details
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

    // iOS details
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
  }

  // Play Azan sound when notification is tapped or shown
  static Future<void> playAzanSound() async {
    final AudioPlayer player = AudioPlayer();
    try {
      await player.play(AssetSource('azan.mp3'));
      // Optionally stop after some duration
      Future.delayed(Duration(seconds: 30), () {
        player.stop();
      });
    } catch (e) {
      print('Error playing Azan: $e');
    }
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ==================== HADITH NOTIFICATION METHODS ====================

  /// Schedule daily Hadith notification at a specific time (default 8:00 AM)
  /// Pass a BuildContext to get current language, or pass isUrdu directly
  static Future<void> scheduleDailyHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
    int notificationId = 999, // unique ID for hadith notification
  }) async {
    try {
      // Get today's hadith
      final hadith = await HadithService.getTodaysHadith();
      
      // Get current language preference
      final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
      
      final String title = isUrdu ? 'آج کی حدیث' : "Today's Hadith";
      final String body = isUrdu ? hadith.urduText : hadith.englishText;
      
      // Calculate next scheduled time (today at specified time, or tomorrow if already passed)
      final now = DateTime.now();
      DateTime scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
      }
      
      // Schedule notification using existing method
      await scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduledDateTime,
        soundPath: null, // No azan sound for hadith
      );
      
      print('Daily Hadith notification scheduled at ${scheduledDateTime.toLocal()}');
    } catch (e) {
      print('Error scheduling hadith notification: $e');
    }
  }
  
  /// Cancel only the hadith notification (optional)
  static Future<void> cancelHadithNotification({int notificationId = 999}) async {
    await cancelNotification(notificationId);
  }
  
  /// Reschedule hadith notification (useful when language changes)
  static Future<void> rescheduleHadithNotification({
    required BuildContext context,
    int hour = 8,
    int minute = 0,
  }) async {
    await cancelHadithNotification();
    await scheduleDailyHadithNotification(context: context, hour: hour, minute: minute);
  }
}
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

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
}
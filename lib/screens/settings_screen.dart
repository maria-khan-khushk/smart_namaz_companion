import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/theme.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/prayer_api_service.dart';
import '../models/prayer_time_model.dart';
import '../utils/shared_prefs_helper.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _scheduleAllPrayerNotifications() async {
    // Get prayer times (cached or fresh)
    PrayerTimeModel? prayerTimes = await PrefsHelper.getCachedPrayerTimes();
    
    if (prayerTimes == null) {
      try {
        final locationService = LocationService();
        bool hasPermission = await locationService.requestPermission();
        if (!hasPermission) throw Exception("Location permission denied");
        
        final position = await locationService.getCurrentLocation();
        final apiService = PrayerApiService();
        prayerTimes = await apiService.fetchPrayerTimes(position.latitude, position.longitude);
        await PrefsHelper.cachePrayerTimes(prayerTimes);
        print("Fetched fresh prayer times for notifications");
      } catch (e) {
        print("Failed to fetch prayer times for notifications: $e");
        throw Exception("Could not fetch prayer times. Please check location and network.");
      }
    } else {
      print("Using cached prayer times for notifications");
    }

    // Cancel existing notifications
    await NotificationService.cancelAllNotifications();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
      {'name': 'Asr', 'time': prayerTimes.asr},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib},
      {'name': 'Isha', 'time': prayerTimes.isha},
    ];

    // Schedule each prayer
    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final timeStr = prayer['time'];
      if (timeStr == null) continue;
      final timeParts = timeStr.split(':');
      if (timeParts.length < 2) continue;
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      DateTime scheduledTime = DateTime(
        today.year,
        today.month,
        today.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }

      await NotificationService.scheduleNotification(
        id: i + 1,
        title: '${prayer['name']!} ka Waqt',
        body: 'اللہ اکبر، اللہ اکبر',
        scheduledTime: scheduledTime,
        soundPath: 'azan',
      );
      print("Scheduled ${prayer['name']} at ${scheduledTime.toLocal()}");
    }

    print("All prayer notifications scheduled successfully");
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Enable notifications
      setState(() => _isLoading = true);
      try {
        await _scheduleAllPrayerNotifications();
        setState(() {
          _notificationsEnabled = true;
          _isLoading = false;
        });
        final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isUrdu 
              ? 'اذان الرٹس فعال! اطلاعات مقرر ہوگئیں۔' 
              : "Azan alerts enabled! Notifications scheduled.")),
        );
        await _saveNotificationPreference(true);
      } catch (e) {
        print("Error enabling notifications: $e");
        setState(() => _isLoading = false);
        final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isUrdu 
              ? 'اذان الرٹس فعال کرنے میں ناکامی: $e' 
              : "Failed to enable Azan alerts: $e")),
        );
        // Reset switch state (it will stay off)
        await _saveNotificationPreference(false);
      }
    } else {
      // Disable notifications
      await NotificationService.cancelAllNotifications();
      setState(() => _notificationsEnabled = false);
      await _saveNotificationPreference(false);
      final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUrdu 
            ? 'اذان الرٹس غیر فعال۔ تمام اطلاعات منسوخ کردی گئیں۔' 
            : "Azan alerts disabled. All notifications canceled.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(title: Text(isUrdu ? 'سیٹنگز' : 'Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: Text(isUrdu ? 'ڈارک موڈ' : 'Dark Mode'),
              subtitle: Text(isUrdu ? 'لائٹ اور ڈارک تھیم کے درمیان سوئچ کریں' : 'Switch between light and dark theme'),
              value: isDark,
              onChanged: (value) => themeNotifier.toggleTheme(value),
              secondary: Icon(Icons.dark_mode, color: AppColors.primaryMuted),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.language, color: AppColors.primaryMuted),
              title: Text(isUrdu ? 'زبان' : 'Language'),
              subtitle: Text(isUrdu ? 'اردو / انگریزی' : 'English / اردو'),
              trailing: DropdownButton<String>(
                value: languageProvider.locale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ur', child: Text('Urdu (اردو)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: AppColors.primaryMuted),
              title: Text(isUrdu ? 'اذان الرٹس' : 'Azan Alerts'),
              subtitle: Text(isUrdu ? 'خودکار اذان اطلاعات کو فعال/غیر فعال کریں' : 'Enable/disable automatic Azan notifications'),
              trailing: _isLoading
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: AppColors.primaryMuted,
                    ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primaryMuted),
              title: Text(isUrdu ? 'تعارف' : 'About'),
              subtitle: Text(isUrdu ? 'اسمارٹ نماز ساتھی ورژن 1.0' : 'Smart Namaz Companion v1.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: isUrdu ? 'اسمارٹ نماز ساتھی' : 'Smart Namaz Companion',
                  applicationVersion: "1.0",
                  applicationLegalese: "© 2025",
                  children: [
                    Text(isUrdu 
                        ? 'یہ ایپ آپ کو وقت پر نماز ادا کرنے میں مدد دیتی ہے، جس میں اذان الرٹس، قبلہ سمت، اور روزانہ حدیث شامل ہیں۔'
                        : 'An app to help you offer prayers on time with Azan alerts, Qibla direction, and daily Hadith.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
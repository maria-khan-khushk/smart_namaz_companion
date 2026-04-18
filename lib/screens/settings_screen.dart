import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/theme.dart';
import '../services/hadith_service.dart';
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
      } catch (e) {
        print("Failed to fetch prayer times for notifications: $e");
        return;
      }
    }

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
    }

    print("Notifications scheduled for all prayers");
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      setState(() => _isLoading = true);
      await _scheduleAllPrayerNotifications();
      setState(() {
        _notificationsEnabled = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LanguageProvider>(context, listen: false).isUrdu 
            ? 'اذان الرٹس فعال! اطلاعات مقرر ہوگئیں۔' 
            : "Azan alerts enabled! Notifications scheduled.")),
      );
    } else {
      await NotificationService.cancelAllNotifications();
      setState(() => _notificationsEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LanguageProvider>(context, listen: false).isUrdu 
            ? 'اذان الرٹس غیر فعال۔ تمام اطلاعات منسوخ کردی گئیں۔' 
            : "Azan alerts disabled. All notifications canceled.")),
      );
    }
    await _saveNotificationPreference(value);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todaysHadith = HadithService.getTodaysHadith();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;

    return Scaffold(
      appBar: AppBar(title: Text(isUrdu ? 'سیٹنگز' : 'Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Dark mode switch card
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

          // Language selection card
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

          // Alarm / Reminder settings card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.alarm, color: AppColors.primaryMuted),
                  title: Text(isUrdu ? 'نماز کی یاددہانی' : 'Prayer Reminders'),
                  subtitle: Text(isUrdu ? 'نماز کے لیے دستی یاددہانیاں مقرر کریں' : 'Set manual reminders for prayers'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isUrdu ? 'دستی یاددہانیاں جلد آرہی ہیں' : 'Manual reminders coming soon!'))
                    );
                  },
                ),
                Divider(height: 0),
                ListTile(
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
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Daily Hadith card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: AppColors.primaryMuted),
                      SizedBox(width: 8),
                      Text(
                        isUrdu ? 'روزانہ حدیث' : 'Daily Hadith',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Icon(Icons.note_add_outlined, size: 20, color: Colors.grey),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    todaysHadith.arabic,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    todaysHadith.translation,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 8),
                  Text(
                    todaysHadith.explanation,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "- ${todaysHadith.reference}",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // About section
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
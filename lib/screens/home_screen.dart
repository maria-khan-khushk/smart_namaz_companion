import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/prayer_api_service.dart';
import '../models/prayer_time_model.dart';
import '../utils/shared_prefs_helper.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';
import 'prayer_guidance_screen.dart';
import '../providers/language_provider.dart';
import 'streak_tracker_screen.dart';
import '../services/hadith_service.dart';
import '../models/hadith_model.dart';
import '../services/notification_service.dart';
import '../services/hijri_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimeModel? prayerTimes;
  bool isFetchingFresh = false;
  String errorMsg = '';
  String nextPrayer = '';
  
  // Direct hadith object (no FutureBuilder needed)
  HadithModel? _todaysHadith;

  @override
  void initState() {
    super.initState();
    _loadCachedTimes();
    Future.delayed(Duration(milliseconds: 500), () {
      _fetchFreshTimes();
    });
    
    // Preload hadiths and load today's hadith into variable
    _loadHadithData();
    
    // Schedule daily Hadith notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleHadithNotification();
    });
  }
  
  Future<void> _loadHadithData() async {
    await HadithService.preload(); // ensure caching
    final hadith = await HadithService.getTodaysHadith();
    if (mounted) {
      setState(() {
        _todaysHadith = hadith;
      });
    }
  }
  
  Future<void> _scheduleHadithNotification() async {
    try {
      await NotificationService.scheduleDailyHadithNotification(
        context: context,
        hour: 8,
        minute: 0,
      );
    } catch (e) {
      print("Error scheduling hadith notification: $e");
    }
  }

  Future<void> _loadCachedTimes() async {
    final cached = await PrefsHelper.getCachedPrayerTimes();
    if (cached != null && mounted) {
      setState(() {
        prayerTimes = cached;
      });
      _calculateNextPrayer();
    }
  }

  Future<void> _fetchFreshTimes() async {
    if (isFetchingFresh) return;
    setState(() => isFetchingFresh = true);

    try {
      LocationService locService = LocationService();
      bool hasPermission = await locService.requestPermission();
      if (!hasPermission) throw Exception("Location permission denied");

      final position = await locService.getCurrentLocation();
      final apiService = PrayerApiService();
      final times = await apiService.fetchPrayerTimes(position.latitude, position.longitude);

      await PrefsHelper.cachePrayerTimes(times);
      if (mounted) {
        setState(() {
          prayerTimes = times;
          errorMsg = '';
        });
        _calculateNextPrayer();
      }
    } catch (e) {
      if (mounted && prayerTimes == null) {
        setState(() {
          errorMsg = e.toString();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not update prayer times. Using cached data.")),
        );
      }
    } finally {
      if (mounted) setState(() => isFetchingFresh = false);
    }
  }

  void _calculateNextPrayer() {
    if (prayerTimes == null) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    List<Map<String, dynamic>> prayers = [
      {'name': 'Fajr', 'time': prayerTimes!.fajr},
      {'name': 'Dhuhr', 'time': prayerTimes!.dhuhr},
      {'name': 'Asr', 'time': prayerTimes!.asr},
      {'name': 'Maghrib', 'time': prayerTimes!.maghrib},
      {'name': 'Isha', 'time': prayerTimes!.isha},
    ];

    for (var prayer in prayers) {
      final prayerDateTime = DateTime.parse('$today ${prayer['time']}');
      if (prayerDateTime.isAfter(now)) {
        if (nextPrayer != prayer['name']) {
          setState(() {
            nextPrayer = prayer['name'];
          });
        }
        return;
      }
    }
    if (nextPrayer != 'Fajr (Tomorrow)') {
      setState(() {
        nextPrayer = 'Fajr (Tomorrow)';
      });
    }
  }

  String _formatTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  String _getPrayerName(String name, bool isUrdu) {
    if (!isUrdu) return name;
    switch (name) {
      case 'Fajr': return 'فجر';
      case 'Dhuhr': return 'ظہر';
      case 'Asr': return 'عصر';
      case 'Maghrib': return 'مغرب';
      case 'Isha': return 'عشاء';
      default: return name;
    }
  }

  String _getNextPrayerDisplay(bool isUrdu) {
    if (!isUrdu) return nextPrayer;
    if (nextPrayer == 'Fajr') return 'فجر';
    if (nextPrayer == 'Dhuhr') return 'ظہر';
    if (nextPrayer == 'Asr') return 'عصر';
    if (nextPrayer == 'Maghrib') return 'مغرب';
    if (nextPrayer == 'Isha') return 'عشاء';
    if (nextPrayer == 'Fajr (Tomorrow)') return 'فجر (کل)';
    return nextPrayer;
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    return Scaffold(
      drawer: _buildDrawer(context, isUrdu),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Top row - Menu LEFT, Streak RIGHT
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Text(
                      isUrdu ? 'نماز کے اوقات' : 'Prayer Times',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StreakTrackerScreen())),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              if (prayerTimes != null) _buildNextPrayerCard(isUrdu),
              Expanded(
                child: prayerTimes == null
                    ? Center(child: CircularProgressIndicator())
                    : _buildPrayerTimesView(isUrdu),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(bool isUrdu) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryMuted, AppColors.secondaryMuted]),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: AppColors.primaryMuted.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isUrdu ? 'اگلی نماز' : 'Next Prayer',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
            ),
            SizedBox(height: 8),
            Text(
              _getNextPrayerDisplay(isUrdu),
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer - now uses direct variable, NO FutureBuilder, instantly opens
Widget _buildDrawer(BuildContext context, bool isUrdu) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primaryMuted, AppColors.secondaryMuted]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(isUrdu ? 'اسمارٹ نماز' : 'Smart Namaz',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(isUrdu ? 'ساتھی' : 'Companion',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
        // ---------- Islamic Calendar Card ----------
        Card(
          margin: EdgeInsets.all(12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primaryMuted, size: 24),
                    SizedBox(width: 8),
                    Text(
                      isUrdu ? 'اسلامی کیلنڈر' : 'Islamic Calendar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMuted),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  HijriService.getFormattedHijriDate(isUrdu),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  isUrdu ? 'عیسوی تاریخ:' : 'Gregorian Date:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  HijriService.getGregorianDate(isUrdu),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        // ---------- Hadith Card ----------
        _todaysHadith == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : _buildHadithCard(_todaysHadith!, isUrdu),
        // ---------- Settings Option ----------
        ListTile(
          leading: Icon(Icons.settings, color: AppColors.primaryMuted),
          title: Text(isUrdu ? 'سیٹنگز' : 'Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
          },
        ),
      ],
    ),
  );
}

// Helper method to build hadith card (already exists)
Widget _buildHadithCard(HadithModel hadith, bool isUrdu) {
  return Card(
    margin: EdgeInsets.all(12),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUrdu ? 'آج کی حدیث' : "Today's Hadith",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMuted),
          ),
          SizedBox(height: 12),
          Text(
            hadith.arabic,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 22, fontFamily: 'serif'),
          ),
          SizedBox(height: 12),
          Text(
            isUrdu ? hadith.urduText : hadith.englishText,
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          Text(
            isUrdu ? hadith.urduTranslation : hadith.englishTranslation,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          Text(
            isUrdu ? hadith.urduTafseer : hadith.englishTafseer,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            hadith.reference,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.secondaryMuted),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPrayerTimesView(bool isUrdu) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _prayerCard('Fajr', _formatTo12Hour(prayerTimes!.fajr), Icons.wb_twilight, isUrdu, nextPrayer == 'Fajr'),
        _prayerCard('Dhuhr', _formatTo12Hour(prayerTimes!.dhuhr), Icons.wb_sunny, isUrdu, nextPrayer == 'Dhuhr'),
        _prayerCard('Asr', _formatTo12Hour(prayerTimes!.asr), Icons.brightness_5, isUrdu, nextPrayer == 'Asr'),
        _prayerCard('Maghrib', _formatTo12Hour(prayerTimes!.maghrib), Icons.nights_stay, isUrdu, nextPrayer == 'Maghrib'),
        _prayerCard('Isha', _formatTo12Hour(prayerTimes!.isha), Icons.nightlight_round, isUrdu, nextPrayer == 'Isha'),
      ],
    );
  }

  Widget _prayerCard(String name, String timeFormatted, IconData icon, bool isUrdu, bool isNext) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isNext ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isNext ? AppColors.accentMuted.withOpacity(0.3) : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryMuted,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            _getPrayerName(name, isUrdu),
            style: TextStyle(
              fontSize: 20,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Text(timeFormatted, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrayerGuidanceScreen(prayerName: name)));
          },
        ),
      ),
    );
  }
}
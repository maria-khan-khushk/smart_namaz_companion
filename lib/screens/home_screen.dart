import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import '../services/prayer_api_service.dart';
import '../models/prayer_time_model.dart';
import '../utils/shared_prefs_helper.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';   // <-- Import for Settings

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimeModel? prayerTimes;
  bool isLoading = true;
  String errorMsg = '';
  String nextPrayer = '';
  Duration? timeUntilNext;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() { isLoading = true; errorMsg = ''; });
    
    try {
      LocationService locService = LocationService();
      bool hasPermission = await locService.requestPermission();
      if (!hasPermission) throw Exception("Location permission denied");
      
      final position = await locService.getCurrentLocation();
      final apiService = PrayerApiService();
      final times = await apiService.fetchPrayerTimes(position.latitude, position.longitude);
      
      await PrefsHelper.cachePrayerTimes(times);
      setState(() { prayerTimes = times; isLoading = false; });
      _calculateNextPrayer();
    } catch (e) {
      final cached = await PrefsHelper.getCachedPrayerTimes();
      if (cached != null) {
        setState(() { prayerTimes = cached; isLoading = false; errorMsg = ''; });
        _calculateNextPrayer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Using cached prayer times - No internet"))
        );
      } else {
        setState(() { errorMsg = e.toString(); isLoading = false; });
      }
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
        setState(() {
          nextPrayer = prayer['name'];
          timeUntilNext = prayerDateTime.difference(now);
        });
        return;
      }
    }
    // Sab prayers ho chuki hain to next day Fajr
    setState(() {
      nextPrayer = 'Fajr (Tomorrow)';
      timeUntilNext = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ DRAWER ADD KAR DIYA
      drawer: _buildDrawer(context),
body: Container(
  color: Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkBackground   // dark mode mein dark
      : Colors.white,               // light mode mein pure white
  child: SafeArea(
    child: isLoading
        ? Center(child: CircularProgressIndicator())
        : errorMsg.isNotEmpty
            ? _buildErrorView()
            : prayerTimes == null
                ? Center(child: Text("No data"))
                : _buildPrayerTimesView(),
  ),
),
    );
  }

  // ✅ DRAWER WIDGET
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryMuted, AppColors.secondaryMuted],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Smart Namaz",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Companion",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.access_time, color: AppColors.primaryMuted),
            title: Text("Prayer Times"),
            onTap: () {
              Navigator.pop(context); // close drawer
              // Already on home screen
            },
          ),
          ListTile(
            leading: Icon(Icons.compass_calibration, color: AppColors.primaryMuted),
            title: Text("Qibla Direction"),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Qibla screen (will implement later)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Qibla direction coming soon!"))
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: AppColors.primaryMuted),
            title: Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(errorMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPrayerTimes,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMuted,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesView() {
    return Column(
      children: [
        // Header with next prayer
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryMuted, AppColors.secondaryMuted],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Next Prayer",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                nextPrayer,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (timeUntilNext != null) ...[
                SizedBox(height: 8),
                Text(
                  _formatDuration(timeUntilNext!),
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ],
          ),
        ),
        // Prayer times list
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              _prayerCard("Fajr", prayerTimes!.fajr, Icons.wb_twilight),
              _prayerCard("Dhuhr", prayerTimes!.dhuhr, Icons.wb_sunny),
              _prayerCard("Asr", prayerTimes!.asr, Icons.brightness_5),
              _prayerCard("Maghrib", prayerTimes!.maghrib, Icons.nights_stay),
              _prayerCard("Isha", prayerTimes!.isha, Icons.nightlight_round),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prayerCard(String name, String time, IconData icon) {
    bool isNext = name == nextPrayer;
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isNext ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isNext ? AppColors.accentMuted.withOpacity(0.3) : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryMuted,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Text(
            time,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes left";
  }
}
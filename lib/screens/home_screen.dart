// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../services/location_service.dart';
// import '../services/prayer_api_service.dart';
// import '../models/prayer_time_model.dart';
// import '../utils/shared_prefs_helper.dart';
// import '../utils/theme.dart';
// import 'settings_screen.dart';
// import 'prayer_guidance_screen.dart';
// import '../providers/language_provider.dart';
// import '../services/streak_service.dart';
// import '../models/daily_prayer_record.dart';
// import 'streak_tracker_screen.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   PrayerTimeModel? prayerTimes;
//   bool isLoading = true;
//   String errorMsg = '';
//   String nextPrayer = '';
//   Duration? timeUntilNext;
//   Timer? _timer;
//   int _lastMinute = -1; // for timer optimization

//   // Streak related
//   int _streakCount = 0;
//   DailyPrayerRecord? _todayRecord;
//   final StreakService _streakService = StreakService();

//   @override
//   void initState() {
//     super.initState();
//     _loadPrayerTimes();
//     // Start timer only after first frame to avoid blocking
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startTimer();
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (prayerTimes != null) {
//         final now = DateTime.now();
//         // Recalculate only if minute changed or countdown is less than 60 seconds
//         if (_lastMinute != now.minute ||
//             (timeUntilNext != null && timeUntilNext!.inSeconds <= 60)) {
//           _lastMinute = now.minute;
//           _calculateNextPrayer();
//         }
//       }
//     });
//   }

//   Future<void> _loadPrayerTimes() async {
//     setState(() {
//       isLoading = true;
//       errorMsg = '';
//     });

//     try {
//       LocationService locService = LocationService();
//       bool hasPermission = await locService.requestPermission();
//       if (!hasPermission) throw Exception("Location permission denied");

//       final position = await locService.getCurrentLocation();
//       final apiService = PrayerApiService();
//       final times = await apiService.fetchPrayerTimes(position.latitude, position.longitude);

//       await PrefsHelper.cachePrayerTimes(times);
//       setState(() {
//         prayerTimes = times;
//         isLoading = false;
//       });
//       _calculateNextPrayer();
//       // Defer streak loading to avoid blocking the UI thread
//       Future.microtask(() => _loadStreakAndTodayRecord());
//     } catch (e) {
//       final cached = await PrefsHelper.getCachedPrayerTimes();
//       if (cached != null) {
//         setState(() {
//           prayerTimes = cached;
//           isLoading = false;
//           errorMsg = '';
//         });
//         _calculateNextPrayer();
//         Future.microtask(() => _loadStreakAndTodayRecord());
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Using cached prayer times - No internet")),
//         );
//       } else {
//         setState(() {
//           errorMsg = e.toString();
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadStreakAndTodayRecord() async {
//     final streak = await _streakService.getCurrentStreak();
//     final record = await _streakService.getRecordForDate(DateTime.now());
//     setState(() {
//       _streakCount = streak;
//       _todayRecord = record;
//     });
//   }

//   void _calculateNextPrayer() {
//     if (prayerTimes == null) return;
//     final now = DateTime.now();
//     final today = DateFormat('yyyy-MM-dd').format(now);

//     List<Map<String, dynamic>> prayers = [
//       {'name': 'Fajr', 'time': prayerTimes!.fajr},
//       {'name': 'Dhuhr', 'time': prayerTimes!.dhuhr},
//       {'name': 'Asr', 'time': prayerTimes!.asr},
//       {'name': 'Maghrib', 'time': prayerTimes!.maghrib},
//       {'name': 'Isha', 'time': prayerTimes!.isha},
//     ];

//     for (var prayer in prayers) {
//       final prayerDateTime = DateTime.parse('$today ${prayer['time']}');
//       if (prayerDateTime.isAfter(now)) {
//         if (nextPrayer != prayer['name'] ||
//             timeUntilNext != prayerDateTime.difference(now)) {
//           setState(() {
//             nextPrayer = prayer['name'];
//             timeUntilNext = prayerDateTime.difference(now);
//           });
//         }
//         return;
//       }
//     }
//     if (nextPrayer != 'Fajr (Tomorrow)') {
//       setState(() {
//         nextPrayer = 'Fajr (Tomorrow)';
//         timeUntilNext = null;
//       });
//     }
//   }

//   String _formatTo12Hour(String time24) {
//     try {
//       final parts = time24.split(':');
//       int hour = int.parse(parts[0]);
//       int minute = int.parse(parts[1]);
//       final period = hour >= 12 ? 'PM' : 'AM';
//       int hour12 = hour % 12;
//       if (hour12 == 0) hour12 = 12;
//       return '$hour12:${minute.toString().padLeft(2, '0')} $period';
//     } catch (e) {
//       return time24;
//     }
//   }

//   String _getPrayerName(String name, bool isUrdu) {
//     if (!isUrdu) return name;
//     switch (name) {
//       case 'Fajr':
//         return 'فجر';
//       case 'Dhuhr':
//         return 'ظہر';
//       case 'Asr':
//         return 'عصر';
//       case 'Maghrib':
//         return 'مغرب';
//       case 'Isha':
//         return 'عشاء';
//       default:
//         return name;
//     }
//   }

//   String _getNextPrayerDisplay(String nextPrayer, bool isUrdu) {
//     if (!isUrdu) return nextPrayer;
//     if (nextPrayer == 'Fajr') return 'فجر';
//     if (nextPrayer == 'Dhuhr') return 'ظہر';
//     if (nextPrayer == 'Asr') return 'عصر';
//     if (nextPrayer == 'Maghrib') return 'مغرب';
//     if (nextPrayer == 'Isha') return 'عشاء';
//     if (nextPrayer == 'Fajr (Tomorrow)') return 'فجر (کل)';
//     return nextPrayer;
//   }

//   Future<void> _togglePrayerCompletion(String prayerName) async {
//     await _streakService.markPrayerCompleted(prayerName);
//     await _loadStreakAndTodayRecord();
//     final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//           content: Text(isUrdu ? '$prayerName مکمل ہوگئی' : '$prayerName completed')),
//     );
//   }

//   bool _isPrayerCompleted(String prayerName) {
//     if (_todayRecord == null) return false;
//     return _todayRecord!.prayersCompleted[prayerName] ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
//     return Scaffold(
//       drawer: _buildDrawer(context, isUrdu),
//       body: Container(
//         color: Theme.of(context).brightness == Brightness.dark
//             ? AppColors.darkBackground
//             : Colors.white,
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Top row with streak icon and app title
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Builder(
//                       builder: (context) => IconButton(
//                         icon: Icon(Icons.menu),
//                         onPressed: () => Scaffold.of(context).openDrawer(),
//                       ),
//                     ),
//                     Text(
//                       isUrdu ? 'نماز کے اوقات' : 'Prayer Times',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(context,
//                             MaterialPageRoute(builder: (_) => StreakTrackerScreen()));
//                       },
//                       child: Container(
//                         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: AppColors.primaryMuted,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.local_fire_department,
//                                 color: Colors.white, size: 20),
//                             SizedBox(width: 4),
//                             Text(
//                               '$_streakCount',
//                               style: TextStyle(
//                                   color: Colors.white, fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: isLoading
//                     ? Center(child: CircularProgressIndicator())
//                     : errorMsg.isNotEmpty
//                         ? _buildErrorView(isUrdu)
//                         : prayerTimes == null
//                             ? Center(child: Text(isUrdu ? 'کوئی ڈیٹا نہیں' : 'No data'))
//                             : _buildPrayerTimesView(isUrdu),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer(BuildContext context, bool isUrdu) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                   colors: [AppColors.primaryMuted, AppColors.secondaryMuted]),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Text(
//                   isUrdu ? 'اسمارٹ نماز' : 'Smart Namaz',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   isUrdu ? 'ساتھی' : 'Companion',
//                   style: TextStyle(color: Colors.white70, fontSize: 16),
//                 ),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.access_time, color: AppColors.primaryMuted),
//             title: Text(isUrdu ? 'نماز کے اوقات' : 'Prayer Times'),
//             onTap: () => Navigator.pop(context),
//           ),
//           ListTile(
//             leading: Icon(Icons.compass_calibration, color: AppColors.primaryMuted),
//             title: Text(isUrdu ? 'قبلہ سمت' : 'Qibla Direction'),
//             onTap: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                     content: Text(isUrdu
//                         ? 'قبلہ سمت جلد آرہی ہے'
//                         : 'Qibla direction coming soon!')),
//               );
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings, color: AppColors.primaryMuted),
//             title: Text(isUrdu ? 'سیٹنگز' : 'Settings'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context,
//                   MaterialPageRoute(builder: (_) => SettingsScreen()));
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorView(bool isUrdu) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 64, color: Colors.red),
//           SizedBox(height: 16),
//           Text(errorMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
//           SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: _loadPrayerTimes,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primaryMuted,
//               padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//             ),
//             child: Text(isUrdu ? 'دوبارہ کوشش کریں' : 'Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimesView(bool isUrdu) {
//     return Column(
//       children: [
//         // Next Prayer Card
//         Container(
//           margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
//           padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//                 colors: [AppColors.primaryMuted, AppColors.secondaryMuted]),
//             borderRadius: BorderRadius.circular(40),
//             boxShadow: [
//               BoxShadow(
//                   color: AppColors.primaryMuted.withOpacity(0.3),
//                   blurRadius: 12,
//                   offset: Offset(0, 6))
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     isUrdu ? 'اگلی نماز' : 'Next Prayer',
//                     style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     _getNextPrayerDisplay(nextPrayer, isUrdu),
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               if (timeUntilNext != null)
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(30)),
//                   child: Text(
//                     _formatDuration(timeUntilNext!, isUrdu),
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: ListView(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             children: [
//               _prayerCard('Fajr', _formatTo12Hour(prayerTimes!.fajr), Icons.wb_twilight,
//                   isUrdu),
//               _prayerCard('Dhuhr', _formatTo12Hour(prayerTimes!.dhuhr), Icons.wb_sunny,
//                   isUrdu),
//               _prayerCard('Asr', _formatTo12Hour(prayerTimes!.asr), Icons.brightness_5,
//                   isUrdu),
//               _prayerCard('Maghrib', _formatTo12Hour(prayerTimes!.maghrib),
//                   Icons.nights_stay, isUrdu),
//               _prayerCard('Isha', _formatTo12Hour(prayerTimes!.isha),
//                   Icons.nightlight_round, isUrdu),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _prayerCard(String name, String timeFormatted, IconData icon, bool isUrdu) {
//     bool isNext = name == nextPrayer;
//     bool isCompleted = _isPrayerCompleted(name);
//     return Card(
//       margin: EdgeInsets.only(bottom: 12),
//       elevation: isNext ? 4 : 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           color: isNext ? AppColors.accentMuted.withOpacity(0.3) : null,
//         ),
//         child: ListTile(
//           leading: CircleAvatar(
//             backgroundColor: AppColors.primaryMuted,
//             child: Icon(icon, color: Colors.white),
//           ),
//           title: Text(
//             _getPrayerName(name, isUrdu),
//             style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: isNext ? FontWeight.bold : FontWeight.normal),
//           ),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(timeFormatted,
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
//               SizedBox(width: 8),
//               GestureDetector(
//                 onTap: () => _togglePrayerCompletion(name),
//                 child: Container(
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: isCompleted ? Colors.green : Colors.grey.shade300,
//                   ),
//                   child: Icon(
//                     isCompleted ? Icons.check : Icons.check_box_outline_blank,
//                     size: 20,
//                     color: isCompleted ? Colors.white : Colors.grey.shade700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           onTap: () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => PrayerGuidanceScreen(prayerName: name)));
//           },
//         ),
//       ),
//     );
//   }

//   String _formatDuration(Duration duration, bool isUrdu) {
//     if (duration.isNegative) return isUrdu ? "0:00 باقی" : "0:00 left";
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     String hours = twoDigits(duration.inHours);
//     String minutes = twoDigits(duration.inMinutes.remainder(60));
//     return isUrdu ? "$hours:$minutes باقی" : "$hours:$minutes left";
//   }
// }
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
import '../services/streak_service.dart';
import '../models/daily_prayer_record.dart';
import 'streak_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimeModel? prayerTimes;
  bool isLoading = true;
  bool isFetchingFresh = false;
  String errorMsg = '';
  String nextPrayer = '';
  Duration? timeUntilNext;
  Timer? _timer;

  // Streak related
  int _streakCount = 0;
  DailyPrayerRecord? _todayRecord;
  final StreakService _streakService = StreakService();

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    // Start timer only after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Optimized: update only once per minute
  void _startTimer() {
    _calculateNextPrayer(); // immediate calculation
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  // Show cached data immediately, then fetch fresh in background
  Future<void> _loadPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });

    final cached = await PrefsHelper.getCachedPrayerTimes();
    if (cached != null) {
      setState(() {
        prayerTimes = cached;
        isLoading = false;
      });
      _calculateNextPrayer();
      // Fetch fresh data in background
      _fetchFreshPrayerTimes();
    } else {
      await _fetchFreshPrayerTimes();
    }
  }

  Future<void> _fetchFreshPrayerTimes() async {
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
          isLoading = false;
          errorMsg = '';
        });
        _calculateNextPrayer();
        Future.microtask(() => _loadStreakAndTodayRecord());
      }
    } catch (e) {
      if (mounted && prayerTimes == null) {
        setState(() {
          errorMsg = e.toString();
          isLoading = false;
        });
      } else if (mounted && prayerTimes != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not update prayer times. Using cached data.")),
        );
      }
    } finally {
      if (mounted) setState(() => isFetchingFresh = false);
    }
  }

  Future<void> _loadStreakAndTodayRecord() async {
    final streak = await _streakService.getCurrentStreak();
    final record = await _streakService.getRecordForDate(DateTime.now());
    if (mounted) {
      setState(() {
        _streakCount = streak;
        _todayRecord = record;
      });
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
        if (nextPrayer != prayer['name'] ||
            timeUntilNext != prayerDateTime.difference(now)) {
          setState(() {
            nextPrayer = prayer['name'];
            timeUntilNext = prayerDateTime.difference(now);
          });
        }
        return;
      }
    }
    if (nextPrayer != 'Fajr (Tomorrow)') {
      setState(() {
        nextPrayer = 'Fajr (Tomorrow)';
        timeUntilNext = null;
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

  String _getNextPrayerDisplay(String nextPrayer, bool isUrdu) {
    if (!isUrdu) return nextPrayer;
    if (nextPrayer == 'Fajr') return 'فجر';
    if (nextPrayer == 'Dhuhr') return 'ظہر';
    if (nextPrayer == 'Asr') return 'عصر';
    if (nextPrayer == 'Maghrib') return 'مغرب';
    if (nextPrayer == 'Isha') return 'عشاء';
    if (nextPrayer == 'Fajr (Tomorrow)') return 'فجر (کل)';
    return nextPrayer;
  }

  Future<void> _togglePrayerCompletion(String prayerName) async {
    await _streakService.markPrayerCompleted(prayerName);
    await _loadStreakAndTodayRecord();
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isUrdu ? '$prayerName مکمل ہوگئی' : '$prayerName completed')),
    );
  }

  bool _isPrayerCompleted(String prayerName) {
    if (_todayRecord == null) return false;
    return _todayRecord!.prayersCompleted[prayerName] ?? false;
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
              // Top row with streak icon and app title
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
                        child: Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                            SizedBox(width: 4),
                            Text('$_streakCount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMsg.isNotEmpty
                        ? _buildErrorView(isUrdu)
                        : prayerTimes == null
                            ? Center(child: Text(isUrdu ? 'کوئی ڈیٹا نہیں' : 'No data'))
                            : _buildPrayerTimesView(isUrdu),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          ListTile(
            leading: Icon(Icons.access_time, color: AppColors.primaryMuted),
            title: Text(isUrdu ? 'نماز کے اوقات' : 'Prayer Times'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.compass_calibration, color: AppColors.primaryMuted),
            title: Text(isUrdu ? 'قبلہ سمت' : 'Qibla Direction'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isUrdu ? 'قبلہ سمت جلد آرہی ہے' : 'Qibla direction coming soon!'))
              );
            },
          ),
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

  Widget _buildErrorView(bool isUrdu) {
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
            child: Text(isUrdu ? 'دوبارہ کوشش کریں' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesView(bool isUrdu) {
    return Column(
      children: [
        // Next Prayer Card
        Container(
          margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primaryMuted, AppColors.secondaryMuted]),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: AppColors.primaryMuted.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu ? 'اگلی نماز' : 'Next Prayer',
                    style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getNextPrayerDisplay(nextPrayer, isUrdu),
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (timeUntilNext != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    _formatDuration(timeUntilNext!, isUrdu),
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              _prayerCard('Fajr', _formatTo12Hour(prayerTimes!.fajr), Icons.wb_twilight, isUrdu),
              _prayerCard('Dhuhr', _formatTo12Hour(prayerTimes!.dhuhr), Icons.wb_sunny, isUrdu),
              _prayerCard('Asr', _formatTo12Hour(prayerTimes!.asr), Icons.brightness_5, isUrdu),
              _prayerCard('Maghrib', _formatTo12Hour(prayerTimes!.maghrib), Icons.nights_stay, isUrdu),
              _prayerCard('Isha', _formatTo12Hour(prayerTimes!.isha), Icons.nightlight_round, isUrdu),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prayerCard(String name, String timeFormatted, IconData icon, bool isUrdu) {
    bool isNext = name == nextPrayer;
    bool isCompleted = _isPrayerCompleted(name);
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
            style: TextStyle(fontSize: 20, fontWeight: isNext ? FontWeight.bold : FontWeight.normal),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeFormatted, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _togglePrayerCompletion(name),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.check_box_outline_blank,
                    size: 20,
                    color: isCompleted ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrayerGuidanceScreen(prayerName: name)));
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration, bool isUrdu) {
    if (duration.isNegative) return isUrdu ? "0:00 باقی" : "0:00 left";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return isUrdu ? "$hours:$minutes باقی" : "$hours:$minutes left";
  }
}
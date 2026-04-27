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

// Prayer icon + color mapping
const _prayerMeta = {
  'Fajr':    {'icon': Icons.wb_twilight,     'emoji': '🌙'},
  'Dhuhr':   {'icon': Icons.wb_sunny,        'emoji': '☀️'},
  'Asr':     {'icon': Icons.brightness_5,    'emoji': '🌤️'},
  'Maghrib': {'icon': Icons.nights_stay,     'emoji': '🌆'},
  'Isha':    {'icon': Icons.nightlight_round,'emoji': '🌃'},
};

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimeModel? prayerTimes;
  bool isFetchingFresh = false;
  String errorMsg = '';
  String nextPrayer = '';
  DateTime? _nextPrayerTime;
  Duration _timeLeft = Duration.zero;
  Timer? _countdownTimer;
  HadithModel? _todaysHadith;

  @override
  void initState() {
    super.initState();
    _loadCachedTimes();
    Future.delayed(const Duration(milliseconds: 500), _fetchFreshTimes);
    _loadHadithData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleHadithNotification());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadHadithData() async {
    await HadithService.preload();
    final hadith = await HadithService.getTodaysHadith();
    if (mounted) setState(() => _todaysHadith = hadith);
  }

  Future<void> _scheduleHadithNotification() async {
    try {
      await NotificationService.scheduleDailyHadithNotification(context: context, hour: 8, minute: 0);
    } catch (e) { print('Error scheduling hadith notification: $e'); }
  }

  Future<void> _loadCachedTimes() async {
    final cached = await PrefsHelper.getCachedPrayerTimes();
    if (cached != null && mounted) {
      setState(() => prayerTimes = cached);
      _calculateNextPrayer();
    }
  }

  Future<void> _fetchFreshTimes() async {
    if (isFetchingFresh) return;
    setState(() => isFetchingFresh = true);
    try {
      final locService = LocationService();
      if (!await locService.requestPermission()) throw Exception('Location permission denied');
      final position = await locService.getCurrentLocation();
      final times = await PrayerApiService().fetchPrayerTimes(position.latitude, position.longitude);
      await PrefsHelper.cachePrayerTimes(times);
      if (mounted) {
        setState(() { prayerTimes = times; errorMsg = ''; });
        _calculateNextPrayer();
        await NotificationService.scheduleAzanAlarms(
          fajr: times.fajr, dhuhr: times.dhuhr, asr: times.asr,
          maghrib: times.maghrib, isha: times.isha,
        );
      }
    } catch (e) {
      if (mounted && prayerTimes == null) {
        setState(() => errorMsg = e.toString());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update prayer times. Using cached data.')),
        );
      }
    } finally {
      if (mounted) setState(() => isFetchingFresh = false);
    }
  }

  // ── Next prayer + countdown ─────────────────────────────────────────────

  void _calculateNextPrayer() {
    if (prayerTimes == null) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final prayers = [
      {'name': 'Fajr',    'time': prayerTimes!.fajr},
      {'name': 'Dhuhr',   'time': prayerTimes!.dhuhr},
      {'name': 'Asr',     'time': prayerTimes!.asr},
      {'name': 'Maghrib', 'time': prayerTimes!.maghrib},
      {'name': 'Isha',    'time': prayerTimes!.isha},
    ];

    for (final prayer in prayers) {
      final prayerDateTime = DateTime.parse('$today ${prayer['time']}');
      if (prayerDateTime.isAfter(now)) {
        setState(() {
          nextPrayer = prayer['name']!;
          _nextPrayerTime = prayerDateTime;
        });
        _startCountdown();
        return;
      }
    }

    // All prayers passed — next is Fajr tomorrow
    final tomorrowFajr = DateTime.parse(
      '${DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)))} ${prayerTimes!.fajr}'
    );
    setState(() {
      nextPrayer = 'Fajr (Tomorrow)';
      _nextPrayerTime = tomorrowFajr;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    if (_nextPrayerTime == null) return;
    final now = DateTime.now();
    final diff = _nextPrayerTime!.difference(now);

    if (diff.isNegative || diff.inSeconds == 0) {
      // Timer hit zero — recalculate which prayer is next
      _calculateNextPrayer();
      return;
    }

    if (mounted) setState(() => _timeLeft = diff);
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  // ── Formatting helpers ──────────────────────────────────────────────────

  String _formatTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) { return time24; }
  }

  String _getPrayerName(String name, bool isUrdu) {
    if (!isUrdu) return name;
    const map = {'Fajr': 'فجر', 'Dhuhr': 'ظہر', 'Asr': 'عصر', 'Maghrib': 'مغرب', 'Isha': 'عشاء'};
    return map[name] ?? name;
  }

  String _getNextPrayerDisplay(bool isUrdu) {
    if (!isUrdu) return nextPrayer;
    const map = {'Fajr': 'فجر', 'Dhuhr': 'ظہر', 'Asr': 'عصر', 'Maghrib': 'مغرب', 'Isha': 'عشاء', 'Fajr (Tomorrow)': 'فجر (کل)'};
    return map[nextPrayer] ?? nextPrayer;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      drawer: _buildDrawer(context, isUrdu),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(isUrdu, primaryColor, textPrimary),
              Expanded(
                child: prayerTimes == null
                    ? _buildLoadingOrError(primaryColor, textSecondary)
                    : _buildBody(isUrdu, primaryColor, cardColor, textPrimary, textSecondary, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isUrdu, Color primaryColor, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          Builder(builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: primaryColor, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          )),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'السلام علیکم' : 'Assalamu Alaikum',
                  style: TextStyle(fontSize: 13, color: primaryColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
                Text(
                  isUrdu ? 'نماز کے اوقات' : 'Prayer Times',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          ),
          // Refresh indicator
          if (isFetchingFresh)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
            ),
          // Streak button
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StreakTrackerScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Streak', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError(Color primaryColor, Color textSecondary) {
    if (errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(errorMsg, textAlign: TextAlign.center, style: TextStyle(color: textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchFreshTimes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  // ── Main body ────────────────────────────────────────────────────────────

  Widget _buildBody(bool isUrdu, Color primaryColor, Color cardColor,
      Color textPrimary, Color textSecondary, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── Hero countdown card ──────────────────────────────────────
        _buildCountdownCard(isUrdu, primaryColor, isDark),
        const SizedBox(height: 20),

        // ── Section label ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            isUrdu ? 'آج کے اوقات' : "Today's Prayers",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: textSecondary, letterSpacing: 0.5),
          ),
        ),

        // ── Prayer cards ─────────────────────────────────────────────
        _prayerCard('Fajr',    prayerTimes!.fajr,    isUrdu, nextPrayer == 'Fajr',    primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Dhuhr',   prayerTimes!.dhuhr,   isUrdu, nextPrayer == 'Dhuhr',   primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Asr',     prayerTimes!.asr,     isUrdu, nextPrayer == 'Asr',     primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Maghrib', prayerTimes!.maghrib, isUrdu, nextPrayer == 'Maghrib', primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Isha',    prayerTimes!.isha,    isUrdu, nextPrayer == 'Isha',    primaryColor, cardColor, textPrimary, isDark),
      ],
    );
  }

  // ── Countdown hero card ──────────────────────────────────────────────────

  Widget _buildCountdownCard(bool isUrdu, Color primaryColor, bool isDark) {
    final gradientColors = isDark
        ? [primaryColor.withOpacity(0.85), primaryColor.withOpacity(0.55)]
        : [AppColors.primaryMuted, AppColors.secondaryMuted];

    final emoji = _prayerMeta[nextPrayer.replaceAll(' (Tomorrow)', '')]?['emoji'] as String? ?? '🕌';
    final countdown = _formatCountdown(_timeLeft);
    final prayerDisplay = _getNextPrayerDisplay(isUrdu);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUrdu ? 'اگلی نماز' : 'Next Prayer',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.8),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isUrdu ? 'آج' : DateFormat('EEE, d MMM').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prayer name + emoji
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  prayerDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Divider
            Container(height: 1, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 14),

            // Countdown row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? 'وقت باقی' : 'Time Remaining',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countdown,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                // Adhan time chip
                if (_nextPrayerTime != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isUrdu ? 'اذان' : 'Adhan',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTo12Hour(
                          '${_nextPrayerTime!.hour.toString().padLeft(2,'0')}:${_nextPrayerTime!.minute.toString().padLeft(2,'0')}'
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Prayer card ─────────────────────────────────────────────────────────

  Widget _prayerCard(String name, String time24, bool isUrdu, bool isNext,
      Color primaryColor, Color cardColor, Color textPrimary, bool isDark) {
    final icon = _prayerMeta[name]?['icon'] as IconData? ?? Icons.access_time;
    final timeFormatted = _formatTo12Hour(time24);

    // Check if prayer has already passed today
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    bool hasPassed = false;
    try {
      hasPassed = DateTime.parse('$today $time24').isBefore(now);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isNext
            ? primaryColor.withOpacity(isDark ? 0.18 : 0.08)
            : cardColor,
        borderRadius: BorderRadius.circular(18),
        border: isNext
            ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: isNext
            ? [BoxShadow(color: primaryColor.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PrayerGuidanceScreen(prayerName: name))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isNext ? primaryColor : primaryColor.withOpacity(isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: isNext ? Colors.white : primaryColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Prayer name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPrayerName(name, isUrdu),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                          color: hasPassed && !isNext
                              ? textPrimary.withOpacity(0.4)
                              : textPrimary,
                        ),
                      ),
                      if (isNext)
                        Text(
                          isUrdu ? 'اگلی نماز' : 'Up next',
                          style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),

                // Time + passed indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeFormatted,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hasPassed && !isNext
                            ? textPrimary.withOpacity(0.4)
                            : isNext ? primaryColor : textPrimary,
                      ),
                    ),
                    if (hasPassed && !isNext)
                      Text(
                        isUrdu ? 'ادا' : 'Passed',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade400, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),

                // Arrow
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: isNext ? primaryColor : textPrimary.withOpacity(0.3), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Drawer ──────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context, bool isUrdu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isDark
                  ? [primaryColor.withOpacity(0.8), primaryColor.withOpacity(0.6)]
                  : [AppColors.primaryMuted, AppColors.secondaryMuted]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(isUrdu ? 'اسمارٹ نماز' : 'Smart Namaz',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(isUrdu ? 'ساتھی' : 'Companion',
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_today, color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(isUrdu ? 'اسلامی کیلنڈر' : 'Islamic Calendar',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryColor)),
                  ]),
                  const SizedBox(height: 12),
                  Text(HijriService.getFormattedHijriDate(isUrdu),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 6),
                  Text(isUrdu ? 'عیسوی تاریخ:' : 'Gregorian:',
                      style: TextStyle(fontSize: 12, color: textSecondary)),
                  Text(HijriService.getGregorianDate(isUrdu),
                      style: TextStyle(fontSize: 15, color: textPrimary)),
                ],
              ),
            ),
          ),
          _todaysHadith == null
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : _buildHadithCard(_todaysHadith!, isUrdu, primaryColor, cardColor, textPrimary, textSecondary),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: primaryColor),
            title: Text(isUrdu ? 'سیٹنگز' : 'Settings', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHadithCard(HadithModel hadith, bool isUrdu, Color primaryColor,
      Color cardColor, Color textPrimary, Color textSecondary) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isUrdu ? 'آج کی حدیث' : "Today's Hadith",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),
            Text(hadith.arabic, textAlign: TextAlign.right,
                style: TextStyle(fontSize: 20, fontFamily: 'serif', color: textPrimary)),
            const SizedBox(height: 10),
            Text(isUrdu ? hadith.urduText : hadith.englishText,
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: textPrimary)),
            const SizedBox(height: 8),
            Text(isUrdu ? hadith.urduTranslation : hadith.englishTranslation,
                style: TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 8),
            Text(isUrdu ? hadith.urduTafseer : hadith.englishTafseer,
                style: TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 8),
            Text(hadith.reference,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: primaryColor)),
          ],
        ),
      ),
    );
  }
} // End of HomeScreen
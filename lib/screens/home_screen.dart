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

// ─────────────────────────────────────────────────────────────────────────────
// 99 Names of Allah (Arabic + English + Urdu)
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, String>> _allahNames = [
  {'arabic': 'الرَّحْمَنُ', 'english': 'The Most Gracious', 'urdu': 'بہت مہربان'},
  {'arabic': 'الرَّحِيمُ', 'english': 'The Most Merciful', 'urdu': 'نہایت رحم کرنے والا'},
  {'arabic': 'الْمَلِكُ', 'english': 'The King', 'urdu': 'بادشاہ'},
  {'arabic': 'الْقُدُّوسُ', 'english': 'The Most Holy', 'urdu': 'پاک'},
  {'arabic': 'السَّلَامُ', 'english': 'The Source of Peace', 'urdu': 'سلامتی دینے والا'},
  {'arabic': 'الْمُؤْمِنُ', 'english': 'The Granter of Security', 'urdu': 'امن دینے والا'},
  {'arabic': 'الْمُهَيْمِنُ', 'english': 'The Guardian', 'urdu': 'نگہبان'},
  {'arabic': 'الْعَزِيزُ', 'english': 'The Almighty', 'urdu': 'سب پر غالب'},
  {'arabic': 'الْجَبَّارُ', 'english': 'The Compeller', 'urdu': 'زبردست'},
  {'arabic': 'الْمُتَكَبِّرُ', 'english': 'The Supreme', 'urdu': 'بڑائی والا'},
  {'arabic': 'الْخَالِقُ', 'english': 'The Creator', 'urdu': 'پیدا کرنے والا'},
  {'arabic': 'الْبَارِئُ', 'english': 'The Originator', 'urdu': 'بنانے والا'},
  {'arabic': 'الْمُصَوِّرُ', 'english': 'The Fashioner', 'urdu': 'صورت دینے والا'},
  {'arabic': 'الْغَفَّارُ', 'english': 'The Forgiving', 'urdu': 'بہت بخشنے والا'},
  {'arabic': 'الْقَهَّارُ', 'english': 'The Subduer', 'urdu': 'قہر کرنے والا'},
  {'arabic': 'الْوَهَّابُ', 'english': 'The Bestower', 'urdu': 'عطا کرنے والا'},
  {'arabic': 'الرَّزَّاقُ', 'english': 'The Provider', 'urdu': 'رزق دینے والا'},
  {'arabic': 'الْفَتَّاحُ', 'english': 'The Opener', 'urdu': 'کھولنے والا'},
  {'arabic': 'الْعَلِيمُ', 'english': 'The All-Knowing', 'urdu': 'سب جاننے والا'},
  {'arabic': 'الْقَابِضُ', 'english': 'The Restrainer', 'urdu': 'روکنے والا'},
  {'arabic': 'الْبَاسِطُ', 'english': 'The Extender', 'urdu': 'پھیلانے والا'},
  {'arabic': 'الْخَافِضُ', 'english': 'The Reducer', 'urdu': 'نیچے کرنے والا'},
  {'arabic': 'الرَّافِعُ', 'english': 'The Exalter', 'urdu': 'اونچا کرنے والا'},
  {'arabic': 'الْمُعِزُّ', 'english': 'The Honourer', 'urdu': 'عزت دینے والا'},
  {'arabic': 'الْمُذِلُّ', 'english': 'The Humiliator', 'urdu': 'ذلیل کرنے والا'},
  {'arabic': 'السَّمِيعُ', 'english': 'The All-Hearing', 'urdu': 'سننے والا'},
  {'arabic': 'الْبَصِيرُ', 'english': 'The All-Seeing', 'urdu': 'دیکھنے والا'},
  {'arabic': 'الْحَكَمُ', 'english': 'The Judge', 'urdu': 'فیصلہ کرنے والا'},
  {'arabic': 'الْعَدْلُ', 'english': 'The Just', 'urdu': 'انصاف کرنے والا'},
  {'arabic': 'اللَّطِيفُ', 'english': 'The Subtle One', 'urdu': 'باریک بین'},
  {'arabic': 'الْخَبِيرُ', 'english': 'The All-Aware', 'urdu': 'باخبر'},
  {'arabic': 'الْحَلِيمُ', 'english': 'The Forbearing', 'urdu': 'بردبار'},
  {'arabic': 'الْعَظِيمُ', 'english': 'The Magnificent', 'urdu': 'عظمت والا'},
  {'arabic': 'الْغَفُورُ', 'english': 'The Forgiving', 'urdu': 'معاف کرنے والا'},
  {'arabic': 'الشَّكُورُ', 'english': 'The Appreciative', 'urdu': 'قدردان'},
  {'arabic': 'الْعَلِيُّ', 'english': 'The Most High', 'urdu': 'سب سے بلند'},
  {'arabic': 'الْكَبِيرُ', 'english': 'The Most Great', 'urdu': 'بہت بڑا'},
  {'arabic': 'الْحَفِيظُ', 'english': 'The Preserver', 'urdu': 'حفاظت کرنے والا'},
  {'arabic': 'الْمُقِيتُ', 'english': 'The Sustainer', 'urdu': 'قوت دینے والا'},
  {'arabic': 'الْحَسِيبُ', 'english': 'The Reckoner', 'urdu': 'حساب لینے والا'},
  {'arabic': 'الْجَلِيلُ', 'english': 'The Majestic', 'urdu': 'جلال والا'},
  {'arabic': 'الْكَرِيمُ', 'english': 'The Most Generous', 'urdu': 'بہت کریم'},
  {'arabic': 'الرَّقِيبُ', 'english': 'The Watchful', 'urdu': 'نگرانی کرنے والا'},
  {'arabic': 'الْمُجِيبُ', 'english': 'The Responsive', 'urdu': 'قبول کرنے والا'},
  {'arabic': 'الْوَاسِعُ', 'english': 'The All-Encompassing', 'urdu': 'وسعت والا'},
  {'arabic': 'الْحَكِيمُ', 'english': 'The Wise', 'urdu': 'حکمت والا'},
  {'arabic': 'الْوَدُودُ', 'english': 'The Loving', 'urdu': 'محبت کرنے والا'},
  {'arabic': 'الْمَجِيدُ', 'english': 'The Glorious', 'urdu': 'بزرگی والا'},
  {'arabic': 'الْبَاعِثُ', 'english': 'The Resurrector', 'urdu': 'اٹھانے والا'},
  {'arabic': 'الشَّهِيدُ', 'english': 'The Witness', 'urdu': 'گواہ'},
  {'arabic': 'الْحَقُّ', 'english': 'The Truth', 'urdu': 'سچا'},
  {'arabic': 'الْوَكِيلُ', 'english': 'The Trustee', 'urdu': 'وکیل'},
  {'arabic': 'الْقَوِيُّ', 'english': 'The Strong', 'urdu': 'طاقتور'},
  {'arabic': 'الْمَتِينُ', 'english': 'The Firm', 'urdu': 'مضبوط'},
  {'arabic': 'الْوَلِيُّ', 'english': 'The Protecting Friend', 'urdu': 'دوست'},
  {'arabic': 'الْحَمِيدُ', 'english': 'The Praiseworthy', 'urdu': 'تعریف کے لائق'},
  {'arabic': 'الْمُحْصِي', 'english': 'The Counter', 'urdu': 'گننے والا'},
  {'arabic': 'الْمُبْدِئُ', 'english': 'The Originator', 'urdu': 'شروع کرنے والا'},
  {'arabic': 'الْمُعِيدُ', 'english': 'The Restorer', 'urdu': 'واپس کرنے والا'},
  {'arabic': 'الْمُحْيِي', 'english': 'The Giver of Life', 'urdu': 'زندگی دینے والا'},
  {'arabic': 'الْمُمِيتُ', 'english': 'The Taker of Life', 'urdu': 'موت دینے والا'},
  {'arabic': 'الْحَيُّ', 'english': 'The Ever-Living', 'urdu': 'ہمیشہ زندہ'},
  {'arabic': 'الْقَيُّومُ', 'english': 'The Sustainer', 'urdu': 'قائم رکھنے والا'},
  {'arabic': 'الْوَاجِدُ', 'english': 'The Finder', 'urdu': 'پانے والا'},
  {'arabic': 'الْمَاجِدُ', 'english': 'The Noble', 'urdu': 'شریف'},
  {'arabic': 'الْوَاحِدُ', 'english': 'The One', 'urdu': 'اکیلا'},
  {'arabic': 'الْأَحَدُ', 'english': 'The Unique', 'urdu': 'یکتا'},
  {'arabic': 'الصَّمَدُ', 'english': 'The Eternal', 'urdu': 'بے نیاز'},
  {'arabic': 'الْقَادِرُ', 'english': 'The Able', 'urdu': 'قدرت والا'},
  {'arabic': 'الْمُقْتَدِرُ', 'english': 'The Powerful', 'urdu': 'بہت قادر'},
  {'arabic': 'الْمُقَدِّمُ', 'english': 'The Expediter', 'urdu': 'آگے کرنے والا'},
  {'arabic': 'الْمُؤَخِّرُ', 'english': 'The Delayer', 'urdu': 'پیچھے کرنے والا'},
  {'arabic': 'الْأَوَّلُ', 'english': 'The First', 'urdu': 'پہلا'},
  {'arabic': 'الْآخِرُ', 'english': 'The Last', 'urdu': 'آخری'},
  {'arabic': 'الظَّاهِرُ', 'english': 'The Manifest', 'urdu': 'ظاہر'},
  {'arabic': 'الْبَاطِنُ', 'english': 'The Hidden', 'urdu': 'پوشیدہ'},
  {'arabic': 'الْوَالِي', 'english': 'The Governor', 'urdu': 'حاکم'},
  {'arabic': 'الْمُتَعَالِي', 'english': 'The Most Exalted', 'urdu': 'سب سے اعلیٰ'},
  {'arabic': 'الْبَرُّ', 'english': 'The Source of Goodness', 'urdu': 'نیکی کا سرچشمہ'},
  {'arabic': 'التَّوَّابُ', 'english': 'The Acceptor of Repentance', 'urdu': 'توبہ قبول کرنے والا'},
  {'arabic': 'الْمُنْتَقِمُ', 'english': 'The Avenger', 'urdu': 'بدلہ لینے والا'},
  {'arabic': 'الْعَفُوُّ', 'english': 'The Pardoner', 'urdu': 'معاف کرنے والا'},
  {'arabic': 'الرَّؤُوفُ', 'english': 'The Most Kind', 'urdu': 'شفقت کرنے والا'},
  {'arabic': 'مَالِكُ الْمُلْكِ', 'english': 'Owner of Sovereignty', 'urdu': 'بادشاہی کا مالک'},
  {'arabic': 'ذُو الْجَلَالِ وَالْإِكْرَامِ', 'english': 'Lord of Majesty', 'urdu': 'جلال و اکرام والا'},
  {'arabic': 'الْمُقْسِطُ', 'english': 'The Equitable', 'urdu': 'انصاف دینے والا'},
  {'arabic': 'الْجَامِعُ', 'english': 'The Gatherer', 'urdu': 'اکٹھا کرنے والا'},
  {'arabic': 'الْغَنِيُّ', 'english': 'The Self-Sufficient', 'urdu': 'بے پرواہ'},
  {'arabic': 'الْمُغْنِي', 'english': 'The Enricher', 'urdu': 'مالدار بنانے والا'},
  {'arabic': 'الْمَانِعُ', 'english': 'The Withholder', 'urdu': 'روکنے والا'},
  {'arabic': 'الضَّارُّ', 'english': 'The Distresser', 'urdu': 'نقصان دینے والا'},
  {'arabic': 'النَّافِعُ', 'english': 'The Benefiter', 'urdu': 'فائدہ دینے والا'},
  {'arabic': 'النُّورُ', 'english': 'The Light', 'urdu': 'روشنی'},
  {'arabic': 'الْهَادِي', 'english': 'The Guide', 'urdu': 'ہدایت دینے والا'},
  {'arabic': 'الْبَدِيعُ', 'english': 'The Incomparable', 'urdu': 'بے مثال'},
  {'arabic': 'الْبَاقِي', 'english': 'The Everlasting', 'urdu': 'ہمیشہ رہنے والا'},
  {'arabic': 'الْوَارِثُ', 'english': 'The Inheritor', 'urdu': 'وارث'},
  {'arabic': 'الرَّشِيدُ', 'english': 'The Guide to Right Path', 'urdu': 'سیدھی راہ دکھانے والا'},
  {'arabic': 'الصَّبُورُ', 'english': 'The Patient', 'urdu': 'صبر کرنے والا'},
];

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimeModel? prayerTimes;
  bool isFetchingFresh = false;
  String errorMsg = '';
  String nextPrayer = '';
  HadithModel? _todaysHadith;

  // 99 Names search
  String _namesSearch = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCachedTimes();
    Future.delayed(const Duration(milliseconds: 500), _fetchFreshTimes);
    _loadHadithData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleHadithNotification();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHadithData() async {
    await HadithService.preload();
    final hadith = await HadithService.getTodaysHadith();
    if (mounted) setState(() => _todaysHadith = hadith);
  }

  Future<void> _scheduleHadithNotification() async {
    try {
      await NotificationService.scheduleDailyHadithNotification(
        context: context,
        hour: 8,
        minute: 0,
      );
    } catch (e) {
      print('Error scheduling hadith notification: $e');
    }
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
      final hasPermission = await locService.requestPermission();
      if (!hasPermission) throw Exception('Location permission denied');

      final position = await locService.getCurrentLocation();
      final times = await PrayerApiService()
          .fetchPrayerTimes(position.latitude, position.longitude);

      await PrefsHelper.cachePrayerTimes(times);

      if (mounted) {
        setState(() {
          prayerTimes = times;
          errorMsg = '';
        });
        _calculateNextPrayer();

        // ── Schedule azan alarms with fresh times ─────────────────────────
        await NotificationService.scheduleAzanAlarms(
          fajr: times.fajr,
          dhuhr: times.dhuhr,
          asr: times.asr,
          maghrib: times.maghrib,
          isha: times.isha,
        );
      }
    } catch (e) {
      if (mounted && prayerTimes == null) {
        setState(() => errorMsg = e.toString());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not update prayer times. Using cached data.')),
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

    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes!.fajr},
      {'name': 'Dhuhr', 'time': prayerTimes!.dhuhr},
      {'name': 'Asr', 'time': prayerTimes!.asr},
      {'name': 'Maghrib', 'time': prayerTimes!.maghrib},
      {'name': 'Isha', 'time': prayerTimes!.isha},
    ];

    for (final prayer in prayers) {
      final prayerDateTime =
          DateTime.parse('$today ${prayer['time']}');
      if (prayerDateTime.isAfter(now)) {
        if (nextPrayer != prayer['name']) {
          setState(() => nextPrayer = prayer['name']!);
        }
        return;
      }
    }
    if (nextPrayer != 'Fajr (Tomorrow)') {
      setState(() => nextPrayer = 'Fajr (Tomorrow)');
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
    } catch (_) {
      return time24;
    }
  }

  String _getPrayerName(String name, bool isUrdu) {
    if (!isUrdu) return name;
    const map = {
      'Fajr': 'فجر',
      'Dhuhr': 'ظہر',
      'Asr': 'عصر',
      'Maghrib': 'مغرب',
      'Isha': 'عشاء',
    };
    return map[name] ?? name;
  }

  String _getNextPrayerDisplay(bool isUrdu) {
    if (!isUrdu) return nextPrayer;
    const map = {
      'Fajr': 'فجر',
      'Dhuhr': 'ظہر',
      'Asr': 'عصر',
      'Maghrib': 'مغرب',
      'Isha': 'عشاء',
      'Fajr (Tomorrow)': 'فجر (کل)',
    };
    return map[nextPrayer] ?? nextPrayer;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      drawer: _buildDrawer(context, isUrdu),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Icon(Icons.menu, color: primaryColor),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    Text(
                      isUrdu ? 'نماز کے اوقات' : 'Prayer Times',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StreakTrackerScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.local_fire_department,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              if (prayerTimes != null)
                _buildNextPrayerCard(isUrdu, primaryColor),

              Expanded(
                child: prayerTimes == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildScrollBody(isUrdu, primaryColor, cardColor,
                        textPrimary, textSecondary, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scrollable body: prayer list + 99 Names ────────────────────────────
  Widget _buildScrollBody(bool isUrdu, Color primaryColor, Color cardColor,
      Color textPrimary, Color textSecondary, bool isDark) {
    final filtered = _namesSearch.isEmpty
        ? _allahNames
        : _allahNames
            .where((n) =>
                n['arabic']!.contains(_namesSearch) ||
                n['english']!
                    .toLowerCase()
                    .contains(_namesSearch.toLowerCase()) ||
                n['urdu']!.contains(_namesSearch))
            .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Prayer time cards
        _prayerCard('Fajr', _formatTo12Hour(prayerTimes!.fajr),
            Icons.wb_twilight, isUrdu, nextPrayer == 'Fajr',
            primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Dhuhr', _formatTo12Hour(prayerTimes!.dhuhr),
            Icons.wb_sunny, isUrdu, nextPrayer == 'Dhuhr',
            primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Asr', _formatTo12Hour(prayerTimes!.asr),
            Icons.brightness_5, isUrdu, nextPrayer == 'Asr',
            primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Maghrib', _formatTo12Hour(prayerTimes!.maghrib),
            Icons.nights_stay, isUrdu, nextPrayer == 'Maghrib',
            primaryColor, cardColor, textPrimary, isDark),
        _prayerCard('Isha', _formatTo12Hour(prayerTimes!.isha),
            Icons.nightlight_round, isUrdu, nextPrayer == 'Isha',
            primaryColor, cardColor, textPrimary, isDark),

        const SizedBox(height: 24),

        // ── 99 Names section header ────────────────────────────────
        Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              isUrdu ? 'اللہ کے ۹۹ نام' : '99 Names of Allah',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _namesSearch = v),
          decoration: InputDecoration(
            hintText: isUrdu ? 'نام تلاش کریں...' : 'Search names...',
            prefixIcon: Icon(Icons.search, color: primaryColor),
            suffixIcon: _namesSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _namesSearch = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: primaryColor.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),

        // Names grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final name = filtered[index];
            // Number in original list
            final number = _allahNames.indexOf(name) + 1;
            return _nameCard(
              number: number,
              arabic: name['arabic']!,
              translation:
                  isUrdu ? name['urdu']! : name['english']!,
              primaryColor: primaryColor,
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _nameCard({
    required int number,
    required String arabic,
    required String translation,
    required Color primaryColor,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
          ),
          const SizedBox(height: 6),
          // Arabic name
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Translation
          Text(
            translation,
            style: TextStyle(fontSize: 11, color: textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Next prayer banner ─────────────────────────────────────────────────
  Widget _buildNextPrayerCard(bool isUrdu, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [primaryColor.withOpacity(0.8), primaryColor.withOpacity(0.6)]
        : [AppColors.primaryMuted, AppColors.secondaryMuted];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              isUrdu ? 'اگلی نماز' : 'Next Prayer',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              _getNextPrayerDisplay(isUrdu),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, bool isUrdu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: isDark
                      ? [
                          primaryColor.withOpacity(0.8),
                          primaryColor.withOpacity(0.6)
                        ]
                      : [AppColors.primaryMuted, AppColors.secondaryMuted]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(isUrdu ? 'اسمارٹ نماز' : 'Smart Namaz',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(isUrdu ? 'ساتھی' : 'Companion',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          // Islamic Calendar
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isUrdu ? 'اسلامی کیلنڈر' : 'Islamic Calendar',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(HijriService.getFormattedHijriDate(isUrdu),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                      isUrdu ? 'عیسوی تاریخ:' : 'Gregorian Date:',
                      style: TextStyle(fontSize: 14, color: textSecondary)),
                  Text(HijriService.getGregorianDate(isUrdu),
                      style:
                          TextStyle(fontSize: 16, color: textPrimary)),
                ],
              ),
            ),
          ),
          // Hadith
          _todaysHadith == null
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()))
              : _buildHadithCard(_todaysHadith!, isUrdu, primaryColor,
                  cardColor, textPrimary, textSecondary),
          // Settings
          ListTile(
            leading: Icon(Icons.settings, color: primaryColor),
            title: Text(isUrdu ? 'سیٹنگز' : 'Settings',
                style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHadithCard(HadithModel hadith, bool isUrdu,
      Color primaryColor, Color cardColor, Color textPrimary, Color textSecondary) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu ? 'آج کی حدیث' : "Today's Hadith",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(hadith.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'serif',
                    color: textPrimary)),
            const SizedBox(height: 12),
            Text(isUrdu ? hadith.urduText : hadith.englishText,
                style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: textPrimary)),
            const SizedBox(height: 8),
            Text(
                isUrdu
                    ? hadith.urduTranslation
                    : hadith.englishTranslation,
                style:
                    TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 8),
            Text(
                isUrdu ? hadith.urduTafseer : hadith.englishTafseer,
                style:
                    TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 8),
            Text(hadith.reference,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _prayerCard(
      String name,
      String timeFormatted,
      IconData icon,
      bool isUrdu,
      bool isNext,
      Color primaryColor,
      Color cardColor,
      Color textPrimary,
      bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isNext ? 4 : 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isNext
              ? primaryColor.withOpacity(isDark ? 0.2 : 0.1)
              : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            _getPrayerName(name, isUrdu),
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  isNext ? FontWeight.bold : FontWeight.normal,
              color: textPrimary,
            ),
          ),
          trailing: Text(timeFormatted,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textPrimary)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      PrayerGuidanceScreen(prayerName: name))),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../services/streak_service.dart';
import '../models/daily_prayer_record.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';

class StreakTrackerScreen extends StatefulWidget {
  @override
  _StreakTrackerScreenState createState() => _StreakTrackerScreenState();
}

class _StreakTrackerScreenState extends State<StreakTrackerScreen>
    with TickerProviderStateMixin {
  late StreakService _streakService;
  Map<DateTime, DailyPrayerRecord?> _records = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _currentStreak = 0;
  int _bestStreak = 0;

  late AnimationController _headerAnim;
  late AnimationController _cardAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _cardSlide;

  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  // Prayer icons
  final Map<String, IconData> _prayerIcons = {
    'Fajr':    Icons.wb_twilight,
    'Dhuhr':   Icons.wb_sunny,
    'Asr':     Icons.brightness_5,
    'Maghrib': Icons.nights_stay,
    'Isha':    Icons.nightlight_round,
  };

  @override
  void initState() {
    super.initState();
    _streakService = StreakService();

    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardAnim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _cardSlide  = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));

    _loadData();
    _headerAnim.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _cardAnim.forward());
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _cardAnim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final recordsMap = await _streakService.getAllRecords();
    setState(() {
      _records.clear();
      recordsMap.forEach((date, record) {
        _records[DateTime(date.year, date.month, date.day)] = record;
      });
    });
    _refreshStreakCounts();
  }

  Future<void> _refreshStreakCounts() async {
    final current = await _streakService.getCurrentStreak();
    final best    = await _streakService.getBestStreak();
    setState(() {
      _currentStreak = current;
      _bestStreak    = best;
    });
  }

  Future<void> _togglePrayer(String prayer, bool value) async {
    HapticFeedback.selectionClick();
    try {
      final normalized = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      DailyPrayerRecord? record = _records[normalized];
      if (record == null) {
        record = DailyPrayerRecord(
          date: normalized,
          prayersCompleted: {for (var p in _prayerNames) p: false},
        );
      }
      record.prayersCompleted[prayer] = value;
      await _streakService.saveRecord(record);
      setState(() => _records[normalized] = record);
      await _refreshStreakCounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving prayer: $e')),
      );
    }
  }

  String _getPrayerName(String name, bool isUrdu) {
    if (!isUrdu) return name;
    const map = {'Fajr': 'فجر', 'Dhuhr': 'ظہر', 'Asr': 'عصر', 'Maghrib': 'مغرب', 'Isha': 'عشاء'};
    return map[name] ?? name;
  }

  String _formatSelectedDate(bool isUrdu) {
    final d = _selectedDay;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final isToday = isSameDay(d, DateTime.now());
    if (isUrdu) return '${d.day}/${d.month}/${d.year}';
    if (isToday) return 'Today · ${months[d.month - 1]} ${d.day}';
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // Color based on completion
  Color _dayColor(DailyPrayerRecord? record, Color primary) {
    if (record == null) return Colors.transparent;
    if (record.allCompleted) return Colors.green;
    if (record.completedCount > 0) return Colors.orange;
    return Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu      = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    final normalized    = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final selectedRecord = _records[normalized];
    final Map<String, bool> prayerStatus = selectedRecord?.prayersCompleted ??
        {for (var p in _prayerNames) p: false};
    final completedCount = prayerStatus.values.where((v) => v).length;
    final progress = completedCount / _prayerNames.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'اسٹریک ٹریکر' : 'Streak Tracker'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero streak banner ──────────────────────────────────────
            FadeTransition(
              opacity: _headerFade,
              child: _buildStreakBanner(primaryColor, isDark, isUrdu, textSecondary),
            ),

            const SizedBox(height: 4),

            // ── Calendar ────────────────────────────────────────────────
            SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardAnim.drive(CurveTween(curve: Curves.easeOut)),
                child: _buildCalendar(primaryColor, cardColor, isDark, isUrdu),
              ),
            ),

            const SizedBox(height: 12),

            // ── Daily prayer card ────────────────────────────────────────
            SlideTransition(
              position: _cardSlide,
              child: _buildDailyCard(
                isUrdu, primaryColor, cardColor, textPrimary,
                textSecondary, isDark, prayerStatus, completedCount, progress,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Streak banner ──────────────────────────────────────────────────────────

  Widget _buildStreakBanner(Color primary, bool isDark, bool isUrdu, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primary.withOpacity(0.85), primary.withOpacity(0.5)]
              : [AppColors.primaryMuted, AppColors.secondaryMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Current streak
          Expanded(child: _streakStat(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange.shade300,
            value: '$_currentStreak',
            label: isUrdu ? 'موجودہ اسٹریک' : 'Current Streak',
          )),

          // Divider
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),

          // Best streak
          Expanded(child: _streakStat(
            icon: Icons.emoji_events_rounded,
            iconColor: Colors.amber.shade300,
            value: '$_bestStreak',
            label: isUrdu ? 'بہترین اسٹریک' : 'Best Streak',
          )),

          // Divider
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),

          // Total days recorded
          Expanded(child: _streakStat(
            icon: Icons.calendar_month_rounded,
            iconColor: Colors.lightBlue.shade200,
            value: '${_records.length}',
            label: isUrdu ? 'کل دن' : 'Days Logged',
          )),
        ],
      ),
    );
  }

  Widget _streakStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Calendar ───────────────────────────────────────────────────────────────

  Widget _buildCalendar(Color primary, Color cardColor, bool isDark, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: TableCalendar(
          firstDay: DateTime(2024, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDay  = selectedDay;
              _focusedDay   = focusedDay;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            leftChevronIcon: Icon(Icons.chevron_left_rounded,
                color: primary, size: 28),
            rightChevronIcon: Icon(Icons.chevron_right_rounded,
                color: primary, size: 28),
            headerPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            weekendStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: primary.withOpacity(0.8),
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
            selectedDecoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            defaultTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            weekendTextStyle: TextStyle(
              color: primary.withOpacity(0.85),
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final record = _records[DateTime(day.year, day.month, day.day)];
              if (record == null) return null;
              final color = _dayColor(record, primary);
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Daily prayer card ──────────────────────────────────────────────────────

  Widget _buildDailyCard(
    bool isUrdu, Color primary, Color cardColor, Color textPrimary,
    Color textSecondary, bool isDark,
    Map<String, bool> prayerStatus, int completedCount, double progress,
  ) {
    // Progress color
    Color progressColor;
    if (completedCount == 5) progressColor = Colors.green;
    else if (completedCount >= 3) progressColor = Colors.orange;
    else progressColor = primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isUrdu ? 'نمازیں' : 'Prayers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  Text(
                    _formatSelectedDate(isUrdu),
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ]),
                // Completion badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: progressColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$completedCount / ${_prayerNames.length}',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: progressColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Progress bar ───────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              completedCount == 5
                  ? (isUrdu ? '🎉 تمام نمازیں ادا کر لی گئیں!' : '🎉 All prayers completed!')
                  : isUrdu
                      ? '${_prayerNames.length - completedCount} نمازیں باقی ہیں'
                      : '${_prayerNames.length - completedCount} remaining',
              style: TextStyle(
                fontSize: 12,
                color: completedCount == 5 ? Colors.green : textSecondary,
                fontWeight: completedCount == 5 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),

            const SizedBox(height: 16),

            // ── Prayer toggle rows ─────────────────────────────────────
            ..._prayerNames.asMap().entries.map((entry) {
              final prayer  = entry.value;
              final checked = prayerStatus[prayer] ?? false;
              final icon    = _prayerIcons[prayer] ?? Icons.access_time;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _togglePrayer(prayer, !checked),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: checked
                          ? Colors.green.withOpacity(isDark ? 0.2 : 0.08)
                          : isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: checked
                            ? Colors.green.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Prayer icon box
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: checked
                                ? Colors.green.withOpacity(0.15)
                                : primary.withOpacity(isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              color: checked ? Colors.green : primary, size: 20),
                        ),
                        const SizedBox(width: 14),

                        // Prayer name
                        Expanded(
                          child: Text(
                            _getPrayerName(prayer, isUrdu),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: checked
                                  ? Colors.green
                                  : textPrimary,
                            ),
                          ),
                        ),

                        // Custom checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: checked ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: checked ? Colors.green : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: checked
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
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

class _StreakTrackerScreenState extends State<StreakTrackerScreen> {
  late StreakService _streakService;
  Map<DateTime, DailyPrayerRecord?> _records = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _currentStreak = 0;
  int _bestStreak = 0;

  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _streakService = StreakService();
    _loadData();
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
    final best = await _streakService.getBestStreak();
    setState(() {
      _currentStreak = current;
      _bestStreak = best;
    });
  }

  Future<void> _togglePrayer(String prayer, bool value) async {
    print("Toggling prayer: $prayer, value: $value");  // Debug print
    try {
      final normalized = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      DailyPrayerRecord? record = _records[normalized];
      if (record == null) {
        final initialPrayers = {for (var p in _prayerNames) p: false};
        record = DailyPrayerRecord(date: normalized, prayersCompleted: initialPrayers);
      }
      record.prayersCompleted[prayer] = value;
      await _streakService.saveRecord(record);
      setState(() {
        _records[normalized] = record;
      });
      await _refreshStreakCounts();
      print("Prayer toggled successfully");
    } catch (e, stacktrace) {
      print("Error toggling prayer: $e");
      print(stacktrace);
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving prayer: $e")),
      );
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

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final selectedRecord = _records[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)];
    final Map<String, bool> currentPrayerStatus = selectedRecord?.prayersCompleted ??
        {for (var p in _prayerNames) p: false};
    final completedCount = currentPrayerStatus.values.where((v) => v == true).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'اسٹریک ٹریکر' : 'Streak Tracker'),
        backgroundColor: AppColors.primaryMuted,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard(isUrdu ? 'موجودہ اسٹریک' : 'Current Streak', '$_currentStreak', Icons.local_fire_department, Colors.orange)),
                  SizedBox(width: 12),
                  Expanded(child: _buildStatCard(isUrdu ? 'بہترین اسٹریک' : 'Best Streak', '$_bestStreak', Icons.emoji_events, Colors.amber)),
                ],
              ),
            ),
            SizedBox(
              height: 380,
              child: TableCalendar(
                firstDay: DateTime(2024, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  markersAlignment: Alignment.bottomCenter,
                  markerSize: 8,
                  todayDecoration: BoxDecoration(color: AppColors.primaryMuted, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final record = _records[DateTime(day.year, day.month, day.day)];
                    if (record != null) {
                      IconData icon;
                      Color color;
                      if (record.allCompleted) {
                        icon = Icons.check_circle;
                        color = Colors.green;
                      } else if (record.completedCount > 0) {
                        icon = Icons.hourglass_empty;
                        color = Colors.orange;
                      } else {
                        icon = Icons.cancel;
                        color = Colors.red;
                      }
                      return Positioned(bottom: 2, child: Icon(icon, size: 16, color: color));
                    }
                    return null;
                  },
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year} کی نمازیں' : 'Prayers on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: completedCount / _prayerNames.length,
                      backgroundColor: Colors.grey[300],
                      color: AppColors.primaryMuted,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: 8),
                    Text(
                      isUrdu ? '$completedCount / ${_prayerNames.length} نمازیں پڑھی گئیں' : '$completedCount / ${_prayerNames.length} prayers performed',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    // Using a ListView.builder inside Column might cause constraints issue,
                    // but here it's fine as number of items is small. However, to avoid overflow,
                    // we can just use Column with children.
                    ..._prayerNames.map((prayer) => 
                      CheckboxListTile(
                        key: ValueKey(prayer), // Give unique key
                        title: Text(_getPrayerName(prayer, isUrdu)),
                        value: currentPrayerStatus[prayer] ?? false,
                        onChanged: (value) {
                          print("Checkbox clicked for $prayer, new value: $value");
                          _togglePrayer(prayer, value ?? false);
                        },
                        activeColor: AppColors.primaryMuted,
                        secondary: Icon(Icons.mosque, color: AppColors.primaryMuted),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
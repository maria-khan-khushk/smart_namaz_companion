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

  @override
  void initState() {
    super.initState();
    _streakService = StreakService();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _streakService.getAllRecords();
    setState(() {
      _records.clear();
      for (var record in records) {
        _records[DateTime(record.date.year, record.date.month, record.date.day)] = record;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'نماز ٹریکر' : 'Prayer Tracker'),
        backgroundColor: AppColors.primaryMuted,
      ),
      body: Column(
        children: [
          TableCalendar(
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
              todayDecoration: BoxDecoration(
                color: AppColors.primaryMuted,
                shape: BoxShape.circle,
              ),
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
                  return Positioned(
                    bottom: 2,
                    child: Icon(icon, size: 16, color: color),
                  );
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 16),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16),
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
                  FutureBuilder<DailyPrayerRecord?>(
                    future: _streakService.getRecordForDate(_selectedDay),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      final record = snapshot.data;
                      if (record == null) {
                        return Text(isUrdu ? 'کوئی ریکارڈ نہیں' : 'No record');
                      }
                      return Column(
                        children: [
                          Text(isUrdu ? 'مکمل نمازیں: ${record.completedCount}/5' : 'Completed: ${record.completedCount}/5'),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: record.prayersCompleted.entries.map((entry) {
                              return Chip(
                                label: Text(entry.key),
                                backgroundColor: entry.value ? Colors.green : Colors.grey,
                                labelStyle: TextStyle(color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
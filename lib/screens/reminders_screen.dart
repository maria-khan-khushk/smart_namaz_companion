import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';
import 'dart:convert';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedTitle = "Azan Reminder";

  final List<String> _titleOptions = [
    "Azan Reminder",
    "Fajr Reminder",
    "Dhuhr Reminder",
    "Asr Reminder",
    "Maghrib Reminder",
    "Isha Reminder",
    "Tahajjud Reminder",
    "Du'a Reminder",
    "Quran Time",
    "Custom"
  ];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('manual_reminders');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      setState(() {
        _reminders = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manual_reminders', json.encode(_reminders));
  }

  Future<void> _addReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).cardColor,
              hourMinuteTextColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() => _selectedTime = picked);

    // Title selection dialog
    String? customTitle;
    final selectedTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempTitle = _titleOptions.first;
        TextEditingController customController = TextEditingController();
        return AlertDialog(
          title: Text(Provider.of<LanguageProvider>(context).isUrdu ? 'عنوان منتخب کریں' : 'Select Title'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: tempTitle,
                    items: _titleOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        tempTitle = val!;
                        if (tempTitle != "Custom") customController.clear();
                      });
                    },
                  ),
                  if (tempTitle == "Custom") ...[
                    SizedBox(height: 12),
                    TextField(
                      controller: customController,
                      decoration: InputDecoration(
                        hintText: Provider.of<LanguageProvider>(context).isUrdu ? 'اپنا عنوان لکھیں' : 'Enter custom title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(Provider.of<LanguageProvider>(context).isUrdu ? 'منسوخ' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String finalTitle = tempTitle;
                if (tempTitle == "Custom") {
                  if (customController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(Provider.of<LanguageProvider>(context).isUrdu ? 'براہ کرم عنوان درج کریں' : 'Please enter a title')),
                    );
                    return;
                  }
                  finalTitle = customController.text.trim();
                }
                Navigator.pop(context, finalTitle);
              },
              child: Text(Provider.of<LanguageProvider>(context).isUrdu ? 'محفوظ کریں' : 'Save'),
            ),
          ],
        );
      },
    );

    if (selectedTitle == null) return;

    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year, now.month, now.day,
      _selectedTime.hour, _selectedTime.minute,
    );
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
    }

    final int id = DateTime.now().millisecondsSinceEpoch % 1000000;

    await NotificationService.scheduleManualReminder(
      id: id,
      title: selectedTitle,
      body: Provider.of<LanguageProvider>(context, listen: false).isUrdu
          ? 'اذان کا وقت ہوگیا ہے'
          : 'Time for Azan',
      scheduledTime: scheduledDateTime,
      soundPath: 'azan',
    );

    final newReminder = {
      'id': id,
      'title': selectedTitle,
      'hour': _selectedTime.hour,
      'minute': _selectedTime.minute,
      'scheduledTime': scheduledDateTime.toIso8601String(),
    };
    setState(() {
      _reminders.add(newReminder);
    });
    await _saveReminders();

    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isUrdu ? 'یاد دہانی مقرر ہوگئی' : 'Reminder scheduled')),
    );
  }

  Future<void> _deleteReminder(int index) async {
    final reminder = _reminders[index];
    final int id = reminder['id'];
    await NotificationService.cancelNotification(id);
    setState(() {
      _reminders.removeAt(index);
    });
    await _saveReminders();
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isUrdu ? 'یاد دہانی منسوخ کردی گئی' : 'Reminder cancelled')),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'دستی یاد دہانیاں' : 'Manual Reminders'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add_alarm),
              label: Text(isUrdu ? 'نئی یاد دہانی شامل کریں' : 'Add New Reminder'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _addReminder,
            ),
          ),
          Expanded(
            child: _reminders.isEmpty
                ? Center(
                    child: Text(
                      isUrdu ? 'کوئی یاد دہانی نہیں' : 'No reminders set',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final rem = _reminders[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Icon(Icons.alarm, color: Theme.of(context).primaryColor),
                          title: Text(rem['title']),
                          subtitle: Text(_formatTime(rem['hour'], rem['minute'])),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteReminder(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../providers/language_provider.dart';
import 'dart:convert';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedTitle = 'Azan Reminder';

  final List<String> _titleOptions = [
    'Azan Reminder',
    'Fajr Reminder',
    'Dhuhr Reminder',
    'Asr Reminder',
    'Maghrib Reminder',
    'Isha Reminder',
    'Tahajjud Reminder',
    "Du'a Reminder",
    'Quran Time',
    'Custom',
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
        _reminders = decoded
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manual_reminders', json.encode(_reminders));
  }

  Future<void> _addReminder() async {
    final isUrdu =
        Provider.of<LanguageProvider>(context, listen: false).isUrdu;

    // Step 1 — pick time
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Theme.of(context).cardColor,
            hourMinuteTextColor:
                Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);

    // Step 2 — pick title
    final String? selectedTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempTitle = _titleOptions.first;
        final customController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(isUrdu ? 'عنوان منتخب کریں' : 'Select Title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: tempTitle,
                  isExpanded: true,
                  items: _titleOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() {
                    tempTitle = val!;
                    if (tempTitle != 'Custom') customController.clear();
                  }),
                ),
                if (tempTitle == 'Custom') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customController,
                    decoration: InputDecoration(
                      hintText: isUrdu
                          ? 'اپنا عنوان لکھیں'
                          : 'Enter custom title',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Azan sound notice
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.volume_up_rounded,
                        size: 16,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'اذان کی آواز خودبخود بجے گی'
                            : 'Azan sound will play automatically',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String finalTitle = tempTitle;
                  if (tempTitle == 'Custom') {
                    if (customController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isUrdu
                            ? 'براہ کرم عنوان درج کریں'
                            : 'Please enter a title'),
                      ));
                      return;
                    }
                    finalTitle = customController.text.trim();
                  }
                  Navigator.pop(context, finalTitle);
                },
                child: Text(isUrdu ? 'محفوظ کریں' : 'Save'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedTitle == null) return;

    // Build scheduled DateTime
    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year, now.month, now.day,
      _selectedTime.hour, _selectedTime.minute,
    );
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final int id = DateTime.now().millisecondsSinceEpoch % 1000000;

    // Schedule with azan sound
    await NotificationService.scheduleManualReminder(
      id: id,
      title: selectedTitle,
      body: isUrdu ? 'اذان کا وقت ہوگیا ہے' : 'Time for Azan',
      scheduledTime: scheduledDateTime,
    );

    setState(() {
      _reminders.add({
        'id': id,
        'title': selectedTitle,
        'hour': _selectedTime.hour,
        'minute': _selectedTime.minute,
        'scheduledTime': scheduledDateTime.toIso8601String(),
      });
    });
    await _saveReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(isUrdu
                ? 'یاد دہانی مقرر ہوگئی — اذان بجے گی'
                : 'Reminder set — Azan will play'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _deleteReminder(int index) async {
    final isUrdu =
        Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    final reminder = _reminders[index];
    await NotificationService.cancelNotification(reminder['id'] as int);
    setState(() => _reminders.removeAt(index));
    await _saveReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'یاد دہانی منسوخ کردی گئی' : 'Reminder cancelled'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int h12 = hour % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  // ── Determine if a reminder is still in the future ──────────────────────
  bool _isUpcoming(Map<String, dynamic> reminder) {
    try {
      final scheduled =
          DateTime.parse(reminder['scheduledTime'] as String);
      return scheduled.isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'دستی یاد دہانیاں' : 'Manual Reminders'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Add button + info banner ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: Text(isUrdu
                      ? 'نئی یاد دہانی شامل کریں'
                      : 'Add New Reminder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _addReminder,
                ),
                const SizedBox(height: 10),
                // Info strip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.volume_up_rounded,
                        size: 18, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'ہر یاد دہانی پر اذان کی آواز خودبخود بجے گی'
                            : 'Azan sound plays automatically at reminder time',
                        style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Reminder list ────────────────────────────────────────────
          Expanded(
            child: _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_off_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          isUrdu ? 'کوئی یاد دہانی نہیں' : 'No reminders set',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isUrdu
                              ? 'اوپر بٹن دبائیں'
                              : 'Tap the button above to add one',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final rem = _reminders[index];
                      final upcoming = _isUpcoming(rem);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: upcoming
                                ? primaryColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: upcoming
                                  ? primaryColor
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.alarm_rounded,
                                color: Colors.white, size: 22),
                          ),
                          title: Text(
                            rem['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: upcoming ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(
                                    rem['hour'] as int, rem['minute'] as int),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: upcoming
                                      ? primaryColor
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Azan badge
                              Row(children: [
                                Icon(Icons.volume_up_rounded,
                                    size: 12,
                                    color: upcoming
                                        ? primaryColor.withOpacity(0.7)
                                        : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  isUrdu ? 'اذان بجے گی' : 'Azan will play',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: upcoming
                                        ? primaryColor.withOpacity(0.7)
                                        : Colors.grey,
                                  ),
                                ),
                                if (!upcoming) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    isUrdu ? '(گزر گیا)' : '(passed)',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ]),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
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
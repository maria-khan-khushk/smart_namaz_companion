import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../providers/language_provider.dart';
import 'dart:convert';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _reminders = [];
  TimeOfDay _selectedTime = TimeOfDay.now();
  late AnimationController _fabAnim;

  final List<Map<String, dynamic>> _titleOptions = [
    {'label': 'Fajr',     'urdu': 'فجر',  'icon': Icons.wb_twilight},
    {'label': 'Dhuhr',    'urdu': 'ظہر',  'icon': Icons.wb_sunny},
    {'label': 'Asr',      'urdu': 'عصر',  'icon': Icons.brightness_5},
    {'label': 'Maghrib',  'urdu': 'مغرب', 'icon': Icons.nights_stay},
    {'label': 'Isha',     'urdu': 'عشاء', 'icon': Icons.nightlight_round},
    {'label': 'Tahajjud', 'urdu': 'تہجد', 'icon': Icons.bedtime},
    {'label': "Du'a",     'urdu': 'دعا',  'icon': Icons.favorite_border},
    {'label': 'Quran',    'urdu': 'قرآن', 'icon': Icons.menu_book},
    {'label': 'Custom',   'urdu': 'کسٹم', 'icon': Icons.edit_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _loadReminders();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  // Pre-parsed DateTime cache — avoids expensive DateTime.parse() in build loop
  final Map<int, DateTime> _parsedTimes = {};

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('manual_reminders');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      final reminders = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      // Pre-parse all DateTime strings once at load time
      _parsedTimes.clear();
      for (final r in reminders) {
        try {
          _parsedTimes[r['id'] as int] = DateTime.parse(r['scheduledTime'] as String);
        } catch (_) {}
      }
      setState(() {
        _reminders = reminders;
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manual_reminders', json.encode(_reminders));
  }

  Future<void> _addReminder() async {
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;

    // Step 1 — time picker
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(ctx).cardColor),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);

    // Step 2 — label picker bottom sheet
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LabelPickerSheet(
        isUrdu: isUrdu,
        titleOptions: _titleOptions,
        primaryColor: Theme.of(context).primaryColor,
        cardColor: Theme.of(context).cardColor,
        selectedTime: picked,
      ),
    );
    if (result == null || !mounted) return;

    final String finalTitle = result['title'] as String;
    final now = DateTime.now();
    DateTime scheduled = DateTime(
        now.year, now.month, now.day, picked.hour, picked.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final int id = DateTime.now().millisecondsSinceEpoch % 1000000;
    try {
      await NotificationService.scheduleManualReminder(
        id: id,
        title: finalTitle,
        body: 'Time for prayer',
        scheduledTime: scheduled,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'Notification permission is required',
        Icons.notifications_off_rounded,
        Colors.red.shade600,
      );
      return;
    }

    setState(() {
      _reminders.add({
        'id': id,
        'title': finalTitle,
        'hour': picked.hour,
        'minute': picked.minute,
        'scheduledTime': scheduled.toIso8601String(),
      });
      // Cache the parsed DateTime
      _parsedTimes[id] = scheduled;
    });
    await _saveReminders();
    if (mounted) _showSnack(
      isUrdu ? 'یاد دہانی ترتیب دے دی گئی' : 'Reminder scheduled',
      Icons.check_circle_outline_rounded,
      Colors.green.shade600,
    );
  }

  Future<void> _deleteReminder(int index) async {
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUrdu ? 'یاد دہانی ہٹائیں؟' : 'Remove Reminder?'),
        content: Text(
          isUrdu ? 'یہ یاد دہانی منسوخ کر دی جائے گی۔'
                 : 'This reminder will be cancelled.',
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(ctx).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isUrdu ? 'نہیں' : 'Cancel',
                style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodyMedium?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isUrdu ? 'ہاں، ہٹائیں' : 'Remove',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await NotificationService.cancelNotification(_reminders[index]['id'] as int);
    setState(() => _reminders.removeAt(index));
    await _saveReminders();
    if (mounted) _showSnack(
      isUrdu ? 'یاد دہانی ہٹا دی گئی' : 'Reminder removed',
      Icons.remove_circle_outline_rounded,
      Colors.grey.shade700,
    );
  }

  void _showSnack(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int h = hour % 12;
    if (h == 0) h = 12;
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  bool _isUpcoming(Map<String, dynamic> r) {
    // Use pre-parsed DateTime from cache instead of parsing string every frame
    final parsed = _parsedTimes[r['id'] as int];
    if (parsed != null) return parsed.isAfter(DateTime.now());
    try {
      return DateTime.parse(r['scheduledTime'] as String).isAfter(DateTime.now());
    } catch (_) { return true; }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu      = Provider.of<LanguageProvider>(context).isUrdu;
    final primary     = Theme.of(context).primaryColor;
    final cardColor   = Theme.of(context).cardColor;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSec     = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final upcoming    = _reminders.where(_isUpcoming).length;
    final passed      = _reminders.length - upcoming;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'یاد دہانیاں' : 'Reminders'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.easeOutBack),
        child: FloatingActionButton.extended(
          onPressed: _addReminder,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_alarm_rounded, size: 22),
          label: Text(isUrdu ? 'نئی یاد دہانی' : 'New Reminder',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: _reminders.isEmpty
          ? _buildEmpty(isUrdu, primary)
          : Column(children: [
              // Summary strip attached to AppBar
              Container(
                color: primary,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  _chip('$upcoming', isUrdu ? 'آنے والی' : 'Upcoming',
                      Colors.white, Colors.white.withOpacity(0.2)),
                  if (passed > 0) ...[
                    const SizedBox(width: 8),
                    _chip('$passed', isUrdu ? 'گزر گئی' : 'Passed',
                        Colors.white70, Colors.white.withOpacity(0.1)),
                  ],
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.volume_up_rounded, size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(isUrdu ? 'اذان آواز' : 'Azan sound',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _reminders.length,
                  itemBuilder: (ctx, i) => _buildCard(
                      i, isUrdu, primary, cardColor, isDark, textPrimary, textSec),
                ),
              ),
            ]),
    );
  }

  Widget _chip(String count, String label, Color text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: text)),
      ]),
    );
  }

  Widget _buildEmpty(bool isUrdu, Color primary) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
            color: primary.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(Icons.alarm_rounded, size: 36, color: primary.withOpacity(0.45)),
      ),
      const SizedBox(height: 20),
      Text(isUrdu ? 'کوئی یاد دہانی نہیں' : 'No reminders yet',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      const SizedBox(height: 6),
      Text(
        isUrdu ? 'نیچے بٹن سے یاد دہانی شامل کریں' : 'Use the button below to schedule one',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      ),
      const SizedBox(height: 90),
    ]));
  }

  Widget _buildCard(int index, bool isUrdu, Color primary, Color cardColor,
      bool isDark, Color textPrimary, Color textSec) {
    final rem      = _reminders[index];
    final upcoming = _isUpcoming(rem);
    final timeStr  = _formatTime(rem['hour'] as int, rem['minute'] as int);
    final title    = rem['title'] as String;

    // Match icon from options list
    final match = _titleOptions.firstWhere(
      (t) => (t['label'] as String).toLowerCase() == title.toLowerCase(),
      orElse: () => _titleOptions.last,
    );
    final IconData icon = match['icon'] as IconData;

    return Dismissible(
      key: ValueKey(rem['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { await _deleteReminder(index); return false; },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red.shade400, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: upcoming ? primary.withOpacity(0.2) : Colors.grey.withOpacity(0.12),
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Icon
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: upcoming ? primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: upcoming ? textPrimary : Colors.grey)),
              const SizedBox(height: 2),
              Text(timeStr,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: upcoming ? primary : Colors.grey, letterSpacing: -0.5)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(
                  upcoming ? Icons.volume_up_rounded : Icons.check_circle_outline_rounded,
                  size: 12,
                  color: upcoming ? primary.withOpacity(0.6) : Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  upcoming
                      ? (isUrdu ? 'اذان بجے گی' : 'Azan will play')
                      : (isUrdu ? 'گزر گئی' : 'Passed'),
                  style: TextStyle(fontSize: 11,
                      color: upcoming ? primary.withOpacity(0.6) : Colors.grey.shade400),
                ),
              ]),
            ])),
            // Delete
            IconButton(
              onPressed: () => _deleteReminder(index),
              icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 22),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label picker — modal bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LabelPickerSheet extends StatefulWidget {
  final bool isUrdu;
  final List<Map<String, dynamic>> titleOptions;
  final Color primaryColor;
  final Color cardColor;
  final TimeOfDay selectedTime;

  const _LabelPickerSheet({
    required this.isUrdu,
    required this.titleOptions,
    required this.primaryColor,
    required this.cardColor,
    required this.selectedTime,
  });

  @override
  State<_LabelPickerSheet> createState() => _LabelPickerSheetState();
}

class _LabelPickerSheetState extends State<_LabelPickerSheet> {
  int _selected = 0;
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void dispose() { _customCtrl.dispose(); super.dispose(); }

  String _fmt(TimeOfDay t) {
    final p = t.hour >= 12 ? 'PM' : 'AM';
    int h = t.hour % 12; if (h == 0) h = 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} $p';
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final isCustom    = widget.titleOptions[_selected]['label'] == 'Custom';

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.isUrdu ? 'نماز منتخب کریں' : 'Select Prayer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              Text(_fmt(widget.selectedTime),
                  style: TextStyle(fontSize: 13, color: widget.primaryColor,
                      fontWeight: FontWeight.w500)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.volume_up_rounded, size: 13, color: widget.primaryColor),
                const SizedBox(width: 4),
                Text(widget.isUrdu ? 'اذان' : 'Azan',
                    style: TextStyle(fontSize: 12, color: widget.primaryColor,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ]),
        ),

        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.titleOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 10,
                crossAxisSpacing: 10, childAspectRatio: 1.55),
            itemBuilder: (ctx, i) {
              final opt      = widget.titleOptions[i];
              final selected = _selected == i;
              return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _selected = i); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: selected ? widget.primaryColor
                        : isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? widget.primaryColor : Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(opt['icon'] as IconData, size: 22,
                        color: selected ? Colors.white : widget.primaryColor),
                    const SizedBox(height: 5),
                    Text(
                      widget.isUrdu ? opt['urdu'] as String : opt['label'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : textPrimary),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),

        // Custom input
        if (isCustom) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _customCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.isUrdu ? 'یاد دہانی کا عنوان' : 'Reminder title',
                filled: true,
                fillColor: widget.primaryColor.withOpacity(0.06),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Confirm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              String title = widget.isUrdu
                  ? widget.titleOptions[_selected]['urdu'] as String
                  : widget.titleOptions[_selected]['label'] as String;
              if (isCustom) {
                final c = _customCtrl.text.trim();
                if (c.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(widget.isUrdu ? 'عنوان درج کریں' : 'Please enter a title'),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                  return;
                }
                title = c;
              }
              Navigator.pop(context, {'title': title});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(widget.isUrdu ? 'ترتیب دیں' : 'Schedule Reminder',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'guidance_screen.dart';

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with TickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  bool _targetReachedShown = false;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;
  double _animatedProgress = 0;

  // Common dhikr presets
  final List<Map<String, dynamic>> _presets = [
    {'label': 'SubhanAllah', 'urdu': 'سبحان اللہ', 'count': 33},
    {'label': 'Alhamdulillah', 'urdu': 'الحمد للہ', 'count': 33},
    {'label': 'AllahuAkbar', 'urdu': 'اللہ اکبر', 'count': 34},
    {'label': 'Astaghfirullah', 'urdu': 'استغفر اللہ', 'count': 100},
  ];
  int _selectedPreset = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _animatedProgress = _progressAnim.value;
        });
      });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _increment() {
    if (_counter >= _target) return;
    HapticFeedback.lightImpact();

    // Button press animation
    _pulseController.forward().then((_) => _pulseController.reverse());

    setState(() {
      _counter++;
    });

    // Animate progress ring
    double newProgress = _counter / _target;
    _progressAnim = Tween<double>(
      begin: _animatedProgress,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _progressController.forward(from: 0);

    if (_counter == _target && !_targetReachedShown) {
      _targetReachedShown = true;
      HapticFeedback.mediumImpact();
      _showTargetCompletion();
    }
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _counter = 0;
      _targetReachedShown = false;
    });
    _progressAnim = Tween<double>(begin: _animatedProgress, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _progressController.forward(from: 0);
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPreset = index;
      _target = _presets[index]['count'] as int;
      _counter = 0;
      _targetReachedShown = false;
    });
    _progressAnim = Tween<double>(begin: _animatedProgress, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _progressController.forward(from: 0);
  }

  void _setCustomTarget() async {
    final isUrdu =
        Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    final controller = TextEditingController(text: _target.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUrdu ? 'حد مقرر کریں' : 'Set Custom Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isUrdu ? 'مطلوبہ تعداد' : 'Enter count',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTarget = int.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                setState(() {
                  _target = newTarget;
                  if (_counter > _target) _counter = _target;
                  _targetReachedShown = (_counter == _target);
                  _selectedPreset = -1;
                });
                double newProgress = _counter / _target;
                _progressAnim = Tween<double>(
                  begin: _animatedProgress,
                  end: newProgress,
                ).animate(CurvedAnimation(
                    parent: _progressController, curve: Curves.easeOut));
                _progressController.forward(from: 0);
              }
              Navigator.pop(context);
            },
            child: Text(isUrdu ? 'محفوظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showTargetCompletion() {
    final isUrdu =
        Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isUrdu
                  ? 'مبارک ہو! آپ نے حد مکمل کر لی!'
                  : 'Mashallah! Target complete!',
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'تسبیح کاؤنٹر' : 'Tasbeeh Counter'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Text('🤲', style: TextStyle(fontSize: 22)),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => GuidanceScreen())),
            tooltip: isUrdu ? 'اذکار اور دعائیں' : 'Dhikr & Duas',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ── Preset chips ──────────────────────────────────────────
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = _selectedPreset == i;
                    return ChoiceChip(
                      label: Text(
                        isUrdu
                            ? _presets[i]['urdu'] as String
                            : _presets[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected ? Colors.white : textSecondary,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => _selectPreset(i),
                      selectedColor: primaryColor,
                      backgroundColor:
                          isDark ? Colors.white10 : Colors.grey.shade100,
                      side: BorderSide(
                        color: selected
                            ? primaryColor
                            : Colors.grey.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── Circular progress + tap button ────────────────────────
              GestureDetector(
                onTap: _increment,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _animatedProgress,
                        primaryColor: primaryColor,
                        trackColor: isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_counter',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isUrdu ? 'حد: ' : 'of ',
                                    style: TextStyle(
                                        fontSize: 14, color: textSecondary),
                                  ),
                                  GestureDetector(
                                    onTap: _setCustomTarget,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            primaryColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              primaryColor.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_target',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Icon(Icons.edit,
                                              size: 11,
                                              color: primaryColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                isUrdu ? 'گنتی کے لیے دائرے کو ٹیپ کریں' : 'Tap the circle to count',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 28),

              // ── Stat row ──────────────────────────────────────────────
              Row(
                children: [
                  _statCard(
                    isUrdu ? 'باقی' : 'Remaining',
                    '${_target - _counter}',
                    primaryColor.withOpacity(0.08),
                    primaryColor,
                    cardColor,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    isUrdu ? 'تکمیل' : 'Complete',
                    '${(_counter / _target * 100).toStringAsFixed(0)}%',
                    _counter == _target
                        ? Colors.green.withOpacity(0.12)
                        : primaryColor.withOpacity(0.08),
                    _counter == _target ? Colors.green : primaryColor,
                    cardColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Action buttons ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label:
                          Text(isUrdu ? 'ری سیٹ' : 'Reset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                            color: Colors.grey.withOpacity(0.4)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _increment,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                          isUrdu ? 'ایک بڑھائیں' : 'Add Count'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color bgColor,
      Color valueColor, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: valueColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }
}

/// Circular progress ring painter
class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -pi / 2,                // start from top
        2 * pi * progress,      // sweep
        false,
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.primaryColor != primaryColor;
}
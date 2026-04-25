import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';
import 'dart:math';

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  int _currentBead = 0; // 0 to 32
  int _completeSets = 0; // each full cycle of 33 beads
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Dhikr list for each bead (cycle repeats after 33)
  final List<Map<String, String>> _dhikrList = [
    {'arabic': 'سُبْحَانَ اللَّهِ', 'english': 'Glory be to Allah', 'urdu': 'اللہ پاک ہے'},
    {'arabic': 'الْحَمْدُ لِلَّهِ', 'english': 'Praise be to Allah', 'urdu': 'تمام تعریفیں اللہ کے لیے ہیں'},
    {'arabic': 'اللَّهُ أَكْبَرُ', 'english': 'Allah is the Greatest', 'urdu': 'اللہ سب سے بڑا ہے'},
  ];
  // cycle: 33 times (11 of each, simple loop)
  int get currentDhikrIndex => (_currentBead % 3);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_animationController);
  }

  void _moveBead() {
    setState(() {
      if (_currentBead < 32) {
        _currentBead++;
      } else {
        _currentBead = 0;
        _completeSets++;
      }
    });
    // trigger animation
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _reset() {
    setState(() {
      _currentBead = 0;
      _completeSets = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    final currentDhikr = _dhikrList[currentDhikrIndex];
    final dhikrText = currentDhikr['arabic']!;
    final translation = isUrdu ? currentDhikr['urdu']! : currentDhikr['english']!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'تسبیح' : 'Tasbeeh'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Digital counter display
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        isUrdu ? 'مجموعی گنتی' : 'Total Count',
                        style: TextStyle(fontSize: 16, color: textSecondary),
                      ),
                      Text(
                        '${(_completeSets * 33) + _currentBead}',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      Text(
                        isUrdu ? 'مکمل دور: $_completeSets' : 'Full Cycles: $_completeSets',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Tasbeeh visual - beads on a string
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Main bead (central controller)
                    GestureDetector(
                      onTap: _moveBead,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 3))
                                ],
                              ),
                              child: Center(
                                child: Icon(Icons.touch_app, color: Colors.white, size: 32),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      isUrdu ? 'تسبیح دانے کو چھوئیں' : 'Tap the bead to count',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                    SizedBox(height: 20),

                    // Bead row (string)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(33, (index) {
                          bool isActive = index <= _currentBead;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive ? primaryColor : Colors.grey[400],
                                    boxShadow: isActive ? [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 3)] : null,
                                  ),
                                ),
                                if (index == 10 || index == 21) // separator beads (optional)
                                  Container(
                                    width: 2,
                                    height: 6,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Dhikr display with translation
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        dhikrText,
                        style: TextStyle(fontSize: 32, fontFamily: 'serif', color: textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        translation,
                        style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        isUrdu ? 'یہ تسبیح ہر بار پڑھیں' : 'Recite this dhikr each time',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Reset button
              ElevatedButton.icon(
                onPressed: _reset,
                icon: Icon(Icons.refresh),
                label: Text(isUrdu ? 'دوبارہ شروع کریں' : 'Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
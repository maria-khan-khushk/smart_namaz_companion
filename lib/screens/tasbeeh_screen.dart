import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';
import 'guidance_screen.dart';

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _counter = 0;
  int _target = 33;
  bool _targetReachedShown = false;

  void _increment() {
    if (_counter < _target) {
      setState(() {
        _counter++;
        if (_counter == _target && !_targetReachedShown) {
          _targetReachedShown = true;
          _showTargetCompletion();
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _counter = 0;
      _targetReachedShown = false;
    });
  }

  void _setTarget() async {
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    final controller = TextEditingController(text: _target.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUrdu ? 'حد مقرر کریں' : 'Set Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: isUrdu ? 'مطلوبہ تعداد' : 'Enter count',
            border: OutlineInputBorder(),
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
                });
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
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isUrdu ? '🎉 مبارک ہو! آپ نے اپنی حد مکمل کر لی!' : '🎉 Congratulations! You have reached your target!',
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openGuidance() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GuidanceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    final progress = _counter / _target;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'تسبیح کاؤنٹر' : 'Tasbeeh Counter'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Text('🤲', style: TextStyle(fontSize: 24)), // 👐 dua hands emoji
            onPressed: _openGuidance,
            tooltip: isUrdu ? 'اذکار اور دعائیں' : 'Dhikr & Duas',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        isUrdu ? 'موجودہ گنتی' : 'Current Count',
                        style: TextStyle(fontSize: 18, color: textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$_counter',
                        style: TextStyle(fontSize: 96, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isUrdu ? 'حد: ' : 'Target: ',
                            style: TextStyle(fontSize: 18, color: textSecondary),
                          ),
                          GestureDetector(
                            onTap: _setTarget,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_target',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 16, color: primaryColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: primaryColor,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: Icon(Icons.refresh),
                    label: Text(isUrdu ? 'ری سیٹ' : 'Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _increment,
                    icon: Icon(Icons.add),
                    label: Text(isUrdu ? 'ایک بڑھائیں' : 'Add One'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isUrdu ? 'حد مقرر کرنے کے لیے "عدد" پر ٹیپ کریں' : 'Tap the target number to change limit',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
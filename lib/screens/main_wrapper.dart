import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'qibla_screen.dart';
import 'tasbeeh_screen.dart';
import 'reminders_screen.dart';

class MainWrapper extends StatefulWidget {
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Build screens lazily — only created when first visited
  final List<Widget> _screens = [
    HomeScreen(),
    QiblaScreen(),
    TasbeehScreen(),
    RemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    return Scaffold(
      // IndexedStack keeps all visited screens alive in the widget tree,
      // preventing expensive re-initialization when switching tabs.
      // Without this, every tab switch destroys the old screen and
      // rebuilds + refetches everything from scratch.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.access_time),
            label: isUrdu ? 'نماز' : 'Namaz',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.compass_calibration),
            label: isUrdu ? 'قبلہ' : 'Qibla',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.numbers),
            label: isUrdu ? 'تسبیح' : 'Tasbeeh',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.alarm),
            label: isUrdu ? 'یاد دہانی' : 'Reminders',
          ),
        ],
      ),
    );
  }
}
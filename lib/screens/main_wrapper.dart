import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'qibla_screen.dart';
import 'tasbeeh_screen.dart';
import 'settings_screen.dart';

class MainWrapper extends StatefulWidget {
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    QiblaScreen(),
    TasbeehScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBackground
            : Colors.white,
        selectedItemColor: AppColors.primaryMuted,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: isUrdu ? 'نماز' : 'Namaz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compass_calibration),
            label: isUrdu ? 'قبلہ' : 'Qibla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: isUrdu ? 'تسبیح' : 'Tasbeeh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: isUrdu ? 'سیٹنگز' : 'Settings',
          ),
        ],
      ),
    );
  }
}
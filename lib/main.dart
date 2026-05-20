import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/language_provider.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';


void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // NotificationService.initialize() already calls AndroidAlarmManager.initialize()
  await NotificationService.initialize();
  await NotificationService.createNotificationChannel();

  // Load saved theme mode (persisted across restarts)
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('themeMode');
  ThemeMode initialTheme = ThemeMode.system;
  if (saved == 'dark') initialTheme = ThemeMode.dark;
  else if (saved == 'light') initialTheme = ThemeMode.light;

  runApp(MyApp(initialTheme: initialTheme));
}

class MyApp extends StatelessWidget {
  final ThemeMode initialTheme;
  const MyApp({super.key, this.initialTheme = ThemeMode.system});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier(initialTheme)),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeNotifier, LanguageProvider>(
        builder: (context, themeNotifier, languageProvider, child) {
          return MaterialApp(
            title: 'Awwab',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier(ThemeMode initial) {
    _themeMode = initial;
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', 'system');
    notifyListeners();
  }
}
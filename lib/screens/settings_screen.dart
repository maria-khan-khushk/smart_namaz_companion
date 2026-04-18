import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // ThemeNotifier ke liye
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text("Dark Mode"),
            subtitle: Text("Switch between light and dark theme"),
            value: isDark,
            onChanged: (value) {
              themeNotifier.toggleTheme(value);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("About"),
            subtitle: Text("Smart Namaz Companion v1.0"),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class QiblaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Qibla Direction")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compass_calibration, size: 100, color: AppColors.primaryMuted),
            SizedBox(height: 20),
            Text("Coming Soon!", style: TextStyle(fontSize: 24)),
            Text("Qibla compass will be implemented next", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
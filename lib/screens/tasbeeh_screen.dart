import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TasbeehScreen extends StatefulWidget {
  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _counter = 0;
  int _goal = 33;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasbeeh Counter")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$_counter",
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text("Goal: $_goal", style: TextStyle(fontSize: 20)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _counter++;
                  if (_counter >= _goal) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("🎉 Goal achieved! Well done!")),
                    );
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMuted,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text("Tap", style: TextStyle(fontSize: 24)),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () => setState(() => _counter = 0), child: Text("Reset")),
                SizedBox(width: 20),
                TextButton(onPressed: () => setState(() => _goal = 33), child: Text("Set 33")),
                SizedBox(width: 20),
                TextButton(onPressed: () => setState(() => _goal = 99), child: Text("Set 99")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
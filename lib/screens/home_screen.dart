import 'package:flutter/material.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Namaz Companion'),
      ),
      body: Center(
        child: Text('Home Screen - Will show prayer times'),
      ),
    );
  }
}
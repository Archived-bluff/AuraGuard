import 'package:flutter/material.dart';
import 'screens/daily_review.dart';
import 'screens/suspicious_activity.dart';
import 'screens/user_account.dart';

void main() {
  runApp(DoorbellApp());
}

class DoorbellApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Doorbell Security',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doorbell Security Dashboard'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DashboardButton(
              label: "Daily Review",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DailyReviewPage()),
                );
              },
            ),
            DashboardButton(
              label: "Suspicious Activity Recordings",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SuspiciousActivityPage()),
                );
              },
            ),
            DashboardButton(
              label: "User Account",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  DashboardButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(250, 60),
          textStyle: TextStyle(fontSize: 18),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

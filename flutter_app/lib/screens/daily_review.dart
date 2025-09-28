import 'package:flutter/material.dart';

class DailyReviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daily Review")),
      body: Center(
        child: Text(
          "Daily Review Page\n(Swipe faces + suspicious clips here)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

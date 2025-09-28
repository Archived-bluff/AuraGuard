import 'package:flutter/material.dart';

class UserAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Account")),
      body: Center(
        child: Text(
          "User Account Page\n(Profiles, Settings, etc.)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

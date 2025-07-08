import 'dart:async';
import 'package:flutter/material.dart';

class SplashLogoPage extends StatefulWidget {
  @override
  _SplashLogoPageState createState() => _SplashLogoPageState();
}

class _SplashLogoPageState extends State<SplashLogoPage> {
  @override
  void initState() {
    super.initState();

    // 2 saniye sonra ana sayfaya geç
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashLogoPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka plan beyaz
      body: Center(
        child: Image.asset(
          'assets/logo.png', // 👈 Logonu assets klasörüne koymayı unutma
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
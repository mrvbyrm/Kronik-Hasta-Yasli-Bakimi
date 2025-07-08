import 'dart:async';
import 'package:flutter/material.dart';
import 'InfiniteHealthHomePage.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/FallDetectionService.dart';
import 'SignInPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/NotificationService.dart'; 
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Zaman dilimlerini initialize et
  tz.initializeTimeZones();
  
  // Notification servisini başlat
  await NotificationService.init();
  
  // Android 13+ için bildirim izni iste
  await requestNotificationPermission();
  await Permission.notification.request();

  
  runApp(MyApp());
}

Future<void> requestNotificationPermission() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    var result = await Permission.notification.request();
    if (result.isGranted) {
      print("🔔 Bildirim izni verildi.");
    } else {
      print("🚫 Bildirim izni reddedildi.");
    }
  } else {
    print("✅ Bildirim izni zaten verilmiş.");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashLogoPage(),
    );
  }
}

class SplashLogoPage extends StatefulWidget {
  @override
  _SplashLogoPageState createState() => _SplashLogoPageState();
}

class _SplashLogoPageState extends State<SplashLogoPage> {
  FallDetectionService? _fallDetectionService;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    Future.delayed(const Duration(seconds: 2), () async {
      await checkIfLoggedIn();
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      final result = await Permission.notification.request();

      if (result.isGranted) {
        print("🔔 Bildirim izni verildi.");
      } else {
        print("🚫 Bildirim izni reddedildi.");
      }
    } else {
      print("✅ Bildirim izni zaten verilmiş.");
    }
  }

  Future<void> checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final kullaniciId = prefs.getInt('kullaniciId');
    final email = prefs.getString('kullaniciEmail');

    if (kullaniciId != null && email != null) {
      // Giriş yapılmışsa ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InfiniteHealthHomePage(userId: kullaniciId, userName: email),
        ),
      );
    } else {
      // Giriş yapılmamışsa giriş sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    }
  }

  Future<void> onLoginSuccess(int kullaniciId, String kullaniciEmail) async {
    _fallDetectionService = FallDetectionService(
      kullaniciId: kullaniciId,
    );

    await initBackgroundMode();
    await _fallDetectionService!.start();
    await _fallDetectionService!.showForegroundNotification();
  }

  Future<void> initBackgroundMode() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Düşme Algılama",
      notificationText: "Arka planda düşme algılama aktif.",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      // İzinleri iste
      var activityResult = await Permission.activityRecognition.request();
      var locationResult = await Permission.locationAlways.request();

      if (!activityResult.isGranted || !locationResult.isGranted) {
        print("⚠️ Arka plan izinleri reddedildi.");
        // Burada kullanıcıyı bilgilendirebilir veya başka aksiyon alabilirsin
        return;
      }
    }

    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (success) {
      await FlutterBackground.enableBackgroundExecution();
    } else {
      print("⚠️ FlutterBackground initialize başarısız oldu.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
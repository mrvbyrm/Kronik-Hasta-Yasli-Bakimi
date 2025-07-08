import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FallDetectionService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  final int kullaniciId;
  

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'fall_detection_channel';
  static const String _channelName = 'Düşme Algılama';
  static const String _channelDescription = 'Düşme algılandığında gönderilen bildirimler';

  bool _isFallDetectedRecently = false;
  bool _isRotatedSharply = false;

  FallDetectionService({
    required this.kullaniciId,
  }) {
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == 'fall_detected') {
          print("👤 Kullanıcı yanıt verdi: İyiyim");
          await _sendFallToServer(
            DateTime.now(),
            "Kullanıcı 'İyiyim' yanıtı verdi.",
          );
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> start() async {
    // Gyroscope dinleyicisi
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      double rotation = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (rotation > 3.0) {
        _isRotatedSharply = true;
        print("🌀 Ani dönme tespit edildi! Rotation: $rotation");
      }
    });

    // Accelerometer dinleyicisi
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > 15 && _isRotatedSharply && !_isFallDetectedRecently) {
        print("🚨 DÜŞME ALGILANDI! Hız: $magnitude | Dönme: $_isRotatedSharply");
        _isFallDetectedRecently = true;
        _isRotatedSharply = false;

        _showFallDetectedNotification();

        Future.delayed(Duration(seconds: 3), () {
          _isFallDetectedRecently = false;
        });
      }
    });
  }

  Future<void> _showFallDetectedNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Düşme algılandı!',
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      '⚠️ Dikkat!',
      'Düşme algılandı. İyi misiniz?',
      platformChannelSpecifics,
      payload: 'fall_detected',
    );

    // Yanıt bekleme süresi: 10 saniye
    Timer(Duration(seconds: 10), () async {
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.getActiveNotifications();

      final stillActive = pendingNotifications.any((n) => n.id == 0);

      if (stillActive) {
        print("❌ Yanıt alınamadı. Sunucuya bildiriliyor.");
        await _sendFallToServer(
          DateTime.now(),
          "Yanıt alınamadı. Kullanıcı sessiz.",
        );
        await _flutterLocalNotificationsPlugin.cancel(0);
      }
    });
  }

  Future<void> showForegroundNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Arka planda düşme algılama servisi bildirimi',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      1,
      'Düşme Algılama Aktif',
      'Arka planda çalışıyor',
      platformDetails,
      payload: 'fall_detection_active',
    );
  }

  void stop() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
  }

  Future<void> _sendFallToServer(DateTime tarihSaat, String notlar) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {

      final url = Uri.parse("http://192.168.1.58:5000/api/Dusme/ekle");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "kullaniciId": kullaniciId,
          "tarihSaat": tarihSaat.toIso8601String(),
          "notlar": notlar,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Düşme bildirimi başarıyla gönderildi.");
      } else {
        print("❌ API hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Düşme bildirimi gönderilemedi: $e");
    }
  }
}

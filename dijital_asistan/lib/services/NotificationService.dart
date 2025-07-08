import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  final initSettings = InitializationSettings(android: androidSettings);
  await _flutterLocalNotificationsPlugin.initialize(initSettings);

  // 📢 BURAYA EKLE → Bildirim izni kontrolü
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // 🔔 Kanal oluştur
  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
    const AndroidNotificationChannel(
      'zamanli_kanal_id',
      'Zamanlı Bildirimler',
      description: 'Zamanlanmış randevu bildirimleri',
      importance: Importance.max,
    ),
  );
}

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'randevu_channel_id', 
      'Randevu Bildirimleri',
      channelDescription: 'Randevu ve anlık hatırlatma bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, 
      title,
      body,
      platformDetails,
    );
  }

  static Future<void> showRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required DateTimeComponents repeatType,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tekrarli_id',
          'Tekrarlı Bildirimler',
          channelDescription: 'Tekrarlayan hatırlatmalar',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: repeatType,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showScheduledNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
}) async {
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'zamanli_kanal_id',
        'Zamanlı Bildirimler',
        channelDescription: 'Zamanlanmış randevu bildirimleri',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );

  // ✅ Bildirim planlandı mı kontrol et
  final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  print("📋 Planlanan bildirim sayısı: ${pending.length}");
  for (var p in pending) {
    print("🔔 Bildirim ID: ${p.id}, Başlık: ${p.title}, İçerik: ${p.body}");
  }
}

  
}


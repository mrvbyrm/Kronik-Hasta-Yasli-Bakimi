import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DusmeAlgilamaPage extends StatefulWidget {
  @override
  _DusmeAlgilamaPageState createState() => _DusmeAlgilamaPageState();
}

class _DusmeAlgilamaPageState extends State<DusmeAlgilamaPage> {
  StreamSubscription? _accelerometerSubscription;
  bool _dusmeAlgilandi = false;
  Timer? _sayacTimer;
  String? _token;

  @override
  void initState() {
    super.initState();
    _tokenYukle().then((_) => _dinlemeyeBasla());
  }

  Future<void> _tokenYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString("token");
    });
  }

  void _dinlemeyeBasla() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double toplamIvme =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // ⚠️ Gürültüye karşı ikinci koşul eklendi: sayaç aktif mi
      if (!_dusmeAlgilandi &&
          (_sayacTimer == null || !_sayacTimer!.isActive) &&
          (toplamIvme < 2 || toplamIvme > 30)) {
        _dusmeAlgilandi = true;
        _dusmePopupGoster();
      }
    });
  }

  void _dusmePopupGoster() {
    int kalanSure = 30;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _sayacTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            kalanSure--;
          });

          if (kalanSure <= 0) {
            _sayacTimer?.cancel();
            Navigator.of(context).pop(); // Popup kapat
            _apiyeDusmeBildir();
          }
        });

        return AlertDialog(
          title: Text("Düşme Algılandı"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("İyi misiniz? $kalanSure saniye içinde yanıt verin."),
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sayacTimer?.cancel();
                _dusmeAlgilandi = false;
                Navigator.of(context).pop();
              },
              child: Text("Evet, İyiyim"),
            ),
          ],
        );
      },
    );
  }

  void _apiyeDusmeBildir() async {
    final now = DateTime.now().toIso8601String();

    if (_token == null) {
      print("Token bulunamadı!");
      return;
    }

    // ✅ DTO şeklinde JSON gönderimi düzeltildi
    final response = await http.post(
      Uri.parse('http://192.168.1.36:5000/api/Dusme/ekle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        "dto": {
          "tarihSaat": now,
          "notlar": "Mobil uygulama tarafından otomatik düşme bildirimi",
          "epostaGonderildiMi": false // İstersen burayı true yapabilirsin
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Düşme bildirildi ve e-posta gönderimi başlatıldı.");
    } else {
      print("API’ye düşme bildirimi başarısız: ${response.body}");
    }

    _dusmeAlgilandi = false;
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _sayacTimer?.cancel();
    _dusmeAlgilandi = false; // 🧹 Uygulama kapanırken sıfırla
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Düşme Algılama")),
      body: Center(
        child: Text("Sensör dinleniyor, düşme algılanırsa bildirim çıkacaktır."),
      ),
    );
  }
}

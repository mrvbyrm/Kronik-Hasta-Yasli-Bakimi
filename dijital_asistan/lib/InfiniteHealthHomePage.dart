import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:health/health.dart';
import 'AppointmentScreen.dart';
import 'DegerGiris.dart';
import 'TahlilSonuclari.dart';
import 'IlacTakipPage.dart';
import 'MakalePage.dart';
import 'UserProfileScreen.dart';
import 'BesinPage.dart';
import 'RutinlerPage.dart';
import 'services/WaterService.dart';
import 'AdimSayarPage.dart';
import 'DusmeAlgilamaPage.dart';
import 'services/FallDetectionService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SettingsScreen.dart';

class InfiniteHealthHomePage extends StatefulWidget {
  final String userName;
  final int userId;
  const InfiniteHealthHomePage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<InfiniteHealthHomePage> createState() => _InfiniteHealthHomePageState();
}

class _InfiniteHealthHomePageState extends State<InfiniteHealthHomePage> {
  double waterCount = 0;
  late StreamSubscription<StepCount> _stepCountStream;
  late FallDetectionService _fallService;
  int currentCardIndex = 0;
  int _steps = 0;
  final List<Map<String, dynamic>> kartlar = [
  {
    "aciklama": "Doğru ve dengeli beslenmek, sağlığın korunması için önemlidir.",
    "baslik": "Kendini Sev, Sağlıklı Beslen.",
    "progress": 0.9,
    "imagePath": "assets/healthyFood.png",
    "resimBoyut": 240.0,
    "renk": Color(0xFFBAC94A),
    "yaziRenk": Color(0xFF1D1D1D),
    "imageTop": 20.0, // 👈 bu yeni
  },
  {
    "aciklama": "Tansiyonunuzu düzenli ölçmek, kalp sağlığınızı korumanıza yardımcı olur.",
    "baslik": "Sağlıklı Tansiyon, Sağlıklı Yaşam",
    "progress": 0.9,
    "imagePath": "assets/tansiyonMakale.png",
    "resimBoyut": 240.0,
    "renk": Color.fromARGB(255, 222, 103, 103),
    "yaziRenk": Color.fromARGB(255, 240, 243, 240),
    "imageTop": 55.0, // 👈 bu resmi aşağı indirir
  },
  {
    "aciklama": "Yeterli su içmek, vücut fonksiyonları için kritik önem taşır.",
    "baslik": "Haydi Su İç!",
    "progress": 0.9,
    "imagePath": "assets/pourWaters.png",
    "resimBoyut": 260.0,
    "renk": Color.fromRGBO(95, 176, 227, 1),
    "yaziRenk": Color.fromARGB(255, 245, 246, 247),
    "imageTop": 10.0, // 👈 orta seviye
    "imageLeft":-10.0,
  },
];

Widget bilgiKarti(Map<String, dynamic> data) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 280,
            height: 230,
            padding: EdgeInsets.only(
  left: data['resimBoyut'] * 0.6,
  right: 12,
  top: 12,
  bottom: 12,
),
            decoration: BoxDecoration(
              color: data['renk'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['aciklama'],
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: data['progress'],
                  color: data['yaziRenk'],
                  backgroundColor: Colors.white,
                  minHeight: 3,
                ),
                const SizedBox(height: 10),
                Text(
                  data['baslik'],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: data['yaziRenk'],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
  left: data['imageLeft'] ?? 0.0, // ← Bunu güncelledik!
  top: data['imageTop'] ?? 40.0,
  child: Image.asset(
    data['imagePath'],
    width: data['resimBoyut'],
    height: data['resimBoyut'] * 0.95,
    fit: BoxFit.contain,
  ),
),

        // ← Sol ok
        if (currentCardIndex > 0)
          Positioned(
            left: 0,
            top: 90,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentCardIndex--;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black54),
              ),
            ),
          ),

        // → Sağ ok
        if (currentCardIndex < kartlar.length - 1)
          Positioned(
            right: 0,
            top: 90,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentCardIndex++;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black54),
              ),
            ),
          ),
      ],
    ),
  );
}
  @override
  void initState() {
    super.initState();
    _baslatDusmeAlgilama();
    requestPermissions();
    initPlatformState();
    fetchWaterData();
  }
  final WaterService _waterService = WaterService();

void fetchWaterData() async {
  try {
    final miktar = await _waterService.getDailyWaterIntake(DateTime.now());
    setState(() {
      waterCount = miktar;
    });
  } catch (e) {
    print("Su verisi hatası: $e");
  }
}
 void initPlatformState() {
  _stepCountStream = Pedometer.stepCountStream.listen(
    onStepCount,
    onError: onStepCountError,
    cancelOnError: true,
  );
}

      void onStepCount(StepCount event) {
        print('Yeni adım sayısı: ${event.steps}');
        setState(() {
          _steps = event.steps;
        });
      }

        void onStepCountError(error) {
          debugPrint('Adım sayar hatası: $error');
          setState(() {
            _steps = 0;
          });
        }

        @override
        void dispose() {
          _stepCountStream.cancel();
          super.dispose();
        }
        Future<void> requestPermissions() async {
          var status = await Permission.activityRecognition.request();
          if (status.isGranted) {
            print("İzin verildi.");
          } else {
            print("İzin reddedildi.");
          }
        }
          @override
            Widget build(BuildContext context) {
              print('InfiniteHealthHomePage userId: ${widget.userId}');

              return Scaffold(
                backgroundColor: const Color(0xFFF7FDFD),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // ÜST PROFİL ALANI
                      Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Color(0xFF94D9C6), width: 1),
                                ),
                              ),
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Color(0xFF59A7A7), width: 1),
                                ),
                              ),
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage('assets/profile.png'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                /// ŞİMDİ BURASI DÜZGÜN:
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Sol tarafta yazılar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hoş geldiniz!', style: TextStyle(fontSize: 16)),
                          Text(
                            widget.userName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      /// Sağda ayarlar ikonu
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.teal),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(), // SettingsScreen sınıfın tanımlı olmalı
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            const SizedBox(height: 10),
            Image.asset('assets/logo.png', width: 80),
            const Text(
              'INFINITE HEALTH',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5FB5B5),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 450,
              child: LinearProgressIndicator(
                value: 3.0,
                color: Color(0xFF5FB5B5),
                backgroundColor: Colors.white,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 80),
            // BESLENME BİLGİ KARTI
            bilgiKarti(kartlar[currentCardIndex]),

            const SizedBox(height: 32),
            // MAKALE BUTONU
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MakalePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Makaleyi Oku',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 320, // ← Genişlik burada belirleniyor
                child: Divider(
                  thickness: 2,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 32),
           // SU TAKİBİ VE ADIMSAYAR
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Column( // Row yerine Column
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // SU TAKİBİ
      Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_drink, size: 30, color: Color(0xFF9FC9E9)),
              const SizedBox(width: 8),
              const Text('SU TAKİBİ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xFF9FC9E9))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9FC9E9), Color(0xFF59A7A7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gün içinde ne kadar su içtiğini takip etmek sağlıklıdır.',
                    style: TextStyle(color: Colors.white)),
                const Text('Hatırlatıcı bildirimleri açmayı unutma!',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Text('Toplam: ${waterCount.toStringAsFixed(2)} Litre',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                     const SizedBox(height: 14),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ElevatedButton(
      onPressed: () async {
        setState(() {
          waterCount += 0.25;
        });

        try {
          await _waterService.addWaterIntake(0.25, DateTime.now());
        } catch (e) {
          print("Ekleme hatası: $e");
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text('+0.25 Litre Ekle'),
    ),
    const SizedBox(width: 12), // Butonlar arası boşluk
    ElevatedButton(
      onPressed: () async {
        if (waterCount >= 0.25) {
          setState(() {
            waterCount -= 0.25;
          });

          try {
            await _waterService.addWaterIntake(-0.25, DateTime.now());
          } catch (e) {
            print("Silme hatası: $e");
          }
        } else {
          print("Su miktarı zaten 0, daha fazla silinemez.");
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text('-0.25 Litre Sil'),
    ),
  ],
),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24), // Su Takibi ile Adımsayar arası boşluk

      // ADIMSAYAR
      Column(
        children: [
          const Text(
            'ADIMSAYAR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFFE2D46B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE2D46B), Color(0xFF59A7A7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bugün', style: TextStyle(color: Colors.white)),
                Text('$_steps',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Text('adım attınız.', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: (_steps / 8000).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white30,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdimSayarPage()),
                    );
                  },
                  child: const Text("Adımsayarı Görüntüle"),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),

            const SizedBox(height: 32),
            Center(
            child: SizedBox(
              width: 320, // ← Genişlik burada belirleniyor
              child: Divider(
                thickness: 2,
                color: Colors.teal,
              ),
            ),
          ),
            const SizedBox(height: 32),
            // MENÜ BUTONLARI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _menuButton('İLAÇ TAKİP', Icons.medical_services, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IlacTakipPage(userId: widget.userId)),
                    );
                  }),
                  _menuButton('DEĞER GİRİŞ', Icons.bar_chart, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DegerGiris()),
                    );
                  }),
                  _menuButton('TAHLİL SONUÇLARI', Icons.list_alt, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TahlilSonuclari()),
                    );
                  }),
                  _menuButton('RANDEVU', Icons.calendar_month, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AppointmentScreen(userId: widget.userId)),
                    );
                  }),
                _menuButton('HAFTALIK RUTİNLER', Icons.repeat, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RutinlerPage(userId: widget.userId)), // Burayı kendi sayfana göre ayarla
                  );
                }),
                _menuButton('BESİN', Icons.bar_chart, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BesinPage(userId: widget.userId)),
                  );
                }),
              ],
            ),
          ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
Future<void> _baslatDusmeAlgilama() async {
  final prefs = await SharedPreferences.getInstance();
  final kullaniciId = prefs.getInt('kullaniciId');
  final email = prefs.getString('kullaniciEmail');

  if (kullaniciId != null && email != null) {
    _fallService = FallDetectionService(
      kullaniciId: kullaniciId,
    );
    await _fallService!.start();
    await _fallService!.showForegroundNotification(); // arka plan bildirimi
  }
}
  Widget _menuButton(String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
    width: 300,
    height: 70, // Sabit genişlik (gerekirse artır veya azalt)
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF5FB5B5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      icon: Icon(icon, size: 28),
      label: Text(title, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
    ),
  );
}  
}
import 'package:flutter/material.dart';
import 'TansiyonGirisEkrani.dart';
import 'SekerGirisEkrani.dart';
import 'KanDegerleriGirisEkrani.dart'; 
import 'HeartRatePage.dart';

class DegerGiris extends StatelessWidget {
  const DegerGiris({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor:Color(0xFF94D9C6),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    "assets/logo.png",
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "DEĞER GİRİŞ",
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                hintText: "Ara...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  healthButton(
                    context,
                    "KAN DEĞERLERİ",
                    Colors.red[300],
                    Icons.bloodtype,
                    KanDegerleriGirisEkrani(),
                  ),
                  healthButton(
                    context,
                    "KALP DEĞERLERİ",
                    Colors.pink[300],
                    Icons.favorite,
                    HeartRatePage(),
                  ),
                  healthButton(
                    context,
                    "ŞEKER DEĞERLERİ",
                    Colors.lightGreen[400],
                    Icons.medical_services,
                    SekerGirisEkrani(),
                  ),
                  healthButton(
                    context,
                    "TANSİYON DEĞERLERİ",
                    Colors.yellow[600],
                    Icons.monitor_heart,
                    TansiyonGirisEkrani(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget healthButton(BuildContext context, String text, Color? color, IconData icon, Widget? page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        ),
        onPressed: () {
          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$text sayfası henüz eklenmedi.')),
            );
          }
        },
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 50),
            SizedBox(width: 30),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/AdimsayarService.dart';

class AdimSayarPage extends StatefulWidget {
  const AdimSayarPage({Key? key}) : super(key: key);

  @override
  State<AdimSayarPage> createState() => _AdimSayarPageState();
}

class _AdimSayarPageState extends State<AdimSayarPage> {
  int _steps = 0;
  late Stream<StepCount> _stepCountStream;
  final AdimsayarService _service = AdimsayarService();
  Map<String, int> weeklySteps = {}; // String formatında tarih - adım sayısı
  final int hedef = 8000;

  @override
  void initState() {
    super.initState();
    initPedometer();
    kontrolVeVeriGonder();
    haftalikAdimGetir();
  }

  void initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
    });
  }

  void onStepCountError(error) {
    setState(() {
      _steps = 0;
    });
  }

  Future<void> kontrolVeVeriGonder() async {
    final prefs = await SharedPreferences.getInstance();
    final bugun = DateTime.now();
    final bugunKey =
        "${bugun.year}-${bugun.month}-${bugun.day}-adim-gonderildi";
    final gonderildiMi = prefs.getBool(bugunKey) ?? false;

    if (!gonderildiMi) {
      try {
        final mevcutAdim = await _service.bugunkuAdimGetir();
        if (mevcutAdim == 0 && _steps > 0) {
          await _service.adimEkle(_steps, bugun);
          await prefs.setBool(bugunKey, true);
        }
      } catch (e) {
        debugPrint("Veri gönderilirken hata: $e");
      }
    }
  }

  Future<void> haftalikAdimGetir() async {
    final data = await _service.adimlariGetirSon7Gun(); // Map<DateTime, int>

    Map<String, int> stringKeyMap = {};

    data.forEach((key, value) {
      String keyStr = "${key.year}-${key.month}-${key.day}";
      stringKeyMap[keyStr] = value;
    });

    setState(() {
      weeklySteps = stringKeyMap;
    });
  }

  double hesaplaDakika(int steps) {
    return steps / 100;
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_steps / hedef).clamp(0.0, 1.0);
    double dakika = hesaplaDakika(_steps);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF94D9C6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset("assets/logo.png", height: 80),
              const SizedBox(height: 10),
              const Text(
                "ADIMSAYAR",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
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

              // 🔵 Daire Grafik
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFE2D46B)),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "$_steps",
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const Text("adım"),
                      const SizedBox(height: 4),
                      Text(
                        "${dakika.toStringAsFixed(1)} dakika",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              progress >= 1.0
                  ? const Text(
                      "🎉 Hedefe ulaştınız!",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  : Text(
                      "Hedef: $hedef adım",
                      style: const TextStyle(color: Colors.black87),
                    ),
              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "📊 Son 7 Gün",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // 🔷 BAR CHART
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        //tooltipBgColorOverride: Colors.teal.withOpacity(0.85),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final tarih = DateTime.now()
                              .subtract(Duration(days: 6 - group.x));
                          final adim = rod.toY.toInt();
                          return BarTooltipItem(
                            "${tarih.day}.${tarih.month}: $adim adım",
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            List<String> days = ["P", "S", "Ç", "P", "C", "C", "T"];
                            return Text(days[value.toInt() % 7]);
                          },
                          interval: 1,
                        ),
                      ),
                    ),
                    barGroups: List.generate(7, (i) {
                      final tarih =
                          DateTime.now().subtract(Duration(days: 6 - i));
                      final key = "${tarih.year}-${tarih.month}-${tarih.day}";
                      final step = weeklySteps[key] ?? 0;

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: step.toDouble(),
                            color: step >= hedef
                                ? Colors.green
                                : Colors.blueAccent,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
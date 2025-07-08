import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/kalp_degerleri_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeartRatePage extends StatefulWidget {
  @override
  _HeartRatePageState createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isDetecting = false;
  List<double> redAvgList = [];
  double? finalBPM;
  double? currentBPM;
  bool isMeasuring = false;
  bool showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  
  final KalpService kalpService = KalpService();

  List<FlSpot> bpmSpots = [];
  Future<List<Map<String, dynamic>>> kalpVerileriniGetir(String token) async {
  // örnek kullanım
  return await kalpService.kalpVerileriniGetir(token);
}

  int timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);

      if (_controller != null) {
        try {
          if (_controller!.value.isStreamingImages) {
            await _controller!.stopImageStream();
          }
          await _controller!.dispose();
        } catch (_) {}
      }

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      try {
        await _controller!.setFlashMode(FlashMode.torch);
      } catch (e) {
        print("Flash modu ayarlanamadı veya desteklenmiyor: $e");
      }

      await Future.delayed(Duration(milliseconds: 300));

      _controller!.startImageStream((CameraImage image) {
        if (!isMeasuring || _isDetecting) return;
        _isDetecting = true;

        double avgRed = _calculateRedAverage(image);
        redAvgList.add(avgRed);
        if (redAvgList.length > 100) redAvgList.removeAt(0);

        _calculateCurrentBPM();

        if (currentBPM != null) {
          timeCounter++;
          bpmSpots.add(FlSpot(timeCounter.toDouble(), currentBPM!));
          if (bpmSpots.length > 50) bpmSpots.removeAt(0);
        }

        setState(() {});
        _isDetecting = false;
      });

      setState(() {});
    } catch (e) {
      print("Kamera başlatılamadı: $e");
    }
  }

  double _calculateRedAverage(CameraImage image) {
    final bytes = image.planes[0].bytes;
    int sum = 0;
    for (int i = 0; i < bytes.length; i += 10) {
      sum += bytes[i];
    }
    return sum / (bytes.length / 10);
  }

  void _calculateCurrentBPM() {
    if (redAvgList.length < 30) {
      currentBPM = null;
      return;
    }

    double avg = redAvgList.reduce((a, b) => a + b) / redAvgList.length;
    int peaks = 0;
    for (int i = 1; i < redAvgList.length - 1; i++) {
      if (redAvgList[i] > redAvgList[i - 1] &&
          redAvgList[i] > redAvgList[i + 1] &&
          redAvgList[i] > avg) {
        peaks++;
      }
    }

    currentBPM = (peaks * 60 / 15);
  }

  void _startMeasurement() async {
    redAvgList.clear();
    bpmSpots.clear();
    timeCounter = 0;
    finalBPM = null;
    currentBPM = null;

    setState(() {
      isMeasuring = true;
      showHeart = true;
    });

    await _initCamera();

    Timer(Duration(seconds:15), () async {
      setState(() {
        isMeasuring = false;
        showHeart = false;
      });

      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      if (_controller != null) {
        try {
          await _controller!.setFlashMode(FlashMode.off);
          await _controller!.dispose();
        } catch (_) {}
      }

      _controller = null;

      if (redAvgList.length < 30) {
        setState(() {
          finalBPM = null;
        });
        return;
      }

      double avg = redAvgList.reduce((a, b) => a + b) / redAvgList.length;
      int peaks = 0;
      for (int i = 1; i < redAvgList.length - 1; i++) {
        if (redAvgList[i] > redAvgList[i - 1] &&
            redAvgList[i] > redAvgList[i + 1] &&
            redAvgList[i] > avg) {
          peaks++;
        }
      }

      final bpm = (peaks * 60 / 15);
      setState(() {
        finalBPM = bpm;
      });

      // API'ye kaydet
      if (finalBPM != null) {
        await _kaydetKalpVerisi(finalBPM!);
      }
    });
  }

  Future<void> _kaydetKalpVerisi(double bpm) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Map<String, dynamic> degerListesi = {
      "nabiz": bpm.toInt(),
      "oksijen": 97.0,
      "ritim": "normal"
    };

    bool sonuc = await kalpService.kalpVerisiEkle(
      degerTipiId: 4,
      degerListesi: degerListesi,
      tahlilSonuclari: '{"sonuc":"Kalp atış hızı ölçüldü"}',
      token: token!,
    );

    if (sonuc) {
      print("Kalp verisi API'ye başarıyla gönderildi");
    } else {
      print("Kalp verisi API'ye gönderilirken hata oluştu");
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.dispose();
    }
    super.dispose();
  }

  String _bpmComment(double bpm) {
    if (bpm < 60) return "Düşük kalp atış hızı";
    if (bpm <= 100) return "Normal kalp atış hızı";
    return "Yüksek kalp atış hızı";
  }

  Widget _buildChart() {
  if (isMeasuring) {
    // Ölçüm sırasında çizgi grafik göster
    if (bpmSpots.isEmpty) {
      return Center(
        child: Text("Ölçüm sırasında grafik görüntülenecek"),
      );
    }
    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 160,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 20),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 20),
        lineBarsData: [
          LineChartBarData(
            spots: bpmSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  } else if (finalBPM != null) {
    // Ölçüm tamamlandıktan sonra çubuk grafik göster
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: 160,
        minY: 40,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 20, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('Kalp Hızı');
                return Container();
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: finalBPM!,
                color: Colors.red,
                width: 40,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
        gridData: FlGridData(show: true, horizontalInterval: 20),
      ),
    );
  } else {
    return Center(
      child: Text("Grafik görüntülenecek veri yok"),
    );
  }
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade100,
    appBar: AppBar(
      title: Text("Kalp Atış Hızı Ölçümü"),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isMeasuring && (_controller?.value.isInitialized ?? false))
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CameraPreview(_controller!),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                "Ölçüm için butona basın",
                style: TextStyle(color: Colors.grey.shade800, fontSize: 20),
              ),
            ),
          ),

        if (showHeart)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ScaleTransition(
              scale: _heartAnimation,
              child: Icon(Icons.favorite, color: Colors.red, size: 80),
            ),
          ),

        if (isMeasuring && currentBPM != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "${currentBPM!.toStringAsFixed(0)} BPM",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
          ),

        if (!isMeasuring && finalBPM != null)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(Icons.favorite, size: 80, color: Colors.red),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "${finalBPM!.toStringAsFixed(0)} BPM",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _bpmComment(finalBPM!),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _startMeasurement,
                icon: Icon(Icons.replay, color: Colors.white),
                label: Text("Yeniden Ölç", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),

        if (!isMeasuring && finalBPM == null)
          ElevatedButton.icon(
            onPressed: _startMeasurement,
            icon: Icon(Icons.favorite, color: Colors.white),
            label: Text("Ölçüme Başla", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

        SizedBox(height: 40),

        // **Grafik en sonda olacak şekilde buraya ekledim**
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildChart(),
          ),
        ),
      ],
    ),
  );
}
}

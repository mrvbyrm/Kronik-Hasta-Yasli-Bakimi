import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/tansiyon_service.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class TansiyonGirisEkrani extends StatefulWidget {
  const TansiyonGirisEkrani({super.key});

  @override
  State<TansiyonGirisEkrani> createState() => _TansiyonGirisEkraniState();
}

class _TansiyonGirisEkraniState extends State<TansiyonGirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _sistolikController = TextEditingController();
  final _diyastolikController = TextEditingController();
  final _nabizController = TextEditingController();

  final TansiyonService _service = TansiyonService();
  List<Map<String, dynamic>> _tansiyonVerileri = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final List<Map<String, dynamic>> veriler =
          await _service.tansiyonVerileriniGetir(token);
      final now = DateTime.now();
      final yediGunOnce = now.subtract(const Duration(days: 7));

      final filtreli = veriler.where((veri) {
        final tarih = DateTime.parse(veri['tarih']);
        return tarih.isAfter(yediGunOnce);
      }).map((veri) {
        return {
          'tarih': veri['tarih'],
          'sistolik': veri['sistolik'],
          'diyastolik': veri['diyastolik'],
          'nabiz': veri['nabiz'],
          'tahlilSonuclari': _cozSonucu(veri['tahlilSonuclari']),
        };
      }).toList();

      filtreli.sort((a, b) =>
          DateTime.parse(b['tarih']).compareTo(DateTime.parse(a['tarih'])));

      setState(() {
        _tansiyonVerileri = filtreli;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Veri hatası: $e")));
    }
  }

 Future<void> tansiyonVerisiniGonder() async {
  if (!_formKey.currentState!.validate()) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oturum doğrulanamadı. Lütfen giriş yapın.')),
    );
    return;
  }

  try {
    final sistolik = int.parse(_sistolikController.text);
    final diyastolik = int.parse(_diyastolikController.text);
    final nabiz = int.parse(_nabizController.text);

    final basariliMi = await _service.tansiyonVerisiEkle(
      degerTipiId: 1,
      degerListesi: {
        'sistolik': sistolik,
        'diyastolik': diyastolik,
        'nabiz': nabiz,
      },
      tahlilSonuclari: _yorumlaTansiyon(sistolik, diyastolik),
      token: token,
    );

    if (basariliMi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veri başarıyla kaydedildi!')),
      );
      _formKey.currentState?.reset();
      _sistolikController.clear();
      _diyastolikController.clear();
      _nabizController.clear();
      await _verileriYukle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veri kaydedilemedi! (Sunucu reddetti)')),
      );
    }
  } catch (e) {
    print("Hata oluştu: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veri kaydedilemedi! (İstisna oluştu)')),
    );
  }
}
  String _yorumlaTansiyon(int s, int d) {
    if (s < 90 || d < 60) return "Düşük tansiyon. Dikkatli olun.";
    if (s > 130 || d > 90) return "Yüksek tansiyon. Takipte kalın.";
    return "Tansiyon normal. Tebrikler!";
  }

  dynamic _cozSonucu(dynamic veri) {
    if (veri == null) return null;
    try {
      final decoded = jsonDecode(veri);
      if (decoded is Map<String, dynamic>) {
        return decoded.values.join(", ");
      }
      return veri.toString();
    } catch (e) {
      return veri.toString();
    }
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.grey.shade100,
          filled: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Bu alan boş bırakılamaz.";
          final val = int.tryParse(value.trim());
          if (val == null) return "Sadece tam sayı giriniz.";
          if (val <= 0) return "0'dan büyük bir değer giriniz.";
          return null;
        },

      ),
    );
  }

  Widget _buildTansiyonTablosu() {
    if (_tansiyonVerileri.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(
            child: Text("Kayıtlı veri yok.",
                style: TextStyle(color: Colors.grey))),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith(
            (_) => const Color(0xFF00BFAE).withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text("Tarih")),
          DataColumn(label: Text("Sistolik")),
          DataColumn(label: Text("Diyastolik")),
          DataColumn(label: Text("Nabız")),
          DataColumn(label: Text("Yorum")),
        ],
        rows: _tansiyonVerileri.map((v) {
          final t = DateTime.parse(v['tarih']);
          return DataRow(cells: [
            DataCell(Text(
                "${t.day}/${t.month}/${t.year} ${t.hour}:${t.minute.toString().padLeft(2, '0')}")),
            DataCell(Text(v['sistolik'].toString())),
            DataCell(Text(v['diyastolik'].toString())),
            DataCell(Text(v['nabiz'].toString())),
            DataCell(Text(v['tahlilSonuclari'] ?? "")),
          ]);
        }).toList(),
      ),
    );
  }

Widget _buildTansiyonGrafikleri() {
  if (_tansiyonVerileri.length < 2) return const SizedBox();

  List<FlSpot> sistolikSpots = [];
  List<FlSpot> diyastolikSpots = [];

  for (int i = 0; i < _tansiyonVerileri.length; i++) {
    final v = _tansiyonVerileri[i];
    final double x = i.toDouble();
    sistolikSpots.add(FlSpot(x, v['sistolik'].toDouble()));
    diyastolikSpots.add(FlSpot(x, v['diyastolik'].toDouble()));
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
    child: Card(
      elevation: 6,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: const Color(0xFFF8FBFC),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Tansiyon Değeri Grafikleri",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00897B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 40,
                  maxY: 200,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < _tansiyonVerileri.length) {
                            final tarih = DateTime.parse(_tansiyonVerileri[index]['tarih']);
                            return Text(
                              '${tarih.day}.${tarih.month}',
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black26),
                      bottom: BorderSide(color: Colors.black26),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                  ),
                  lineBarsData: [
                    // Sistolik
                    LineChartBarData(
                      spots: sistolikSpots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xff4fc3f7), Color(0xff0288d1)],
                      ),
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xff4fc3f7).withOpacity(0.3),
                            const Color(0xff0288d1).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 2,
                            color: Colors.blue,
                            strokeWidth: 0,
                          );
                        },
                      ),
                    ),
                    // Diyastolik
                    LineChartBarData(
                      spots: diyastolikSpots,
                      isCurved: false,
                      gradient: const LinearGradient(
                        colors: [Color(0xffff8a65), Color(0xffd84315)],
                      ),
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xffff8a65).withOpacity(0.3),
                            const Color(0xffd84315).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.deepOrange,
                            strokeWidth: 0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: Colors.blue, size: 10),
                SizedBox(width: 5),
                Text("Sistolik", style: TextStyle(fontSize: 12)),
                SizedBox(width: 15),
                Icon(Icons.circle, color: Colors.deepOrange, size: 10),
                SizedBox(width: 5),
                Text("Diyastolik", style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.yellow[600],
      elevation: 0,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // ↓↓↓ LOGO VE BAŞLIK
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/logo.png",
                          height: 80,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "TANSİYON TAKİBİ",
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

                  // ↓↓↓ ARAMA KUTUSU
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

                  // ↓↓↓ TANSİYON FORMU
                  _buildInput("Büyük tansiyon", _sistolikController),
                  _buildInput("Küçük tansiyon", _diyastolikController),
                  _buildInput("Nabız", _nabizController),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: tansiyonVerisiniGonder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Verileri Gönder",
                        style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                      " Kayıtlı Veriler",
                        style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: Colors.amber)),
                        Center(
                          child: SizedBox(
                            width: 320, // ← Genişlik burada belirleniyor
                            child: Divider(
                              thickness: 2,
                              color: Colors.yellow[600],
                            ),
                          ),
                        ),
                  // ↓↓↓ GRAFİK VE TABLO
                  _buildTansiyonGrafikleri(),
                  const SizedBox(height: 20),
                  _buildTansiyonTablosu(),
            
                ],
              ),
            ),
          ),
  );
}

}
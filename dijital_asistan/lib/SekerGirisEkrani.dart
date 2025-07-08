import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'services/seker_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SekerGirisEkrani extends StatefulWidget {
  const SekerGirisEkrani({super.key});

  @override
  State<SekerGirisEkrani> createState() => _SekerGirisEkraniState();
}

class _SekerGirisEkraniState extends State<SekerGirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _glukozController = TextEditingController();
  final _olcumZamaniController = TextEditingController();
  String? _toklukDurumu;

  final SekerService _service = SekerService();

  List<Map<String, dynamic>> _sekerVerileri = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _glukozController.dispose();
    _olcumZamaniController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final List<Map<String, dynamic>> veriler = await _service.sekerVerileriniGetir(token);
      final now = DateTime.now();
      final yediGunOnce = now.subtract(const Duration(days: 7));

      final filtreli = veriler.where((v) {
        if (v['tarih'] == null) return false;
        final tarih = DateTime.tryParse(v['tarih']);
        return tarih != null && tarih.isAfter(yediGunOnce);
      }).map((v) {
        return {
          'tarih': v['tarih'],
          'glukoz': v['glukoz'],
          'yorum': _cozYorum(v['tahlilSonuclari']),
        };
      }).toList();

      filtreli.sort((a, b) => DateTime.parse(b['tarih']).compareTo(DateTime.parse(a['tarih'])));

      setState(() {
        _sekerVerileri = filtreli;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veri hatası: $e")));
    }
  }

  Future<void> _veriGonder() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final int? glukoz = int.tryParse(_glukozController.text);
if (glukoz == null || glukoz < 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Geçerli ve pozitif bir glukoz değeri giriniz.")),
  );
  return;
}

      final yorum = _yorumlaSeker(glukoz);

      final basariliMi = await _service.sekerVerisiEkle(
        degerTipiId: 2,
        degerListesi: {'glukoz': glukoz},
        tahlilSonuclari: jsonEncode({'yorum': yorum}),
        olcumZamani: _olcumZamaniController.text,
        toklukDurumu: _toklukDurumu,
        token: token,
      );

      if (basariliMi) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veri kaydedildi")));
        _formKey.currentState!.reset();
        _glukozController.clear();
        _olcumZamaniController.clear();
        setState(() => _toklukDurumu = null);
        await _verileriYukle();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedilemedi")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    }
  }

  String _yorumlaSeker(int glukoz) {
    if (glukoz < 70) return "Hipoglisemi (düşük şeker)";
    if (glukoz > 140) return "Hiperglisemi (yüksek şeker)";
    return "Normal";
  }

  String _cozYorum(dynamic veri) {
    try {
      final decoded = jsonDecode(veri);
      if (decoded is Map) {
        return decoded['yorum'] ?? decoded.values.join(", ");
      }
      return decoded.toString();
    } catch (_) {
      return veri.toString();
    }
  }

  Widget _buildInput() {
    return TextFormField(
      controller: _glukozController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Glukoz (mg/dL)',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
  if (value == null || value.isEmpty) return "Boş geçilemez";
  final val = double.tryParse(value);
  if (val == null || val < 0) return "Geçerli ve pozitif bir değer girin";
  return null;
},

    );
  }

  Widget _buildOlcumZamaniDropdown() {
  final zamanlar = ["Sabah", "Öğle", "Öğleden Sonra", "Akşam", "Gece"];
  return DropdownButtonFormField<String>(
    value: _olcumZamaniController.text.isEmpty ? null : _olcumZamaniController.text,
    items: zamanlar
        .map((zaman) => DropdownMenuItem(value: zaman, child: Text(zaman)))
        .toList(),
    onChanged: (value) {
      setState(() {
        _olcumZamaniController.text = value ?? '';
      });
    },
    decoration: const InputDecoration(
      labelText: "Ölçüm Zamanı",
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return "Boş geçilemez";
      return null;
    },
  );
}


  Widget _buildToklukDurumuDropdown() {
    return DropdownButtonFormField<String>(
      value: _toklukDurumu,
      items: const [
        DropdownMenuItem(value: "Aç", child: Text("Aç")),
        DropdownMenuItem(value: "Tok", child: Text("Tok")),
      ],
      decoration: const InputDecoration(
        labelText: "Tokluk Durumu",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() => _toklukDurumu = value),
      validator: (value) {
        if (value == null || value.isEmpty) return "Boş geçilemez";
        return null;
      },
    );
  }
Widget _buildOlcumGecmisiKart() {
  return Card(
    color: Colors.grey[50],
    elevation: 8, // Gölge ekleyerek derinlik hissi veriyoruz
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16), // Kenarları yuvarlatıyoruz
    ),
    margin: const EdgeInsets.symmetric(vertical: 12), // Kartlar arasındaki boşluk
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _buildTablo(), // Tabloyu burada yerleştiriyoruz
        ],
      ),
    ),
  );
}
  Widget _buildTablo() {
  if (_sekerVerileri.isEmpty) return const Text("Veri bulunamadı.");

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(columns: const [
      DataColumn(label: Text("Tarih", style: TextStyle(fontWeight: FontWeight.w600))),
      DataColumn(label: Text("Glukoz", style: TextStyle(fontWeight: FontWeight.w600))),
      DataColumn(label: Text("Yorum", style: TextStyle(fontWeight: FontWeight.w600))),
    ], rows: _sekerVerileri.map((v) {
      final t = DateTime.parse(v['tarih']);
      return DataRow(cells: [
        DataCell(Text("${t.day}/${t.month} ${t.hour}:${t.minute.toString().padLeft(2, '0')}")),
        DataCell(Text(v['glukoz'].toString())),
        DataCell(Text(v['yorum'])),
      ]);
    }).toList()),
  );
}

  Widget _buildGrafik() {
    if (_sekerVerileri.length < 2) return const SizedBox();

    List<FlSpot> glukozSpots = [];
    for (int i = 0; i < _sekerVerileri.length; i++) {
      glukozSpots.add(FlSpot(i.toDouble(), _sekerVerileri[i]['glukoz'].toDouble()));
    }

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: 50,
          maxY: 250,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _sekerVerileri.length) return const SizedBox.shrink();
                  final tarih = DateTime.parse(_sekerVerileri[index]['tarih']);
                  return Text("${tarih.day}/${tarih.month}");
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: glukozSpots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
            )
          ],
        ),
      ),
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.lightGreen[400],
      elevation: 0,
    ),
    body: Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ↓↓↓ LOGO VE BAŞLIK ALANI
            Center(
              child: Column(
                children: [
                  Image.asset(
                    "assets/logo.png",
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "ŞEKER DEĞERLERİ",
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

            // ↓↓↓ GLUKOZ GİRİŞİ FORMU
            Card(
              color: Colors.grey[50],
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Text("Glukoz Girişi", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreen[700])),
                      const SizedBox(height: 12),
                      _buildInput(),
                      const SizedBox(height: 12),
                      _buildOlcumZamaniDropdown(),
                      const SizedBox(height: 12),
                      _buildToklukDurumuDropdown(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen[400],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _veriGonder,
                          child: const Text(
                            "Kaydet",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
           
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                " Son 7 Günlük Glukoz Grafiği",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreen[700]),
              ),
               Center(
              child: SizedBox(
                width: 320, // ← Genişlik burada belirleniyor
                child: Divider(
                  thickness: 2,
                  color: Colors.lightGreen[400],
                ),
              ),
            ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildGrafik(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
            " Ölçüm Geçmişi",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.lightGreen[700], // Başlık rengi
            ),
          ),
               Center(
              child: SizedBox(
                width: 320, // ← Genişlik burada belirleniyor
                child: Divider(
                  thickness: 2,
                  color: Colors.lightGreen[400],
                ),
              ),
            ),
              _buildOlcumGecmisiKart(),
            ],
          ],
        ),
      ),
    ),
  );
}
}
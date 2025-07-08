import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/kan_degerleri_service.dart';
import 'package:intl/intl.dart';

class KanDegerleriGirisEkrani extends StatefulWidget {
  const KanDegerleriGirisEkrani({super.key});

  @override
  State<KanDegerleriGirisEkrani> createState() => _KanDegerleriGirisEkraniState();
}

class _KanDegerleriGirisEkraniState extends State<KanDegerleriGirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _degerListesiController = TextEditingController();
  final _tahlilSonuclariController = TextEditingController();
  final _olcumZamaniController = TextEditingController();
  DateTime? _olcumZamani;

  final KanDegerleriService _service = KanDegerleriService();
  List<Map<String, dynamic>> _notlar = [];

  @override
  void initState() {
    super.initState();
    _notlariYukle();
  }

  Future<void> _notlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final notlar = await _service.kanVerileriniGetir(token);
      setState(() {
        _notlar = notlar;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Veriler yüklenemedi: $e")));
    }
  }

  @override
  void dispose() {
    _degerListesiController.dispose();
    _tahlilSonuclariController.dispose();
    _olcumZamaniController.dispose();
    super.dispose();
  }

  Future<void> _veriGonder() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || _olcumZamani == null) return;

    try {
      final degerListesi = {
        "kanDegeri": int.tryParse(_degerListesiController.text) ?? 0
      };
      final tahlilSonuclari = _tahlilSonuclariController.text;

      final basariliMi = await _service.kanDegeriEkle(
        degerListesi: degerListesi,
        tahlilSonuclari: tahlilSonuclari,
        olcumZamani: DateFormat('yyyy-MM-dd HH:mm').format(_olcumZamani!),
        tarih: _olcumZamani!,
        token: token,
      );

      if (basariliMi) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veri kaydedildi")));
  await _notlariYukle(); // ← Burada listeyi yeniden çekiyoruz
  _formKey.currentState!.reset();
  _degerListesiController.clear();
  _tahlilSonuclariController.clear();
  _olcumZamaniController.clear();
  _olcumZamani = null;
} else {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedilemedi")));
}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    }
  }

  Future<void> _veriSil(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final silmeBasariliMi = await _service.kanDegeriSil(id, token);

      if (silmeBasariliMi) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veri silindi")));
        setState(() {
          _notlar.removeWhere((not) => not['id'] == id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silme işlemi başarısız")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    }
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isDateTime = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Boş geçilemez";
          return null;
        },
        readOnly: isDateTime,
        onTap: isDateTime
            ? () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate == null) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime == null) return;

                final combined = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                setState(() {
                  _olcumZamani = combined;
                  controller.text = DateFormat('yyyy-MM-dd HH:mm').format(combined);
                });
              }
            : null,
      ),
    );
  }

  Widget _buildNotKagidi(Map<String, dynamic> veri) {
    DateTime tarih = DateTime.parse(veri['tarih']);
    String formattedDate = DateFormat('dd/MM/yyyy – HH:mm').format(tarih);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 Tarih: $formattedDate", style: GoogleFonts.roboto(fontSize: 16, color: Colors.blue[700])),
            const SizedBox(height: 6),
            Text("🩸 Kan Değeri: ${veri['kanDegeri']}", style: GoogleFonts.roboto(fontSize: 16, color: Colors.blue[700])),
            const SizedBox(height: 6),
            Text("🧪 Tahlil Sonuçları: ${veri['tahlilSonuclari']}", style: GoogleFonts.roboto(fontSize: 16, color: Colors.blue[700])),
            const SizedBox(height: 6),
            Text("⏰ Ölçüm Zamanı: ${veri['olcumZamani']}", style: GoogleFonts.roboto(fontSize: 16, color: Colors.blue[700])),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                ),
                onPressed: () => _veriSil(veri['id']),
                child: Text("Sil", style: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.red[200],
    ),
    body: Container(
      child: Padding(
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
                    "KAN DEĞERLERİ",
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
              child: Form(
                key: _formKey, // 🔑 Burada formu ekledik
                child: ListView(
                  children: [
                    _buildInput("Değer Listesi (Kan Değeri)", _degerListesiController),
                    _buildInput("Tahlil Sonuçları (Takip Edilen Hastalık)", _tahlilSonuclariController),
                    _buildInput("Ölçüm Zamanı", _olcumZamaniController, isDateTime: true),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: _veriGonder,
                      child: Text("Veri Gönder", style: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    Text(" Notlar", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700])),
                    Center(
                      child: SizedBox(
                        width: 320,
                        child: Divider(
                          thickness: 2,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._notlar.map((not) => _buildNotKagidi(not)).toList(),
                  ],
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
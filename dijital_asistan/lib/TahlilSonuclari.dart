import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/TahlilService.dart';

class Tahlil {
  final String tarih;
  final String tur;
  final String dosyaAdi;
  final String yorum;

  Tahlil({
    required this.tarih,
    required this.tur,
    required this.dosyaAdi,
    required this.yorum,
  });

  factory Tahlil.fromJson(Map<String, dynamic> json) {
    return Tahlil(
      tarih: json['raporTarihi'] ?? '',
      tur: json['raporBasligi'] ?? '',
      dosyaAdi: json['raporDosyaYolu'] ?? '',
      yorum: json['raporIcerigi'] ?? '',
    );
  }
}

class TahlilSonuclari extends StatefulWidget {
  const TahlilSonuclari({super.key});

  @override
  State<TahlilSonuclari> createState() => _TahlilSonuclariState();
}

class _TahlilSonuclariState extends State<TahlilSonuclari> {
  List<Tahlil> tahliller = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTahliller();
  }

  Future<void> fetchTahliller() async {
    setState(() => isLoading = true);
    final response = await TahlilService.raporListele();
    if (response != null) {
      setState(() {
        tahliller = response.map((item) => Tahlil.fromJson(item)).toList();
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _showMessage("❗ Dosya seçilmedi.");
        return;
      }

      final pickedFile = result.files.first;

      final uploadedJson = kIsWeb
          ? await TahlilService.raporYukle(pickedFile.bytes!, fileName: pickedFile.name)
          : await TahlilService.raporYukle(File(pickedFile.path!));

      if (uploadedJson != null) {
        final yeniTahlil = Tahlil.fromJson(uploadedJson);
        setState(() {
          tahliller.insert(0, yeniTahlil);
        });
      } else {
        _showMessage("❌ Dosya yüklenemedi.");
      }
    } catch (e) {
      _showMessage("⚠️ Hata: $e");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildTahlilCard(Tahlil tahlil) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        color: Colors.grey[100],
        child: ExpansionTile(
          leading: const Icon(Icons.insert_drive_file, size: 40, color: Colors.teal),
          title: Text("Tarih: ${tahlil.tarih}", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Tür: ${tahlil.tur}"),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          children: [
            Text("Dosya: ${tahlil.dosyaAdi}"),
            const SizedBox(height: 10),
            const Text("Yapay Zeka Yorumu:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tahlil.yorum),
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
        backgroundColor:Color(0xFF94D9C6),
        elevation: 0,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              Center(
              child: Column(
                children: [
                  Image.asset(
                    "assets/logo.png",
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "TAHLİL SONUÇLARI",
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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
                ],
              ),
            ),
            ]),
          ),
          const Divider(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : tahliller.isEmpty
                    ? const Center(child: Text("Henüz tahlil yüklenmedi."))
                    : ListView.builder(
                        itemCount: tahliller.length,
                        itemBuilder: (context, index) => _buildTahlilCard(tahliller[index]),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ElevatedButton(
              onPressed: pickAndUploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Tahlil Yükleyin", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
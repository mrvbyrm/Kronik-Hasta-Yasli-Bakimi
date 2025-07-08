import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IlacService {
  static const String baseUrl = 'http://192.168.1.58:5000/api/Ilac';

  // Tüm ilaçları getirme
  static Future<List<Map<String, dynamic>>> getIlaclar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Token bulunamadı!");
      return [];
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      print("İlaçlar alınamadı! Hata Kodu: ${response.statusCode}");
      throw Exception('İlaçlar alınamadı: ${response.statusCode}');
    }
  }

  // İlaç ekleme
  static Future<bool> addIlac(
    String ilacAd,
    String baslangicTarihi,
    String bitisTarihi,
    String siklik,
    String hatirlatmaSaati,
    bool alindiMi,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Token bulunamadı!");
      return false;
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ilacAd': ilacAd,
        'baslangicTarih': baslangicTarihi,
        'bitisTarihi': bitisTarihi,
        'siklik': siklik,
        'hatirlatmaSaati': "$hatirlatmaSaati:00",
        'alindiMi': alindiMi,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ İlaç başarıyla eklendi.");
      return true;
    } else {
      print("İlaç eklenemedi! Hata Kodu: ${response.statusCode}");
      print("Mesaj: ${response.body}");
      return false;
    }
  }

  // İlaç silme
 // İlaç silme
static Future<bool> deleteIlac(int ilacId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    print("Token bulunamadı!");
    return false;
  }

  final response = await http.delete(
    Uri.parse('$baseUrl/$ilacId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    print("✅ İlaç başarıyla silindi.");
    return true;
  } else {
    print("İlaç silinemedi! Hata Kodu: ${response.statusCode}");
    print("Mesaj: ${response.body}");
    return false;
  }
}
}
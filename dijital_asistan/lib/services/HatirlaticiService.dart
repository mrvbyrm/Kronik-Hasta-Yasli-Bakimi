import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HatirlaticiService {
  static const String baseUrl = 'http://192.168.1.58:5000/api/Hatirlatici';

  // 🔄 Hatırlatıcıları getir
  static Future<List<Map<String, dynamic>>> getHatirlaticilar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return [];
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => {
          'rutinId': e['rutinId'],
          'baslik': e['baslik'],
          'gun': e['gun'],
          'saat': e['saat'],
          'tamamlandiMi': e['tamamlandiMi'],
        }).toList();
      } else {
        print("❌ Hatırlatıcılar alınamadı! Hata Kodu: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🔥 Hatırlatıcıları çekerken hata: $e");
      return [];
    }
  }

  // ➕ Yeni hatırlatıcı ekle
  static Future<bool> addHatirlatici({
    required String baslik,
    required int gun,
    required String saat,
    required bool tamamlandiMi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return false;
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'baslik': baslik,
          'gun': gun,
          'saat': saat,
          'tamamlandiMi': tamamlandiMi,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("🔥 Hatırlatıcı eklerken hata: $e");
      return false;
    }
  }

  // ❌ Hatırlatıcı sil
  static Future<bool> deleteHatirlatici(int rutinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return false;
      }

      final url = Uri.parse('$baseUrl/$rutinId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("🔥 Silme hatası: $e");
      return false;
    }
  }

  // ✅ Hatırlatıcı tamamlandı durumunu güncelle (PATCH endpoint ile)
  static Future<bool> updateHatirlaticiTamamlandiMi(int rutinId, bool tamamlandiMi) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return false;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$rutinId/tamamlandi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(tamamlandiMi),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print("🔥 Güncelleme hatası: $e");
      return false;
    }
  }
}
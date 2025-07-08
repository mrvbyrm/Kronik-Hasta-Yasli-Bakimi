import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BesinService {
  static const String baseUrl = 'http://192.168.1.58:5000/api/Besin';

  /// Öneri al ve kaydet işlemi
  static Future<Map<String, dynamic>?> oneriAlVeKaydet({
    required String kategori,
    required String hedef,
    required String aktiviteDuzeyi,
    required String rahatsizlik,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return null;
      }

      final url = Uri.parse('$baseUrl/oneri-al-kaydet');

      final Map<String, dynamic> data = {
        'kategori': kategori,
        'hedef': hedef,
        'aktiviteDuzeyi': aktiviteDuzeyi,
        'rahatsizlik': rahatsizlik,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Öneri alınamadı. Status code: ${response.statusCode}');
        print('🧾 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Hata oluştu: $e');
      return null;
    }
  }

  /// Kullanıcının geçmiş besin kayıtlarını getir
  static Future<List<dynamic>?> getirGecmisKayitlar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return null;
      }

      final url = Uri.parse('$baseUrl/gecmis');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        print('❌ Geçmiş kayıtlar alınamadı. Status code: ${response.statusCode}');
        print('🧾 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Hata oluştu: $e');
      return null;
    }
  }
}
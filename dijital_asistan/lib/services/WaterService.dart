import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WaterService {
  static const String baseUrl = 'http://192.168.1.58:5000/api/SuTakibi';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> addWaterIntake(double litre, DateTime date) async {
    final url = Uri.parse('$baseUrl/ekle');
    final token = await _getToken();

    if (token == null) {
      print("⚠️ Token null geldi. Kullanıcı giriş yapmamış olabilir.");
      throw Exception("Token bulunamadı.");
    }

    final requestBody = {
      'miktar': litre,
      'date': date.toIso8601String(),
    };

    print("➡️ Su ekleme isteği gönderiliyor: $requestBody");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    print("⬅️ Status Code: ${response.statusCode}");
    print("⬅️ Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Su ekleme başarısız: ${response.body}");
    }
  }

  Future<double> getDailyWaterIntake(DateTime date) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Token bulunamadı.");
    }

    final url = Uri.parse('$baseUrl/gunluk?date=${date.toIso8601String()}');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    print("📅 Günlük veri isteği: ${url.toString()}");
    print("⬅️ Status Code: ${response.statusCode}");
    print("⬅️ Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['miktar'] as num).toDouble();
    } else if (response.statusCode == 404) {
      return 0.0;
    } else {
      throw Exception("Su verisi alınamadı: ${response.body}");
    }
  }
}

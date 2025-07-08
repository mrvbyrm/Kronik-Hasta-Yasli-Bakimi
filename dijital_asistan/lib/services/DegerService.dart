import 'package:http/http.dart' as http;
import 'dart:convert';

class DegerService {
  static const String _baseUrl = 'http://192.168.1.58:5000/api/Deger';

  // Değer ekle
  Future<bool> degerEkle({
    required int degerTipiId,
    required Map<String, dynamic> degerListesi,
    required String tahlilSonuclari,
    required String token,
  }) async {
    var url = Uri.parse('$_baseUrl/ekle'); // → dikkat: /ekle eklendi

    Map<String, dynamic> veri = {
      'degerTipiId': degerTipiId,
      'degerListesi': degerListesi, // jsonEncode gerekmiyor, backend DTO içinde Map bekliyor
      'tahlilSonuclari': tahlilSonuclari,
      'tarih': DateTime.now().toIso8601String(),
    };

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(veri),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Veri başarıyla kaydedildi');
      return true;
    } else {
      print('Hata: ${response.statusCode}, ${response.body}');
      return false;
    }
  }

  // Tüm değerleri getir
  Future<List<dynamic>?> degerleriGetir(String token) async {
    var url = Uri.parse(_baseUrl);
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Hata: ${response.statusCode}, ${response.body}');
      return null;
    }
  }

  // Tek değer getir (ID ile)
  Future<Map<String, dynamic>?> degerGetirById(int id, String token) async {
    var url = Uri.parse('$_baseUrl/$id');
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Hata: ${response.statusCode}, ${response.body}');
      return null;
    }
  }

  // Değer güncelle
  Future<bool> degerGuncelle({
    required int id,
    required int degerTipiId,
    required Map<String, dynamic> degerListesi,
    required String tahlilSonuclari,
    required String token,
  }) async {
    var url = Uri.parse('$_baseUrl/$id');

    Map<String, dynamic> veri = {
      'degerTipiId': degerTipiId,
      'degerListesi': degerListesi,
      'tahlilSonuclari': tahlilSonuclari,
      'tarih': DateTime.now().toIso8601String(),
    };

    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(veri),
    );

    if (response.statusCode == 200) {
      print('Veri başarıyla güncellendi');
      return true;
    } else {
      print('Hata: ${response.statusCode}, ${response.body}');
      return false;
    }
  }

  // Değer sil
  Future<bool> degerSil(int id, String token) async {
    var url = Uri.parse('$_baseUrl/$id');

    var response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Veri başarıyla silindi');
      return true;
    } else {
      print('Hata: ${response.statusCode}, ${response.body}');
      return false;
    }
  }
}

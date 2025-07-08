import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdimsayarService {
  final String baseUrl = "http://192.168.1.58:5000/api/AdimSayar"; // kendi URL'ine göre değiştir

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<int> bugunkuAdimGetir() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/bugun"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['adimSayisi'] ?? 0;
    } else {
      throw Exception("Bugünkü adımlar alınamadı: ${response.body}");
    }
  }

  Future<void> adimEkle(int adimSayisi, DateTime tarih) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/ekle"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "adimSayisi": adimSayisi,
        "tarih": tarih.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Adım eklenemedi: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> tumAdimlariGetir() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List jsonData = jsonDecode(response.body);
      return jsonData.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Adımlar alınamadı: ${response.body}");
    }
  }
 

  Future<Map<DateTime, int>> adimlariGetirSon7Gun() async {
  final tumAdimlar = await tumAdimlariGetir();

  DateTime bugun = DateTime.now();
  DateTime yediGunOnce = bugun.subtract(Duration(days: 6));

  Map<DateTime, int> son7GunAdimlar = {};

  for (var adim in tumAdimlar) {
    DateTime tarih = DateTime.parse(adim['tarih']).toLocal();
    int adimSayisi = adim['adimSayisi'];

    if (tarih.isAfter(yediGunOnce.subtract(Duration(days: 1))) && tarih.isBefore(bugun.add(Duration(days: 1)))) {
      son7GunAdimlar[tarih] = adimSayisi;
    }
  }

  var sirali = Map.fromEntries(son7GunAdimlar.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key)));

  return sirali;
}


  Future<void> adimGuncelle(int id, int adimSayisi, DateTime tarih) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "adimSayisi": adimSayisi,
        "tarih": tarih.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Adım güncellenemedi: ${response.body}");
    }
  }

  Future<void> adimSil(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Adım silinemedi: ${response.body}");
    }
  }
}

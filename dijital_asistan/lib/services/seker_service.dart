import 'dart:convert';
import 'package:http/http.dart' as http;

class SekerService {
  final String _baseUrl = "http://192.168.1.58:5000/api/Deger";

  Future<List<Map<String, dynamic>>> sekerVerileriniGetir(String token) async {
    var url = Uri.parse(_baseUrl);

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> veriler = jsonDecode(response.body);
      List<dynamic> sekerVerileri = veriler.where((v) => v['degerTipiId'] == 2).toList();

      return sekerVerileri.map<Map<String, dynamic>>((veri) {
        final degerListesi = veri['degerListesi'];
        final degerler = degerListesi is String ? jsonDecode(degerListesi) : degerListesi;

        return {
          'tarih': veri['tarih'],
          'glukoz': int.tryParse(degerler['glukoz'].toString()) ?? 0,
          'tahlilSonuclari': _cozSonucu(veri['tahlilSonuclari']),
          'olcumZamani': veri['olcumZamani'] ?? '',
          'toklukDurumu': veri['toklukDurumu'] ?? '',
        };
      }).toList();
    } else {
      print('Veri alınamadı: \${response.statusCode}, \${response.body}');
      return [];
    }
  }

  Future<bool> sekerVerisiEkle({
    required int degerTipiId,
    required Map<String, dynamic> degerListesi,
    required String tahlilSonuclari,
    required String token,
    required String olcumZamani,
    required String? toklukDurumu,
  }) async {
    var url = Uri.parse("http://192.168.1.58:5000/api/Deger/ekle");

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'degerTipiId': degerTipiId,
        'degerListesi': jsonEncode(degerListesi),
        'tahlilSonuclari': tahlilSonuclari,
        'tarih': DateTime.now().toIso8601String(),
        'olcumZamani': olcumZamani,
        'toklukDurumu': toklukDurumu,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Şeker verisi başarıyla kaydedildi');
      return true;
    } else {
      print('Hata: \${response.statusCode}, \${response.body}');
      return false;
    }
  }

  String _cozSonucu(dynamic veri) {
    if (veri == null) return "";
    try {
      final decoded = jsonDecode(veri);
      if (decoded is Map<String, dynamic>) {
        return decoded['sonuc'] ?? decoded.values.join(", ");
      }
      return decoded.toString();
    } catch (e) {
      return veri.toString();
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class TansiyonService {
  final String _baseUrl = "http://192.168.1.58:5000/api/Deger";

  Future<List<Map<String, dynamic>>> tansiyonVerileriniGetir(String token) async {
    var url = Uri.parse(_baseUrl);

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> veriler = jsonDecode(response.body);
      List<dynamic> tansiyonVerileri = veriler.where((v) => v['degerTipiId'] == 1).toList();

      return tansiyonVerileri.map<Map<String, dynamic>>((veri) {
        final degerListesi = veri['degerListesi'];
        final degerler = degerListesi is String ? jsonDecode(degerListesi) : degerListesi;

        return {
          'tarih': veri['tarih'],
          'sistolik': int.tryParse(degerler['sistolik'].toString()) ?? 0,
          'diyastolik': int.tryParse(degerler['diyastolik'].toString()) ?? 0,
          'nabiz': int.tryParse(degerler['nabiz'].toString()) ?? 0,
          'tahlilSonuclari': _cozSonucu(veri['tahlilSonuclari']),
        };
      }).toList();
    } else {
      print('Veri alınamadı: ${response.statusCode}, ${response.body}');
      return [];
    }
  }

  Future<bool> tansiyonVerisiEkle({
  required int degerTipiId,
  required Map<String, dynamic> degerListesi,
  required String tahlilSonuclari,
  required String token,
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
      'degerListesi': jsonEncode(degerListesi), // <<< JSON string olarak gönder
      'tahlilSonuclari': tahlilSonuclari,
      'tarih': DateTime.now().toIso8601String(),
      'olcumZamani': null,
      'toklukDurumu': null,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Veri başarıyla kaydedildi');
    return true;
  } else {
    print('Hata: ${response.statusCode}, ${response.body}');
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

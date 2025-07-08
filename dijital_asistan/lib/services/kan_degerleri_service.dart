import 'dart:convert';
import 'package:http/http.dart' as http;

class KanDegerleriService {
  final String _baseUrl = "http://192.168.1.58:5000/api/Deger";  // URL of your API

  // Fetching blood values from the API
  Future<List<Map<String, dynamic>>> kanVerileriniGetir(String token) async {
    var url = Uri.parse(_baseUrl);

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> veriler = jsonDecode(response.body);
      List<dynamic> kanVerileri = veriler.where((v) => v['degerTipiId'] == 3).toList();  // Filtering by DegerTipiId 3

      return kanVerileri.map<Map<String, dynamic>>((veri) {
        final degerListesi = veri['degerListesi'];
        final degerler = degerListesi is String ? jsonDecode(degerListesi) : degerListesi;

        return {
          'tarih': veri['tarih'],
          'kanDegeri': int.tryParse(degerler['kanDegeri'].toString()) ?? 0,  // Assuming kanDegeri as key for blood value
          'tahlilSonuclari': _cozSonucu(veri['tahlilSonuclari']),
          'olcumZamani': veri['olcumZamani'] ?? '',
        };
      }).toList();
    } else {
      print('Veri alınamadı: ${response.statusCode}, ${response.body}');
      return [];
    }
  }

Future<bool> kanDegeriEkle({
  required Map<String, dynamic> degerListesi,
  required String tahlilSonuclari,
  required String token,
  required String olcumZamani,
  required DateTime tarih, // ✅ tarih eklendi
}) async {
  var url = Uri.parse("http://192.168.1.58:5000/api/Deger/ekle"); 

  var response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'degerTipiId': 3,
      'degerListesi': jsonEncode(degerListesi),
      'tahlilSonuclari': tahlilSonuclari,
      'tarih': tarih.toIso8601String(), // ✅ burada kullanılıyor
      'olcumZamani': olcumZamani,
    }),
  );
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Kan değeri başarıyla kaydedildi');
      return true;
    } else {
      print('Hata: ${response.statusCode}, ${response.body}');
      return false;
    }
  }
Future<bool> kanDegeriSil(int id, String token) async {
  var url = Uri.parse("$_baseUrl/sil/$id");  // URL'yi id'yi içerecek şekilde yapılandırıyoruz

  var response = await http.delete(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return true;  // Başarı durumunda true dönüyor
  } else {
    print('Silme işlemi başarısız: ${response.statusCode}, ${response.body}');
    return false;  // Başarısızlık durumunda false dönüyor
  }
}


  // Decoding the lab result and returning a string summary
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

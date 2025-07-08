import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';  // Burayı ekle
import 'package:shared_preferences/shared_preferences.dart';

class RaporService {
  final String _baseUrl = "http://192.168.1.58:5000/api/Rapor/yukle";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<bool> raporYukle(File pdfFile, int kullaniciId) async {
    final token = await _getToken();
    if (token == null) {
      print("Token bulunamadı.");
      return false;
    }

    var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        pdfFile.path,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    request.fields['kullaniciId'] = kullaniciId.toString();

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("Rapor yüklendi: $responseBody");
        return true;
      } else {
        print("Hata: ${response.statusCode}");
        print("Sunucu Yanıtı: $responseBody");
        return false;
      }
    } catch (e) {
      print("Bir hata oluştu: $e");
      return false;
    }
  }
}
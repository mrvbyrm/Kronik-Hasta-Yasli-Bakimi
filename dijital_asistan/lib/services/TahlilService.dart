import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TahlilService {
  static const String baseUrl = 'http://192.168.1.58.194:5000';

  /// PDF dosyası yükleme - Web ve Mobil destekli
  static Future<Map<String, dynamic>?> raporYukle(dynamic fileOrBytes, {String? fileName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return null;
      }

      final uri = Uri.parse('$baseUrl/api/Rapor/yukle');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        // Web: bytes + filename ile gönder
        if (fileOrBytes is Uint8List && fileName != null) {
          final mimeType = lookupMimeType(fileName) ?? 'application/pdf';
          final mediaType = MediaType.parse(mimeType);

          request.files.add(http.MultipartFile.fromBytes(
            'file',
            fileOrBytes,
            filename: fileName,
            contentType: mediaType,
          ));
        } else {
          print("⚠️ Web ortamında geçersiz dosya verisi.");
          return null;
        }
      } else {
        // Mobil: File tipiyle gönder
        if (fileOrBytes is File) {
          final mimeType = lookupMimeType(fileOrBytes.path) ?? 'application/pdf';
          final mediaType = MediaType.parse(mimeType);

          request.files.add(await http.MultipartFile.fromPath(
            'file',
            fileOrBytes.path,
            contentType: mediaType,
            filename: basename(fileOrBytes.path),
          ));
        } else {
          print("⚠️ Mobil ortamda geçersiz dosya tipi.");
          return null;
        }
      }

      final streamedResponse = await request.send();
      final responseString = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(responseString);
        return jsonResponse;
      } else {
        print('API hatası: ${streamedResponse.statusCode}');
        print('Hata mesajı: $responseString');
        return null;
      }
    } catch (e) {
      print('Hata oluştu: $e');
      return null;
    }
  }

  /// Tahlil listesi çekme
  static Future<List<dynamic>?> raporListele() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Token bulunamadı!");
        return null;
      }

      final uri = Uri.parse('$baseUrl/api/Rapor/listele');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        print('API hatası: ${response.statusCode}');
        print('Hata mesajı: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Hata oluştu: $e');
      return null;
    }
  }
}
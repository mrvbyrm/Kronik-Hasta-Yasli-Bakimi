import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.58:5000/api'; // Backend API URL
  static final http.Client client = http.Client();

  // 🔐 Giriş Yapma ve Token'ı Kaydetme
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'eposta': email,
          'sifre': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String token = responseData['token'];
        var userData = responseData['kullanici'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userData['kullaniciId'].toString());
        await prefs.setString('userName', '${userData['ad']} ${userData['soyad']}');
        await prefs.setString('userEmail', userData['eposta']);

        return {
          'token': token,
          'user': userData,
        };
      } else {
        return {
          'error': 'Login failed with status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'error': 'Login error: $e'};
    }
  }

  // ✍️ Kayıt Olma
  static Future<Map<String, dynamic>> register({
    required String eposta,
    required String sifre,
    required String ad,
    required String soyad,
    required String telefon,
    required int yas,
    required String cinsiyet,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'eposta': eposta,
          'sifre': sifre,
          'ad': ad,
          'soyad': soyad,
          'telefonNumarasi': telefon,
          'yas': yas,
          'cinsiyet': cinsiyet,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Registration failed with status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Register error: $e'};
    }
  }

  // 📥 Token'ı SharedPreferences'ten Al
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 📥 Kullanıcı Bilgilerini SharedPreferences'ten Al
  static Future<Map<String, String>?> getUserDataFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');
    String? userEmail = prefs.getString('userEmail');

    if (userId != null && userName != null && userEmail != null) {
      return {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
      };
    }
    return null;
  }

  // ❌ Çıkış Yap (Token ve Kullanıcı Bilgilerini Sil)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  // 📥 Kullanıcı ID'sini Al
  static Future<String?> getUserIdFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // 🔁 Şifre sıfırlama bağlantısı gönderme
  static Future<Map<String, dynamic>> sendResetPasswordLink(String email) async {
    final url = Uri.parse('$baseUrl/auth/sifremi-unuttum');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(email.trim()), // ❗ DİKKAT: JSON encode string olarak
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Şifre sıfırlama bağlantısı gönderildi.'};
      } else {
        return {
          'success': false,
          'error': 'Hata kodu: ${response.statusCode}, ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'İstek hatası: $e'};
    }
  }

  // 🔐 Yeni şifreyi gönderme
  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/sifre-sifirla');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Şifre başarıyla güncellendi.'};
      } else {
        return {
          'success': false,
          'error': 'Şifre güncellenemedi: ${response.statusCode}, ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'İstek hatası: $e'};
    }
  }
}
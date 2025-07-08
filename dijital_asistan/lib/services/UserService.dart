import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String _baseUrl = "http://192.168.1.58:5000/api";

  // 🔍 Kullanıcı profilini GET ile çekme
  static Future<Map<String, dynamic>?> getUserProfile(String token) async {
    final url = Uri.parse("$_baseUrl/Kullanici/profile");
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Kullanıcı bilgisi alınamadı: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Bir hata oluştu (GET): $e");
      return null;
    }
  }

  // ✏️ Kullanıcı profilini PUT ile güncelleme (fotoğrafsız)
  static Future<bool> updateUserProfile(Map<String, dynamic> updatedData, String token) async {
    final url = Uri.parse("$_baseUrl/Kullanici/profile");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        print("✅ Profil başarıyla güncellendi.");
        return true;
      } else {
        print("❌ Güncelleme başarısız: ${response.statusCode}");
        print("Hata içeriği: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Bir hata oluştu (PUT): $e");
      return false;
    }
  }

  // ➕ Acil Yakın Ekleme
  static Future<bool> addAcilYakin(Map<String, dynamic> data, String token) async {
    final url = Uri.parse("$_baseUrl/AcilYakin");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("✅ Acil yakın eklendi.");
        return true;
      } else {
        print("❌ Acil yakın eklenemedi: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Acil yakın ekleme hatası: $e");
      return false;
    }
  }

  // 🔄 Acil Yakın Güncelleme
  static Future<bool> updateAcilYakin(int id, Map<String, dynamic> data, String token) async {
    final url = Uri.parse("$_baseUrl/AcilYakin/$id");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("✅ Acil yakın güncellendi.");
        return true;
      } else {
        print("❌ Acil yakın güncellenemedi: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Acil yakın güncelleme hatası: $e");
      return false;
    }
  }

  // ❌ Acil Yakın Silme
  static Future<bool> deleteAcilYakin(int id, String token) async {
    final url = Uri.parse("$_baseUrl/AcilYakin/$id");

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("🗑️ Acil yakın silindi.");
        return true;
      } else {
        print("❌ Acil yakın silinemedi: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Acil yakın silme hatası: $e");
      return false;
    }
  }

  // 📋 Acil Yakın Listeleme
  static Future<List<dynamic>?> getAcilYakinlar(String token) async {
    final url = Uri.parse("$_baseUrl/AcilYakin");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Acil yakınlar alınamadı: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Acil yakın çekme hatası: $e");
      return null;
    }
  }

  // ➕ Adres Ekleme
  static Future<bool> addAdres(Map<String, dynamic> data, String token) async {
    final url = Uri.parse("$_baseUrl/Adres");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("✅ Adres eklendi.");
        return true;
      } else {
        print("❌ Adres eklenemedi: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Adres ekleme hatası: $e");
      return false;
    }
  }

  // 🔄 Adres Güncelleme
  static Future<bool> updateAdres(int id, Map<String, dynamic> data, String token) async {
    final url = Uri.parse("$_baseUrl/Adres/$id");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("✅ Adres güncellendi.");
        return true;
      } else {
        print("❌ Adres güncellenemedi: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Adres güncelleme hatası: $e");
      return false;
    }
  }

  // ❌ Adres Silme
  static Future<bool> deleteAdres(int id, String token) async {
    final url = Uri.parse("$_baseUrl/Adres/$id");

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("🗑️ Adres silindi.");
        return true;
      } else {
        print("❌ Adres silinemedi: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Adres silme hatası: $e");
      return false;
    }
  }

  // 📋 Adres Listeleme
  static Future<List<dynamic>?> getAdresler(String token) async {
    final url = Uri.parse("$_baseUrl/Adres");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Adresler alınamadı: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Adres çekme hatası: $e");
      return null;
    }
  }
}
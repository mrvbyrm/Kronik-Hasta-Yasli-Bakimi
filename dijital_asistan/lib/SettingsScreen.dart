import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SignInPage.dart'; // Giriş sayfanı import etmeyi unutma

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            child: const Text("Hayır"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text("Evet"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Tüm verileri temizle

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // LOGO ve Başlık
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 8),
                const Text(
                  "INFINITE HEALTH",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.teal),
            title: const Text("Bildirimler"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.language, color: Colors.teal),
            title: const Text("Dil Seçimi"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.lock, color: Colors.teal),
            title: const Text("Gizlilik ve Güvenlik"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Gizlilik Politikası"),
                  content: const Text(
                      "Bu uygulama sadece sağlık takibi amaçlı veri toplar ve üçüncü taraflarla paylaşmaz."),
                  actions: [
                    TextButton(
                      child: const Text("Tamam"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.email, color: Colors.teal),
            title: const Text("Bize Ulaşın"),
            subtitle: const Text("chatgbpt6@gmail.com"),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("İletişim"),
                  content: const Text("Her türlü soru ve öneriniz için:\n\nchatgbpt6@gmail.com"),
                  actions: [
                    TextButton(
                      child: const Text("Tamam"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Çıkış Yap"),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
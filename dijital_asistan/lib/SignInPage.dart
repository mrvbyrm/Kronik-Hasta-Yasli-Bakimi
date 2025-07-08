import 'package:flutter/material.dart';
import 'SignUpPage.dart';
import 'services/AuthService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/FallDetectionService.dart';
import 'InfiniteHealthHomePage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final Color boxColor = const Color(0xFF5FB5B5);
  final Color backgroundColor = const Color(0xFFF7FDFD);

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 80, height: 80),
            const SizedBox(height: 8),
            const Text(
              'INFINITE HEALTH',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5FB5B5),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('GİRİŞ YAP'),
            const SizedBox(height: 10),
            _buildLoginBox(),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text(
                'Hesabınız yok mu? Kaydolun.',
                style: TextStyle(color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5FB5B5),
      ),
    );
  }

  Widget _buildLoginBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            _buildTextField('E-Posta', 'deneme@gmail.com', controller: emailController),
            const SizedBox(height: 12),
            _buildTextField('Şifre', 'sifre123', controller: passwordController, obscureText: true),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
  if (_loginFormKey.currentState!.validate()) {
    // Kullanıcıdan alınan bilgilerle login işlemi yapılıyor
    Map<String, dynamic>? response = await AuthService.login(
      emailController.text,
      passwordController.text,
    );

    // Yanıtın null olmadığı ve token'ın bulunduğu kontrol ediliyor
    if (response != null && response.containsKey('token')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş başarılı'),
          backgroundColor: Colors.green,
        ),
      );

      var userData = response['user'];
      if (userData != null) {
        String fullName = '${userData['ad']} ${userData['soyad']}';
        int userId = userData['kullaniciId'] ?? 0;
        String userEmail = userData['email'] ?? emailController.text;

        print('Kullanıcı Verisi: $userData');

        // SharedPreferences'a kaydet (isteğe bağlı ama tavsiye edilir)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('kullaniciId', userId);
        await prefs.setString('kullaniciEmail', userEmail);

        // FallDetectionService başlat
        final fallService = FallDetectionService(
          kullaniciId: userId,
        
        );
        await fallService.start();
        await fallService.showForegroundNotification();

        // Ana sayfaya yönlendirme yapılır
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InfiniteHealthHomePage(
              userName: fullName,
              userId: userId,
            ),
          ),
        );
      } else {
        // Kullanıcı verisi alınamadığında hata mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı verisi alınamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Giriş başarısız olduğunda hata mesajı gösterilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz kullanıcı adı veya şifre'),
          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: Colors.teal,
                ),
                child: const Text('Giriş Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    bool obscureText = false,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bu alan boş bırakılamaz';
        }
        if (label == 'Şifre' && value.length < 6) {
          return 'Şifre en az 6 karakter olmalıdır';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}
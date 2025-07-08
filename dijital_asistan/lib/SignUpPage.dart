import 'package:flutter/material.dart';
import 'services/AuthService.dart'; // AuthService import
import 'SignInPage.dart'; // SignInPage sayfası import

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Color boxColor = const Color(0xFF5FB5B5);
  final Color backgroundColor = const Color(0xFFF7FDFD);

  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  // Form alanları için controller'lar
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _yasController = TextEditingController();
  String? _cinsiyet;

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: backgroundColor,
    appBar: AppBar(                // <-- Buraya ekleyeceksin
      backgroundColor: boxColor,
      title: const Text('Kayıt Ol'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
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
            _buildSectionTitle('KAYIT OL'),
            const SizedBox(height: 10),
            _buildRegisterBox(),
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

  Widget _buildRegisterBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            _buildTextField('E-Posta', 'HaydayOynayanlarEklesin@gmail.com', controller: _emailController),
            const SizedBox(height: 12),
            _buildTextField('Şifre', 'ghibliLover2025UwUGirl_HotHijabiAtTheBeach', controller: _passwordController, obscureText: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Ad', 'Hatice Merve', controller: _adController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Soyad', 'Bayram', controller: _soyadController)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
  controller: _telefonController,
  keyboardType: TextInputType.phone,
  style: const TextStyle(color: Colors.white),
  autovalidateMode: AutovalidateMode.onUserInteraction,
  decoration: _inputDecoration('Telefon Numarası').copyWith(hintText: '0551 182 9510'),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gerekli';
    }

    final pattern = RegExp(r'^0?5\d{9}$'); // 05XXXXXXXXX veya 5XXXXXXXXX
    if (!pattern.hasMatch(value.replaceAll(' ', ''))) {
      return 'Geçerli bir telefon numarası giriniz (örn. 05551234567)';
    }

    return null;
  },
),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Yaş', '31', controller: _yasController)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cinsiyet,
                    items: ['Kadın', 'Erkek', 'Diğer'].map((String gender) {
                      return DropdownMenuItem<String>(value: gender, child: Text(gender));
                    }).toList(),
                    dropdownColor: boxColor,
                    decoration: _inputDecoration('Cinsiyet'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _cinsiyet = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen bir cinsiyet seçiniz';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                // SignUpPage içinde
onPressed: () async {
  if (_registerFormKey.currentState?.validate() ?? false) {
    // Backend'e kayıt isteği gönder
    final result = await AuthService.register(
      eposta: _emailController.text,
      sifre: _passwordController.text,
      ad: _adController.text,
      soyad: _soyadController.text,
      telefon: _telefonController.text,
      yas: int.parse(_yasController.text),
      cinsiyet: _cinsiyet ?? 'Kadın', // Cinsiyet seçilmemişse varsayılan olarak 'Kadın'
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kaydınız başarılı!'),
          backgroundColor: Colors.green,
        ),
      );

      // Kayıt başarılı olduktan sonra SignInPage'e yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Kayıt başarısız, lütfen tekrar deneyin!'),
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
                child: const Text('Kayıt Ol'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool obscureText = false, required TextEditingController controller}) {
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
        if (label == 'E-Posta') {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
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
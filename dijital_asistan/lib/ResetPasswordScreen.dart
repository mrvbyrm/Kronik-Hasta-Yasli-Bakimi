// reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({required this.token, super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? message;
  bool isLoading = false;

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://192.168.1.58:5000/api/auth/sifre-sifirla'),
      headers: {'Content-Type': 'application/json'},
      body: '{"token": "${widget.token}", "newPassword": "${_passwordController.text}"}',
    );

    setState(() {
      isLoading = false;
      message = response.statusCode == 200
          ? "Şifre başarıyla güncellendi"
          : "Token geçersiz ya da süresi dolmuş.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Şifre Yenile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Yeni Şifre"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : resetPassword,
              child: Text("Şifreyi Güncelle"),
            ),
            if (message != null) ...[
              SizedBox(height: 20),
              Text(message!, style: TextStyle(color: Colors.green)),
            ],
          ],
        ),
      ),
    );
  }
}
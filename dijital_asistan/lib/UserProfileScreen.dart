import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/UserService.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isAcilYakinEnabled = false;
  bool isAdresEnabled = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _yasController = TextEditingController();
  final TextEditingController _cinsiyetController = TextEditingController();
  final TextEditingController _boyController = TextEditingController();
  final TextEditingController _kiloController = TextEditingController();
  final TextEditingController _acilIsimController = TextEditingController();
  final TextEditingController _acilTelController = TextEditingController();
  final TextEditingController _acilEmailController = TextEditingController();
  final TextEditingController _adresDetayController = TextEditingController();

  String? selectedKanGrubu;
  String? token;

  final List<String> _kanGruplari = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token != null) {
      final data = await UserService.getUserProfile(token!);
      if (data != null && mounted) {
        setState(() {
          userData = data;
          _adController.text = data["ad"] ?? "";
          _soyadController.text = data["soyad"] ?? "";
          _telefonController.text = data["telefonNumarasi"] ?? "";
          _tcController.text = data["tcKimlikNo"] ?? "";
          _yasController.text = data["yas"].toString();
          _cinsiyetController.text = data["cinsiyet"] ?? "";
          _boyController.text = data["boy"].toString();
          _kiloController.text = data["kilo"].toString();
          selectedKanGrubu = data["kanGrubu"];
        });
      }
    }
    setState(() => isLoading = false);
  }
String? validatePositiveInt(String? value, String label) {
  if (value == null || value.trim().isEmpty) return "$label boş olamaz.";
  final parsed = int.tryParse(value.trim());
  if (parsed == null) return "$label sadece tam sayı olmalıdır.";
  if (parsed <= 0) return "$label pozitif olmalıdır.";
  return null;
}

String? validatePositiveFloat(String? value, String label) {
  if (value == null || value.trim().isEmpty) return "$label boş olamaz.";
  final parsed = double.tryParse(value.trim());
  if (parsed == null) return "$label sadece sayı olmalıdır.";
  if (parsed <= 0) return "$label pozitif olmalıdır.";
  return null;
}

String? validateMaxLength(String? value, String label, int maxLength) {
  if (value == null || value.trim().isEmpty) return "$label boş olamaz.";
  if (value.trim().length > maxLength) return "$label en fazla $maxLength karakter olabilir.";
  return null;
}

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedData = {
      "ad": _adController.text,
      "soyad": _soyadController.text,
      "telefonNumarasi": _telefonController.text,
      "tcKimlikNo": _tcController.text,
      "yas": int.tryParse(_yasController.text) ?? 0,
      "cinsiyet": _cinsiyetController.text,
      "kanGrubu": selectedKanGrubu,
      "boy": int.tryParse(_boyController.text) ?? 0,
      "kilo": int.tryParse(_kiloController.text) ?? 0,
    };

    final success = await UserService.updateUserProfile(updatedData, token!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil başarıyla güncellendi")));
      _fetchUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güncelleme başarısız.")));
    }
  }

  Future<void> _addAcilYakin() async {
    final data = {
      "isim": _acilIsimController.text,
      "telefonNumarasi": _acilTelController.text,
      "eposta": _acilEmailController.text,
    };

    final success = await UserService.addAcilYakin(data, token!);
    if (success) {
      _fetchUserData();
      _acilIsimController.clear();
      _acilTelController.clear();
      _acilEmailController.clear();
      setState(() => isAcilYakinEnabled = false);
    }
  }

  Future<void> _deleteAcilYakin(int id) async {
    final success = await UserService.deleteAcilYakin(id, token!);
    if (success) _fetchUserData();
  }

  Future<void> _addAdres() async {
    final data = {"adresDetay": _adresDetayController.text};
    final success = await UserService.addAdres(data, token!);
    if (success) {
      _fetchUserData();
      _adresDetayController.clear();
      setState(() => isAdresEnabled = false);
    }
  }

  Future<void> _deleteAdres(int id) async {
    final success = await UserService.deleteAdres(id, token!);
    if (success) _fetchUserData();
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
    {TextInputType type = TextInputType.text, String? Function(String?)? validator}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        validator: validator ?? (value) => value == null || value.isEmpty ? "$label boş olamaz." : null,
      ),
      const SizedBox(height: 12),
    ],
  );
}

Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF94D9C6),
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    backgroundColor: const Color(0xFFFDFDFD),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Image.asset("assets/logo.png", height: 80),
                        const SizedBox(height: 10),
                        const Text(
                          "PROFİL",
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Profil Bilgileri", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const Divider(thickness: 1),

                  const SizedBox(height: 10),
                  _buildLabeledField("Ad", _adController),
                  _buildLabeledField("Soyad", _soyadController),
                  _buildLabeledField(
                    "Telefon Numarası",
                    _telefonController,
                    type: TextInputType.phone,
                    validator: (v) => validateMaxLength(v, "Telefon Numarası", 11),
                  ),
                  _buildLabeledField(
                    "TC Kimlik No",
                    _tcController,
                    type: TextInputType.number,
                    validator: (v) => validateMaxLength(v, "TC Kimlik No", 11),
                  ),
                  _buildLabeledField(
                    "Yaş",
                    _yasController,
                    type: TextInputType.number,
                    validator: (v) => validatePositiveInt(v, "Yaş"),
                  ),
                  _buildLabeledField("Cinsiyet", _cinsiyetController),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
                          "Boy",
                          _boyController,
                          type: TextInputType.number,
                          validator: (v) => validatePositiveFloat(v, "Boy"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLabeledField(
                          "Kilo",
                          _kiloController,
                          type: TextInputType.number,
                          validator: (v) => validatePositiveFloat(v, "Kilo"),
                        ),
                      ),
                    ],
                  ),
                  const Text("Kan Grubu", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedKanGrubu,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _kanGruplari
                        .map((kg) => DropdownMenuItem(value: kg, child: Text(kg)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedKanGrubu = val),
                    validator: (value) => value == null ? "Kan grubu seçilmelidir." : null,
                  ),
                  const SizedBox(height: 20),

                  const Divider(thickness: 1),
                  const Text("Adres Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (userData?['adresler'] != null)
                    ...List<Widget>.from(
                      (userData!['adresler'] as List).map(
                        (adres) => Card(
                          child: ListTile(
                            title: Text(adres['adresDetay']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAdres(adres['id']),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isAdresEnabled) ...[
                    _buildLabeledField("Adres Detayı", _adresDetayController),
                    ElevatedButton(onPressed: _addAdres, child: const Text("Ekle")),
                  ],
                  TextButton(
                    onPressed: () => setState(() => isAdresEnabled = !isAdresEnabled),
                    child: Text(isAdresEnabled ? "İptal" : "Adres Güncelle"),
                  ),

                  const Divider(thickness: 1),
                  const Text("Acil Numaralar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (userData?['acilYakinlar'] != null)
                    ...List<Widget>.from(
                      (userData!['acilYakinlar'] as List).map(
                        (yakin) => Card(
                          child: ListTile(
                            title: Text("${yakin['isim']} - ${yakin['telefonNumarasi']}"),
                            subtitle: Text(yakin['eposta']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAcilYakin(yakin['id']),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isAcilYakinEnabled) ...[
                    _buildLabeledField("İsim", _acilIsimController),
                    _buildLabeledField("Telefon", _acilTelController, type: TextInputType.phone),
                    _buildLabeledField("E-Posta", _acilEmailController, type: TextInputType.emailAddress),
                    ElevatedButton(onPressed: _addAcilYakin, child: const Text("Ekle")),
                  ],
                  TextButton(
                    onPressed: () => setState(() => isAcilYakinEnabled = !isAcilYakinEnabled),
                    child: Text(isAcilYakinEnabled ? "İptal" : "Acil Yakın Güncelle"),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA3D9C9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text("Kaydet", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
}
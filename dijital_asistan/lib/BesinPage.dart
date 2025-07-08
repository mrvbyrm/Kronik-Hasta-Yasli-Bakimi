import 'package:flutter/material.dart';
import '../services/besin_service.dart';

class BesinPage extends StatefulWidget {
  final int userId;

  const BesinPage({super.key, required this.userId});

  @override
  State<BesinPage> createState() => _BesinPageState();
}

class _BesinPageState extends State<BesinPage> {
  String? _selectedKategori;
  String? _selectedHedef;
  String? _selectedAktivite;
  final TextEditingController _rahatsizlikController = TextEditingController();

  String _sonuc = '';
  List<dynamic> _gecmisBesinler = [];
  bool _gecmisGorunur = false;

  final List<String> kategoriler = ['Kahvaltı', 'Öğle', 'Akşam', 'Ara Öğün'];
  final List<String> hedefler = ['Kilo verme', 'Kilo alma', 'Korumak'];
  final List<String> aktiviteDuzeyleri = ['düşük', 'orta', 'yüksek'];

  Future<void> _oneriAl() async {
    if (_selectedKategori == null || _selectedHedef == null || _selectedAktivite == null) {
      setState(() {
        _sonuc = 'Lütfen tüm seçimleri yapınız.';
      });
      return;
    }

    final cevap = await BesinService.oneriAlVeKaydet(
      kategori: _selectedKategori!,
      hedef: _selectedHedef!,
      aktiviteDuzeyi: _selectedAktivite!,
      rahatsizlik: _rahatsizlikController.text.trim(),
    );

    setState(() {
      _sonuc = cevap?['besin']['yapayZekaOnerisi'] ?? 'Öneri alınamadı.';
    });
  }

  Future<void> _gecmisiYukle() async {
    if (_gecmisGorunur) {
      setState(() {
        _gecmisGorunur = false;
      });
    } else {
      final gecmis = await BesinService.getirGecmisKayitlar();
      setState(() {
        _gecmisBesinler = gecmis ?? [];
        _gecmisGorunur = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF94D9C6),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_gecmisGorunur ? Icons.history_toggle_off : Icons.history),
            onPressed: _gecmisiYukle,
            tooltip: _gecmisGorunur ? "Geçmişi Gizle" : "Geçmişi Göster",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset("assets/logo.png", height: 80),
              const SizedBox(height: 10),
              const Text(
                "BESİN",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Kategori',
                value: _selectedKategori,
                items: kategoriler,
                onChanged: (val) => setState(() => _selectedKategori = val),
              ),
              _buildDropdown(
                label: 'Hedef',
                value: _selectedHedef,
                items: hedefler,
                onChanged: (val) => setState(() => _selectedHedef = val),
              ),
              _buildDropdown(
                label: 'Aktivite Düzeyi',
                value: _selectedAktivite,
                items: aktiviteDuzeyleri,
                onChanged: (val) => setState(() => _selectedAktivite = val),
              ),
              _buildTextField(_rahatsizlikController, 'Rahatsızlık (isteğe bağlı)'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _oneriAl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 233, 247, 244),
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Öneri Al'),
              ),
              const SizedBox(height: 20),
              if (_sonuc.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: SizedBox(
                        width: 320,
                        child: Divider(thickness: 2, color: Colors.teal),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Öğün Tavsiyesi:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4F4),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _sonuc,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF344955),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              if (_gecmisGorunur && _gecmisBesinler.isNotEmpty) ...[
                const Text(
                  "Geçmiş Öğünler:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _gecmisBesinler.length,
                  itemBuilder: (context, index) {
                    final item = _gecmisBesinler[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: const Color(0xFFF1FAF9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text("📅 ${item['tarih']?.substring(0, 10) ?? ''} | 🍽 ${item['kategori']}"),
                        subtitle: Text(
                          item['yapayZekaOnerisi'] ?? 'Veri bulunamadı.',
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          "${item['kalori']} kcal",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
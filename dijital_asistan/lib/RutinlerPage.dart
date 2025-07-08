import 'package:flutter/material.dart';
import 'services/HatirlaticiService.dart';
import 'services/NotificationService.dart';
import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';

class RutinlerPage extends StatefulWidget {
  final int userId;
  const RutinlerPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<RutinlerPage> createState() => _RutinlerPageState();
}

class _RutinlerPageState extends State<RutinlerPage> {
  List<Map<String, dynamic>> rutinler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRutinler();
  }

  Future<void> fetchRutinler() async {
    setState(() => isLoading = true);
    final data = await HatirlaticiService.getHatirlaticilar();
    setState(() {
      rutinler = data;
      isLoading = false;
    });
  }

  Future<void> showAddRutinDialog() async {
    final _baslikController = TextEditingController();
    int _selectedGun = 1;
    TimeOfDay _selectedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return ListView(
                    controller: scrollController,
                    children: [
                      const Text("Rutin Ekle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _baslikController,
                        decoration: const InputDecoration(labelText: 'Başlık'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButton<int>(
                        value: _selectedGun,
                        isExpanded: true,
                        onChanged: (value) {
                          setModalState(() => _selectedGun = value ?? 1);
                        },
                        items: List.generate(7, (i) {
                          const gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
                          return DropdownMenuItem(value: i + 1, child: Text(gunler[i]));
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                          if (picked != null) setModalState(() => _selectedTime = picked);
                        },
                        child: Text("Saat Seç: ${_selectedTime.format(context)}"),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_baslikController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('❌ Başlık boş olamaz!')),
                            );
                            return;
                          }
                          String formattedTime = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
                          final success = await HatirlaticiService.addHatirlatici(
                            baslik: _baslikController.text.trim(),
                            gun: _selectedGun,
                            saat: formattedTime,
                            tamamlandiMi: false,
                          );
                          if (success) {
                                final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                            Navigator.pop(context);
                            fetchRutinler();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Rutin eklendi!')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Eklenemedi.')));
                          }
                        },
                        child: const Text("Ekle"),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> deleteRutin(int rutinId) async {
    final success = await HatirlaticiService.deleteHatirlatici(rutinId);
    if (success) {
      fetchRutinler();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Rutin silindi.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Silinemedi.')));
    }
  }

  Future<void> toggleTamamlandiMi(int rutinId, bool value) async {
    final success = await HatirlaticiService.updateHatirlaticiTamamlandiMi(rutinId, value);
    if (success) {
      fetchRutinler();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Güncellenemedi.')));
    }
  }

  Widget buildRutinCard(Map<String, dynamic> rutin) {
  const gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  int? gunIndex;
  if (rutin['gun'] is int) {
    gunIndex = rutin['gun'];
  } else if (rutin['gun'] is String) {
    gunIndex = int.tryParse(rutin['gun']);
  }

  String gunStr = (gunIndex != null && gunIndex >= 1 && gunIndex <= 7)
      ? gunler[gunIndex - 1]
      : 'Bilinmeyen Gün';

  final rutinId = rutin['rutinId'];
  final bool tamamlandi = rutin['tamamlandiMi'] == true;

  final TextStyle titleStyle = tamamlandi
      ? const TextStyle(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
        )
      : const TextStyle(fontWeight: FontWeight.bold);

  final TextStyle subtitleStyle = tamamlandi
      ? const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
        )
      : const TextStyle();

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Color.fromARGB(255, 233, 247, 244),
    child: ListTile(
      leading: Checkbox(
        value: tamamlandi,
        onChanged: (bool? value) {
          if (rutinId != null && rutinId is int && value != null) {
            toggleTamamlandiMi(rutinId, value);
          }
        },
      ),
      title: Text(rutin['baslik'] ?? 'Başlık yok', style: titleStyle),
      subtitle: Text('Gün: $gunStr - Saat: ${rutin['saat'] ?? ''}', style: subtitleStyle),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          if (rutinId != null && rutinId is int) {
            deleteRutin(rutinId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Silinemedi: Rutin ID null veya geçersiz.')),
            );
          }
        },
      ),
    ),
  );
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Color(0xFF94D9C6),
      elevation: 0,
    ),
    
    body: Column(
      children: [
        Center(
          child: Column(
            
            children: [
              const SizedBox(height: 10),
              Image.asset(
                "assets/logo.png",
                height: 80,
              ),
              const SizedBox(height: 10),
              const Text(
                "HAFTALIK RUTİNLER",
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
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                hintText: "Ara...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : rutinler.isEmpty
                  ? const Center(child: Text('Henüz rutininiz yok...'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rutinler.length,
                      itemBuilder: (context, index) {
                        return buildRutinCard(rutinler[index]);
                      },
                    ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: showAddRutinDialog,
      child: const Icon(Icons.add),
      backgroundColor: const Color(0xFF94D9C6),
    ),
  );
}

}
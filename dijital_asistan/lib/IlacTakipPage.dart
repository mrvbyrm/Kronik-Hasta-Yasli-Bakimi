import 'package:flutter/material.dart';
import 'services/IlacService.dart';

class IlacTakipPage extends StatefulWidget {
  final int userId;

  const IlacTakipPage({super.key, required this.userId});

  @override
  _IlacTakipPageState createState() => _IlacTakipPageState();
}

class _IlacTakipPageState extends State<IlacTakipPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> selectedDayMedicines = [];

  final List<String> frequencyOptions = [
    "Her gün",
    "2 günde bir",
    "Haftada bir",
    "2 haftada bir",
    "Ayda bir",
    "Her 2 ayda bir",
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchMedicinesForDay(_focusedDay);
  }

  void _fetchMedicinesForDay(DateTime day) async {
    try {
      List<Map<String, dynamic>> allMedicines = await IlacService.getIlaclar();
      DateTime normalizedDay = DateTime(day.year, day.month, day.day);

      List<Map<String, dynamic>> medicinesForDay = allMedicines.where((ilac) {
        if (ilac['baslangicTarih'] == null || ilac['bitisTarihi'] == null) {
          return false;
        }

        final baslangicRaw = DateTime.parse(ilac['baslangicTarih']);
        final bitisRaw = DateTime.parse(ilac['bitisTarihi']);
        DateTime baslangic = DateTime(baslangicRaw.year, baslangicRaw.month, baslangicRaw.day);
        DateTime bitis = DateTime(bitisRaw.year, bitisRaw.month, bitisRaw.day);

        if (normalizedDay.isBefore(baslangic) || normalizedDay.isAfter(bitis)) {
          return false;
        }

        final siklik = ilac['siklik'] ?? "Her gün";
        Duration diff = normalizedDay.difference(baslangic);

        switch (siklik) {
          case "Her gün":
            return true;
          case "2 günde bir":
            return diff.inDays % 2 == 0;
          case "Haftada bir":
            return diff.inDays % 7 == 0;
          case "2 haftada bir":
            return diff.inDays % 14 == 0;
          case "Ayda bir":
            return normalizedDay.day == baslangic.day;
          case "Her 2 ayda bir":
            return normalizedDay.day == baslangic.day &&
                (normalizedDay.month - baslangic.month) % 2 == 0;
          default:
            return false;
        }
      }).toList();

      setState(() {
        selectedDayMedicines = medicinesForDay;
      });
    } catch (e) {
      print("İlaçlar alınırken hata: $e");
    }
  }

  void _showAddMedicineDialog() {
    TextEditingController nameController = TextEditingController();
    String? selectedFrequency;
    TimeOfDay? reminderTime;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("💊 İlaç Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "İlaç İsmi",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(startDate == null
                      ? "Başlangıç Tarihi Seç"
                      : "${startDate!.day}.${startDate!.month}.${startDate!.year}"),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text(endDate == null
                      ? "Bitiş Tarihi Seç"
                      : "${endDate!.day}.${endDate!.month}.${endDate!.year}"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Sıklık Seç",
                    border: OutlineInputBorder(),
                  ),
                  items: frequencyOptions.map((String freq) {
                    return DropdownMenuItem(value: freq, child: Text(freq));
                  }).toList(),
                  onChanged: (value) => selectedFrequency = value,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() => reminderTime = pickedTime);
                    }
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(reminderTime == null
                      ? "Hatırlatma Saati Seç"
                      : reminderTime!.format(context)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Kaydet"),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    startDate != null &&
                    endDate != null &&
                    selectedFrequency != null &&
                    reminderTime != null) {
                  _ilacEkle(
                    ilacAd: nameController.text,
                    baslangicTarih: startDate!,
                    bitisTarih: endDate!,
                    siklik: selectedFrequency!,
                    hatirlatmaSaati: reminderTime!,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _ilacEkle({
    required String ilacAd,
    required DateTime baslangicTarih,
    required DateTime bitisTarih,
    required String siklik,
    required TimeOfDay hatirlatmaSaati,
  }) async {
    bool basarili = await IlacService.addIlac(
      ilacAd,
      baslangicTarih.toIso8601String(),
      bitisTarih.toIso8601String(),
      siklik,
      "${hatirlatmaSaati.hour}:${hatirlatmaSaati.minute}",
      false,
    );

    if (basarili) {
      if (_selectedDay != null) {
        _fetchMedicinesForDay(_selectedDay!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlaç başarıyla eklendi!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlaç eklenirken hata oluştu.")),
      );
    }
  }

Widget _buildDateBar() {
  DateTime now = DateTime.now();
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday % 7));
  
  return SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),  // Kaydırmayı garantiye alır, istersen ScrollPhysics ile oynayabilirsin
      itemCount: 90,
      itemBuilder: (context, index) {
        DateTime day = startOfWeek.add(Duration(days: index));
        bool isSelected = isSameDay(_selectedDay, day);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
              _fetchMedicinesForDay(day);
            });
          },
          
          child: Container(
            
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyan : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
                Text(
                  day.day.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _ayAdi(day.month),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}



  String _ayAdi(int month) {
    const aylar = [
      "Oca", "Şub", "Mar", "Nis", "May", "Haz",
      "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"
    ];
    return aylar[month - 1];
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    return a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
        backgroundColor:Color(0xFF94D9C6),
        elevation: 0,
      ),
    body: Column(
      children: [
         const SizedBox(height: 20),
            Image.asset(
              'assets/logo.png', // 💡 Logo buraya eklenecek
              height: 80,
            ),
            const SizedBox(height: 8),
            const Text(
                "İLAÇ TAKİP",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
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
        _buildDateBar(),
        const SizedBox(height: 10),
        Text(
          "Bugün, ${_selectedDay!.day} ${_ayAdi(_selectedDay!.month)}",
          style: const TextStyle(color: Colors.cyan, fontSize: 18),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showAddMedicineDialog,
         style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 233, 247, 244), // Arka plan rengi
                  foregroundColor: Colors.teal,  // Yazı rengi
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ), 
          icon: const Icon(Icons.add),
          label: const Text("İLAÇ EKLE"),
        ),
        const Divider(height: 30),
        Expanded(
          child: ListView(
            children: selectedDayMedicines.map((ilac) => ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(ilac['ilacAd']),
                  subtitle: Text(
                      "Saat: ${ilac['hatirlatmaSaati']} - Sıklık: ${ilac['siklik']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Silme işlemi yapılacak
                    },
                  ),
                )).toList(),
          ),
        ),
      ],
    ),
  );
}

}
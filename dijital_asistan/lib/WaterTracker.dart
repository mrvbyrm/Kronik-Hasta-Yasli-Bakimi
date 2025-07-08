import 'package:flutter/material.dart';
import 'services/UserService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTracker extends StatefulWidget {
  @override
  _WaterTrackerState createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  List<bool> glasses = List.filled(7, false); // 7 bardak

  int get totalWaterMl => glasses.where((g) => g).length * 250; // her bardak 250ml

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  glasses[index] = !glasses[index];
                });
              },
              child: Container(
                width: 30,
                height: 50,
                decoration: BoxDecoration(
                  color: glasses[index] ? Colors.white : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'İçilen Su: $totalWaterMl ml',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
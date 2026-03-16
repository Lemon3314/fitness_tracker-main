import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final int steps;
  final int stepGoal;
  final VoidCallback onReset; // 接收一個函式
  final VoidCallback onAdd;   // 接收一個函式

  const HomeScreen({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.onReset,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text("步數追蹤器", style: TextStyle(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 30),
            _buildProgressRing(),
            const SizedBox(height: 50),
            _buildStatsRow(),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: onReset, // 使用傳進來的函式
                    icon: const Icon(Icons.refresh, color: Colors.redAccent),
                    label: const Text("重置步數", style: TextStyle(color: Colors.redAccent)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: onAdd, // 使用傳進來的函式
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text("增加步數"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 將原本在 main.dart 的輔助組件搬過來
  Widget _buildProgressRing() {
    return Center(
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 250,
          height: 250,
          child: CircularProgressIndicator(
            value: steps / stepGoal,
            strokeWidth: 20,
            color: Colors.greenAccent,
            backgroundColor: Colors.white12,
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text("$steps", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)),
          Text("目標: $stepGoal", style: const TextStyle(color: Colors.white70)),
        ])
      ]),
    );
  }

  Widget _buildStatsRow() {
    double distanceKm = (steps * 0.7) / 1000;
    double caloriesKcal = steps * 0.04;
    return Column(
      children: [
        _statCard("估算距離", distanceKm.toStringAsFixed(2), "km", Icons.straighten, Colors.blueAccent),
        const SizedBox(height: 12),
        _statCard("消耗熱量", caloriesKcal.toStringAsFixed(1), "kcal", Icons.local_fire_department, Colors.orangeAccent),
      ],
    );
  }

  Widget _statCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 6),
                    Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
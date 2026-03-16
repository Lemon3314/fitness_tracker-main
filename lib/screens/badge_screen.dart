import 'package:flutter/material.dart';

class BadgeScreen extends StatelessWidget {
  final int steps;

  const BadgeScreen({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _badgeItem("初級", Icons.directions_walk, steps >= 100),
            _badgeItem("中級", Icons.directions_run, steps >= 500),
            _badgeItem("高級", Icons.directions_bike, steps >= 1000),
            _badgeItem("馬拉松", Icons.workspace_premium, steps >= 5000),
            _badgeItem("運動大師", Icons.auto_awesome, steps >= 10000),
          ],
        ),
      )
    );
  }


  Widget _badgeItem(String title, IconData icon, bool isUnlocked) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 30,
          // 邏輯細節：達成就亮綠色，沒達成變灰色
          backgroundColor: isUnlocked ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.white10,
          child: Icon(
            icon,
            color: isUnlocked ? Colors.greenAccent : Colors.white24,
            size: 35,
          ),
          ),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: isUnlocked ? Colors.white : Colors.white24,fontSize: 12),),
    
        
      ],
    );
  }
}
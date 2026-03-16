import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  // 先寫一組「假資料」來模擬從原生端拿到的數據
  // 每一筆資料包含：日期、步數、達標率
  final List<Map<String, dynamic>> dummyHistory = [
    {"date": "2026-03-12", "steps": 8500, "goal": 10000},
    {"date": "2026-03-11", "steps": 12000, "goal": 10000},
    {"date": "2026-03-10", "steps": 4300, "goal": 10000},
    {"date": "2026-03-09", "steps": 10500, "goal": 10000},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("歷史紀錄"),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),

        itemCount: dummyHistory.length, // 告訴 Flutter 總共有幾筆
        itemBuilder: (context, index) {
          final record = dummyHistory[index]; // 取出當前這筆資料
          double progress = record['steps'] / record['goal']; // 計算達標率
          bool isGoalReached = progress >= 1.0;

          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isGoalReached ? Colors.greenAccent : Colors.white12,
                child: Icon(
                  isGoalReached ? Icons.check : Icons.directions_walk,
                  color: isGoalReached ? Colors.black : Colors.white38,
                ),
              ),
              title: Text(record['date'], style: TextStyle(color: Colors.white70)),
              subtitle: Text("步數: ${record['steps']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: Text(
                "${(progress* 100).toInt()}%",
                style: TextStyle(color: isGoalReached ? Colors.greenAccent : Colors.white38),
              )
            ),
          );
        },
      )
    );
  }
}
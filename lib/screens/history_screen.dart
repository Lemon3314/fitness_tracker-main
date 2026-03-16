import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const platform = MethodChannel('com.example.fitness/steps');

  // 1. 宣告一個變數來儲存 Future 實體
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // 2. 在初始化時就執行請求，並保存在變數中
    // 這樣就算 build 跑 100 次，_historyFuture 依然是同一個，不會重新請求
    _historyFuture = _fetchHistory();
  }

  Future<List<dynamic>> _fetchHistory() async {
    try {
      final String jsonString = await platform.invokeMethod('getHistory');
      return jsonDecode(jsonString);
    } catch (e) {
      print("讀取歷史失敗: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("步行歷史紀錄")),
      body: FutureBuilder<List<dynamic>>(
        // 3. 這裡改用剛才存好的變數，不要直接呼叫方法
        future: _historyFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("尚無紀錄，明天再來看看吧！"));
          }

          final historyList = snapshot.data!.reversed.toList();

          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.greenAccent),
                  title: Text(item['date'] ?? "未知日期"),
                  trailing: Text(
                    "${item['steps']} 步",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}


class _HistoryScreenState extends State<HistoryScreen> {
  static const platform = MethodChannel('com.example.fitness/steps');
  
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
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

  // --- 新增：處理刷新的方法 ---
  Future<void> _handleRefresh() async {
    setState(() {
      // 重新請求數據並更新 Future 變數
      _historyFuture = _fetchHistory();
    });
    // 等待數據請求完成，這樣下拉的小圈圈才會消失
    await _historyFuture;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("步行歷史紀錄")),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.greenAccent,
        child: FutureBuilder<List<dynamic>>(

          future: _historyFuture,  // 1. 綁定你的「號碼牌」（非同步任務）
          builder: (context, snapshot) { // 2. 當狀態改變時，這個 builder 會重新執行
            
            // 情況 A：還在等（轉圈圈）
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // 情況 B：出錯或是沒資料（顯示提示文字）
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  Center(child: Text("尚無紀錄，下拉刷新試試看！")),
                ],
              );
            }

            // 情況 C：大功告成（把資料 snapshot.data 拿出來用）
            final historyList = snapshot.data!.reversed.toList();

            return ListView.builder(

              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: historyList.length,

              itemBuilder: (context, index) {
                final item = historyList[index];
                
                // --- 1. 計算該日期的數據 ---
                final int steps = item['steps'] ?? 0;
                double dist = (steps * 0.7) / 1000; // 公里
                double cals = steps * 0.04;          // 熱量

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),

                    leading: CircleAvatar(
                      backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                      child: Icon(Icons.history, color: Colors.greenAccent),
                    ),
                    
                    // 標題顯示日期
                    title: Text(
                      item['date'] ?? "未知日期",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    // --- 2. 副標題顯示距離與熱量 ---
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "📏 ${dist.toStringAsFixed(2)} km  •  🔥 ${cals.toStringAsFixed(1)} kcal",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                    
                    // 右側顯示大大的步數
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$steps",
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.greenAccent
                          ),
                        ),
                        Text("步數", style: TextStyle(fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

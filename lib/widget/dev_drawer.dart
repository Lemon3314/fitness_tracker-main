import 'package:flutter/material.dart';

class DevDrawer extends StatelessWidget {
  // 定義回呼函數，用來通知 main.dart 更新狀態
  final Function(int) onSetSteps;
  final Function(String) onSimulateNextDay;

  const DevDrawer({
    super.key,
    required this.onSetSteps,
    required this.onSimulateNextDay,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.55, // 限制寬度為螢幕的 55%
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text("開發測試面板", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              leading: Icon(Icons.bug_report, color: Colors.greenAccent),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("設定步數"),
              onTap: () => _showSetStepsDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text("模擬指定日期跨日"),
              subtitle: Text("自選存檔日期", style: TextStyle(fontSize: 12)),
              onTap: () => _pickSimulateDate(context), // 改用選日期的方法
            ),
          ],
        ),
      ),
    );
  }

  // 顯示輸入步數的對話框
  void _showSetStepsDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("設定當天步數"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "請輸入任意步數..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("取消"),
            ),
            ElevatedButton(
              onPressed: () {
                int val = int.tryParse(controller.text) ?? 0;
                onSetSteps(val); // 呼叫 main.dart 傳進來的方法
                Navigator.pop(context); // 關閉對話框
                Navigator.pop(context); // 關閉側邊欄
              },
              child: Text("確認"),
            ),
          ],
        );
      },
    );
  }

  void _pickSimulateDate(BuildContext context) async {
    // 彈出 Flutter 內建的日期選擇器
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 1)), // 預設選昨天
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
  
    if (picked != null) {
      // 格式化為 yyyy-MM-dd
      String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      
      // 呼叫 main.dart 傳進來的方法，通知 Native
      onSimulateNextDay(formattedDate);
      
      // 在 StatelessWidget 中使用 context 前建議檢查 mounted
      if (!context.mounted) return; 
      Navigator.pop(context); // 關閉側邊欄
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已將歷史紀錄存入 $formattedDate！")),
      );
    }
  }
}
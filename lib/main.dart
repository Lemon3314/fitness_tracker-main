import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/badge_screen.dart';
import 'screens/history_screen.dart'; 
import 'screens/analysis_screen.dart';
import 'screens/home_screen.dart';

void main() => runApp(MaterialApp(
  home: MyStepTracker(),
  theme: ThemeData.dark(),
));

class MyStepTracker extends StatefulWidget {
  @override
  State<MyStepTracker> createState() => _MyStepTrackerState();
}

class _MyStepTrackerState extends State<MyStepTracker> {
  
  static const platform = MethodChannel('com.example.fitness/steps');

  int _curIndex = 0;
  final int _stepGoal = 1000;
  int _steps = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _getStepFromNative();
    });
  }   

  Future<void> _simulateNextDay(String date) async {
    try {
      final int result = await platform.invokeMethod('simulateNextDay', {'date': date});
      setState(() {
        _steps = result;
      });
    } on PlatformException catch (e) {
      print("error: ${e.message}");
    }
  }
  
  Future<void> _setTargetSteps(int steps) async {
    try {
      final int result = await platform.invokeMethod('setSteps', {'steps': steps});
      setState(() {
        _steps = result;
      });
    } on PlatformException catch (e) {
      print("error: ${e.message}");
    }
  }
  
  Future<void> _getStepFromNative() async {
    try {
      final int result = await platform.invokeMethod('getDailySteps');
      setState(() {
        _steps = result;
      });
    } on PlatformException catch (e) {
      print("error: ${e.message}");
    }
  }

  Future<void> _resetSteps() async {
    try {
      final int result = await platform.invokeMethod('resetSteps');
      setState(() {
        _steps = result;
      });
    } on PlatformException catch (e) {
      print("error: ${e.message}");
    }
  }

  Future<void> _AddSteps() async {
    try {
      final int result = await platform.invokeMethod('addSteps', {'steps': 100});
      setState(() {
        _steps = result;
      });
    } on PlatformException catch (e) {
      print("error: ${e.message}");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 這裡定義三個分頁的內容
    final List<Widget> _pages = [
      HomeScreen(
        steps: _steps,
        stepGoal: _stepGoal,
        onReset: _resetSteps, // 傳入邏輯方法
        onAdd: _AddSteps,     // 傳入邏輯方法
        isActive: _curIndex == 0,
      ), // 原本的首頁 UI
      BadgeScreen(steps: _steps), // 勳章頁：把目前的步數傳進去
      
      // 傳入一個布林值，告訴分析頁它現在是不是「主角」
      AnalysisScreen(isCurrentPage: _curIndex == 2),
      HistoryScreen(), // 歷史頁（目前是空的）
    ];


    return Scaffold(

      // 加入這個：右側滑出的 Drawer，並限制寬度
      endDrawer: Drawer(
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
      ),

      // 使用 IndexedStack 像疊盤子一樣切換頁面，效能最好
      body: IndexedStack(
        index: _curIndex,
        children: _pages,
      ),

      // 底部導航欄
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _curIndex,

        onTap: (index) {
          setState(() {
            _curIndex = index; // 點擊時更新索引，觸發畫面重繪
          });
        },

        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首頁"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "勳章"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "分析"), // <--- 新增項目
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "歷史"),
        ],
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
                _setTargetSteps(val);
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
      
      // 呼叫 Native
      await _simulateNextDay(formattedDate);
      
      if (!mounted) return;
      Navigator.pop(context); // 關閉側邊欄
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已將歷史紀錄存入 $formattedDate！")),
      );
    }
  }
}


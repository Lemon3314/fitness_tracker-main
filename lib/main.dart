import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 引入你的各個 Screen 檔案
import 'screens/badge_screen.dart';
import 'screens/history_screen.dart'; 
import 'screens/analysis_screen.dart';
import 'screens/home_screen.dart';

// 引入剛抽離出來的 Drawer
import 'package:fitness_tracker/widget/dev_drawer.dart';

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
      HistoryScreen(isActive: _curIndex == 3,), // 歷史頁（目前是空的）
    ];

    return Scaffold(
      // 加入這個：右側滑出的 Drawer，並限制寬度
      // 這裡呼叫我們拆分出去的 DevDrawer，並把需要修改 state 的方法當作參數傳進去
      endDrawer: DevDrawer(
        onSetSteps: _setTargetSteps,
        onSimulateNextDay: _simulateNextDay,
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
}
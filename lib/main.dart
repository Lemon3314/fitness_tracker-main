import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/badge_screen.dart';
import 'screens/history_screen.dart'; 
import 'screens/home_screen.dart';

void main() => runApp(MaterialApp(
  home: MyStepTracker(),
  theme: ThemeData.dark(),
));

class MyStepTracker extends StatefulWidget {
  @override
  _MyStepTrackerState createState() => _MyStepTrackerState();
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
      ), // 原本的首頁 UI
      BadgeScreen(steps: _steps), // 勳章頁：把目前的步數傳進去
      HistoryScreen(), // 歷史頁（目前是空的）
    ];


    return Scaffold(
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "歷史"),
        ],
      ),


    );
  }

  
}


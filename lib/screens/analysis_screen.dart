// screens/analysis_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  static const platform = MethodChannel('com.example.fitness/steps');
  
  List<dynamic> _history = [];
  int _selectedTab = 0; // 0 代表 7天 (本週), 1 代表 30天 (本月)

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final String jsonString = await platform.invokeMethod('getHistory');
      List<dynamic> data = jsonDecode(jsonString);
      setState(() {
        _history = data;
      });
    } catch (e) {
      print("分析頁面讀取歷史失敗: $e");
    }
  }

  // --- 核心邏輯：產生包含「空缺補零」的連續日期資料 ---
  List<Map<String, dynamic>> _generateChartData(int days) {
    List<Map<String, dynamic>> result = [];
    DateTime today = DateTime.now();

    // 先把歷史紀錄轉成 Map，方便快速查詢 (Key: 日期字串, Value: 步數)
    Map<String, int> historyMap = {};
    for (var item in _history) {
      historyMap[item['date']] = item['steps'] as int;
    }

    // 由舊到新 (從 days-1 天前，一路算到今天)
    for (int i = days - 1; i >= 0; i--) {
      DateTime targetDate = today.subtract(Duration(days: i));
      // 格式化為 yyyy-MM-dd 以便與紀錄比對
      String dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      
      // 如果歷史紀錄有這天就取值，沒有就給 0
      int steps = historyMap[dateStr] ?? 0;
      result.add({
        'date': dateStr,
        'steps': steps,
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // 根據目前的 Tab 決定要產生幾天的資料
    int daysCount = _selectedTab == 0 ? 7 : 30;
    List<Map<String, dynamic>> currentData = _generateChartData(daysCount);

    return Scaffold(
      appBar: AppBar(
        title: Text("數據分析"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchHistory,
          )
        ],
      ),
      // 就算沒有歷史紀錄，我們現在也會顯示 0 步的圖表，不用擋住使用者了
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildToggleBar(), // 上方的 7天/30天 切換按鈕
            SizedBox(height: 20),
            _buildSummary(currentData), // 根據當前選擇的區間計算總覽
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _selectedTab == 0 ? "近 7 日運動趨勢" : "近 30 日運動趨勢", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
            SizedBox(height: 20),
            _buildChart(currentData, _selectedTab == 1), // 傳入是否為 30 天模式
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- 1. 切換按鈕 UI ---
  Widget _buildToggleBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _buildTabButton(title: "這禮拜", index: 0),
          _buildTabButton(title: "這個月", index: 1),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.transparent
            )
          ),
          child: Center(
            child: Text(
              title, 
              style: TextStyle(
                color: isSelected ? Colors.greenAccent : Colors.white54, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. 數據總覽 (動態計算) ---
  Widget _buildSummary(List<Map<String, dynamic>> data) {
    int totalSteps = data.fold(0, (sum, item) => sum + (item['steps'] as int));
    int avgSteps = (totalSteps / data.length).round();
    int maxSteps = data.fold(0, (max, item) {
      int steps = item['steps'] as int;
      return steps > max ? steps : max;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(child: _summaryCard("日平均", "$avgSteps", Colors.blueAccent)),
          SizedBox(width: 12),
          Expanded(child: _summaryCard("區間最高", "$maxSteps", Colors.orangeAccent)),
          SizedBox(width: 12),
          Expanded(child: _summaryCard("總計", "$totalSteps", Colors.greenAccent)),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white60, fontSize: 12)),
          SizedBox(height: 8),
          // 數字如果太大，稍微縮小字體避免跑版
          Text(value, style: TextStyle(color: color, fontSize: value.length > 5 ? 16 : 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- 3. 純手工繪製長條圖 ---
  Widget _buildChart(List<Map<String, dynamic>> data, bool isMonthView) {
    int maxSteps = data.fold(1, (max, e) => (e['steps'] as int) > max ? (e['steps'] as int) : max);
    if (maxSteps == 0) maxSteps = 1; 

    return Container(
      height: 220,
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        // 30天用 spaceBetween 撐滿，7天用 spaceEvenly 讓間距更舒適
        mainAxisAlignment: isMonthView ? MainAxisAlignment.spaceBetween : MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          
          var item = data[index];
          int steps = item['steps'] as int;
          double barHeight = (steps / maxSteps) * 140; // 容器高度最高 140

          // UI 邏輯判定
          // 30天模式：只在頭、尾、以及每隔 5 天顯示一次日期標籤
          bool showDateLabel = !isMonthView || (index == 0 || index == data.length - 1 || index % 6 == 0);
          // 30天模式：隱藏頂部的數字，避免 30 個數字擠在一起看不清
          bool showStepNumber = !isMonthView;
          
          // 將日期從 yyyy-MM-dd 截斷成 MM/dd
          String displayDate = item['date'].toString().substring(5).replaceFirst('-', '/');

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 柱子頂部的步數數字
              if (showStepNumber) 
                Text("$steps", style: TextStyle(fontSize: 10, color: Colors.white70)),
              
              SizedBox(height: 4),
              
              // 實體柱子
              Container(
                width: isMonthView ? 6 : 24, // 30天柱體變細 (6px)，7天較粗 (24px)
                height: barHeight > 0 ? barHeight : 2, // 就算為 0 也留 2px 的底色
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: steps > 0 
                        ? [Colors.greenAccent, Colors.teal] 
                        // 如果步數是 0，柱子就變成暗灰色
                        : [Colors.white10, Colors.white10], 
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(isMonthView ? 3 : 6),
                ),
              ),
              
              SizedBox(height: 8),
              
              // 柱子底部的日期標籤
              if (showDateLabel)
                Text(displayDate, style: TextStyle(fontSize: 9, color: Colors.white54))
              else
                // 如果不顯示標籤，也要保留高度位置，避免柱體往下沉
                SizedBox(height: 12, width: isMonthView ? 6 : 24), 
            ],
          );
        }),
      ),
    );
  }
}
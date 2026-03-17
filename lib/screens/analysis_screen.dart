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

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final String jsonString = await platform.invokeMethod('getHistory');
    setState(() {
      _history = jsonDecode(jsonString);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 這裡實作「趨勢檢視」：取最近 7 筆
    List<dynamic> chartData = _history.length > 7 
        ? _history.sublist(_history.length - 7) 
        : _history;

    return Scaffold(
      appBar: AppBar(title: Text("數據分析")),
      body: _history.isEmpty 
        ? Center(child: Text("尚無數據，請先使用測試面板模擬跨日"))
        : Column(
            children: [
              _buildSummary(),
              _buildChart(chartData),
              Text("近期 7 日步數趨勢", style: TextStyle(color: Colors.white54)),
            ],
          ),
    );
  }

  // 簡易長條圖 (不使用套件)
  Widget _buildChart(List<dynamic> data) {
    int maxSteps = data.fold(1, (max, e) => e['steps'] > max ? e['steps'] : max);
    
    return Container(
      height: 200,
      margin: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          double barHeight = (item['steps'] / maxSteps) * 150;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("${item['steps']}", style: TextStyle(fontSize: 10)),
              Container(
                width: 30,
                height: barHeight + 5,
                color: Colors.greenAccent,
              ),
              Text(item['date'].toString().substring(5)), // 顯示 MM-dd
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummary() {
    // 這裡可以做「不同維度」的邏輯分析，例如平均值
    return Container( /* ... 總步數、平均值 UI ... */ );
  }
}
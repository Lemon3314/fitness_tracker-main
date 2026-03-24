// screens/analysis_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // 1. 必須引入這個才能使用 Timer

class AnalysisScreen extends StatefulWidget {
  final bool isCurrentPage; // 接收來自 main 的狀態
  const AnalysisScreen({super.key,this.isCurrentPage = false});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

// 1. 加入 SingleTickerProviderStateMixin 才能使用動畫控制器
class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin{
  static const platform = MethodChannel('com.example.fitness/steps');
  
  List<dynamic> _history = [];
  int _selectedTab = 0; // 0 代表 7天 (本週), 1 代表 30天 (本月)

// 2. 定義動畫相關變數
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchHistory();

    // 3. 初始化動畫控制器 (設定 800 毫秒讓生長感更明顯)
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    // 使用節點曲線 (Cubic)，讓動畫有「彈出」的生動感
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    _fetchHistory();
    _controller.forward(); // 進入頁面時啟動動畫

    // 定時刷新 (保留之前的邏輯)
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) _fetchHistory();
    });

  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose(); // 4. 銷毀控制器避免耗電
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 關鍵邏輯：
    // 如果「原本不是當前頁」變成「現在是當前頁」，就重播動畫
    if (!oldWidget.isCurrentPage && widget.isCurrentPage) {
      _controller.forward(from: 0.0); 
      _fetchHistory(); // 順便重新抓取最新數據
    }
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

  // 修改切換 Tab 的邏輯
  void _handleTabChange(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
    });
    // 5. 切換 Tab 時，將動畫重設為 0 並重新播放
    _controller.forward(from: 0.0);
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
          _buildTabButton(title: "近 7 日", index: 0),
          _buildTabButton(title: "近 30 日", index: 1),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTabChange(index),
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

  // 使用 AnimatedBuilder 監聽動畫狀態，每一幀都會重新繪製
  return AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: isMonthView ? MainAxisAlignment.spaceBetween : MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,

          
          children: List.generate(data.length, (index) {
            var item = data[index];
            int steps = item['steps'] as int;
            
            // 核心動畫邏輯：將目標高度乘以動畫當前值 (0.0 -> 1.0)
            double targetHeight = (steps / maxSteps) * 140;
            double animatedHeight = targetHeight * _animation.value;

            bool showDateLabel = !isMonthView || (index == 0 || index == data.length - 1 || index % 6 == 0);
            bool showStepNumber = !isMonthView;
            String displayDate = item['date'].toString().substring(5).replaceFirst('-', '/');

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showStepNumber)
                  // 數字部分加上透明度動畫，隨柱體上升慢慢浮現
                  Opacity(
                    opacity: _animation.value,
                    child: Text("$steps", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: isMonthView ? 6 : 24,
                  // 動畫高度應用在此
                  height: animatedHeight > 0 ? animatedHeight : 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: steps > 0 
                          ? [Colors.greenAccent, Colors.teal] 
                          : [Colors.white10, Colors.white10],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(isMonthView ? 3 : 6),
                  ),
                ),
                const SizedBox(height: 8),
                if (showDateLabel)
                  Text(displayDate, style: const TextStyle(fontSize: 9, color: Colors.white54))
                else
                  SizedBox(height: 12, width: isMonthView ? 6 : 24),
              ],
            );
          }),
        ),
      );
    },
  );
}
}
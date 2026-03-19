import 'package:flutter/material.dart';
import 'package:fitness_tracker/widget/RoundedCircularProgressIndicator.dart';

class HomeScreen extends StatefulWidget {
  final int steps;
  final int stepGoal;
  final VoidCallback onReset;
  final VoidCallback onAdd;
  final bool isActive;

  const HomeScreen({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.onReset,
    required this.onAdd,
    required this.isActive,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _lastProgress = 0.0; // 記錄上一次的進度位置
  
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // 設定播放時長
    );

    // 初始動畫：從 0 到當前進度
    double currentProgress = widget.stepGoal > 0 ? widget.steps / widget.stepGoal : 0;
    _animation = Tween<double>(begin: 0, end: currentProgress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isActive) {
      _controller.forward();
      _lastProgress = currentProgress;
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    double newProgress = widget.stepGoal > 0 ? widget.steps / widget.stepGoal : 0;

    // 情境一：從其他頁面切換回來 -> 從 0 開始播放
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation(0, newProgress);
    } 
    // 情境二：步數有變動且目前正在此頁面 -> 從舊進度跑到新進度
    else if (widget.isActive && oldWidget.steps != widget.steps) {
      _startAnimation(_lastProgress, newProgress);
    }

    _lastProgress = newProgress; // 更新最後紀錄
  }

  void _startAnimation(double begin, double end) {

    double delta = (end - begin).abs();

    int dynamicDuration = ((delta>1)?((delta>5)?300*delta:800*delta ): 1200).toInt();

    _controller.duration = Duration(milliseconds: dynamicDuration);

    _animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            _buildHeader(context),
            const SizedBox(height: 30),
            
            // 使用你的動畫邏輯與自定義畫筆
            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      RoundedCircularProgressIndicator(
                        progress: _animation.value, // 動態進度
                        size: 250,
                        strokeWidth: 20,
                        backgroundColor: Colors.white12,
                        progressColor: Colors.greenAccent,
                      ),
                      Column(
                        children: [
                          
                          Text(
                            "${widget.steps}", 
                            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                          Text("目標: ${widget.stepGoal}", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 50),
            _buildStatsRow(),
            const SizedBox(height: 40),
            _buildActionButtons(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- 原有的 UI 組件封裝，讓 build 看起來更乾淨 ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("步數追蹤器", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.settings_input_component, color: Colors.white54),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        )
      ],
    );
  }

  Widget _buildStatsRow() {
    double distanceKm = (widget.steps * 0.7) / 1000;
    double caloriesKcal = widget.steps * 0.04;
    return Column(
      children: [
        _statCard("估算距離", distanceKm.toStringAsFixed(2), "km", Icons.straighten, Colors.blueAccent),
        const SizedBox(height: 12),
        _statCard("消耗熱量", caloriesKcal.toStringAsFixed(1), "kcal", Icons.local_fire_department, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: Column(
        children: [
          TextButton.icon(
            onPressed: widget.onReset,
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            label: const Text("重置步數", style: TextStyle(color: Colors.redAccent)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: widget.onAdd,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
            child: const Text("增加步數"),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 6),
                  Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


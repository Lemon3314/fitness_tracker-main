// screens/badge_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';


class BadgeScreen extends StatelessWidget {
  final int steps;

  const BadgeScreen({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    // 定義勳章資料，包含解鎖條件
    final List<Map<String, dynamic>> badgeData = [
      {"title": "初級步行者", "icon": Icons.directions_walk, "goal": 100, "color": Colors.brown},
      {"title": "中級跑步者", "icon": Icons.directions_run, "goal": 500, "color": Colors.grey},
      {"title": "高級單車手", "icon": Icons.directions_bike, "goal": 1000, "color": Colors.amber},
      {"title": "城市馬拉松", "icon": Icons.workspace_premium, "goal": 5000, "color": Colors.cyan},
      {"title": "運動大師", "icon": Icons.auto_awesome, "goal": 10000, "color": Colors.purpleAccent},
      {"title": "破萬神話", "icon": Icons.bolt, "goal": 20000, "color": Colors.redAccent},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 稍微深一點的黑色，更有質感
      appBar: AppBar(
        title: const Text("成就勳章", style: TextStyle(color: Colors.white70)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: badgeData.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 一行兩個
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85, // 調整方塊比例，讓下方留點空間給文字
          ),
          itemBuilder: (context, index) {
            final badge = badgeData[index];
            final bool isUnlocked = steps >= badge['goal'];

            // 使用我們自定義的互動勳章元件
            return InteractiveBadgeItem(
              title: badge['title'],
              icon: badge['icon'],
              goal: badge['goal'],
              baseColor: badge['color'],
              isUnlocked: isUnlocked,
            );
          },
        ),
      ),
    );
  }
}

// =========================================
// 第一部分：列表中的互動勳章 (壓下縮放邏輯)
// =========================================
class InteractiveBadgeItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final int goal;
  final Color baseColor;
  final bool isUnlocked;

  const InteractiveBadgeItem({
    super.key,
    required this.title,
    required this.icon,
    required this.goal,
    required this.baseColor,
    required this.isUnlocked,
  });

  @override
  State<InteractiveBadgeItem> createState() => _InteractiveBadgeItemState();
}

class _InteractiveBadgeItemState extends State<InteractiveBadgeItem> with SingleTickerProviderStateMixin {
  // 動畫控制器，用於處理壓下時的縮放
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化動畫，時長設短一點，反應才快
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // 縮放動畫：從 1.0 (原圖) 縮小到 0.93
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 透明度動畫：壓下時變暗一點 (1.0 -> 0.7)
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 顯示勳章詳情彈窗
  void _showDetail() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 關鍵：讓背景透明
        pageBuilder: (context, _, __) => BadgeDetailDialog(
          title: widget.title,
          icon: widget.icon,
          baseColor: widget.baseColor,
          isUnlocked: widget.isUnlocked,
        ),
        transitionsBuilder: (context, animation, _, child) {
          // 自定義頁面淡入動畫
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 GestureDetector 監聽手勢
    return GestureDetector(
      onTapDown: (_) => _controller.forward(), // 手指按下：開始動畫 (縮小變暗)
      onTapUp: (_) {
        _controller.reverse(); // 手指抬起：還原動畫
        _showDetail(); // 觸發詳情彈窗
      },
      onTapCancel: () => _controller.reverse(), // 滑動到外面取消：還原動畫
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 應用縮放和透明度矩陣
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        // 勳章的視覺主體
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // 卡片背景色
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (widget.isUnlocked) // 解鎖時才有發光陰影
                BoxShadow(
                  color: widget.baseColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 使用 Hero 動畫連結到詳情頁
              Hero(
                tag: 'badge_${widget.title}', // 唯一的 Tag
                child: BadgeVisual(
                  icon: widget.icon,
                  baseColor: widget.baseColor,
                  isUnlocked: widget.isUnlocked,
                  size: 80,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.isUnlocked ? Colors.white : Colors.white24,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${widget.goal} 步",
                style: TextStyle(
                  color: widget.isUnlocked ? widget.baseColor : Colors.white10,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================
// 第二部分：詳情彈窗 (Hero + 3D 互動效果)
// =========================================
class BadgeDetailDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color baseColor;
  final bool isUnlocked;

  const BadgeDetailDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.baseColor,
    required this.isUnlocked,
  });

  @override
  State<BadgeDetailDialog> createState() => _BadgeDetailDialogState();
}

// 這裡我們需要兩個 Ticker，一個給翻轉，一個給手勢還原
class _BadgeDetailDialogState extends State<BadgeDetailDialog> with TickerProviderStateMixin {
  // 入場時的 3D 翻轉動畫
  late AnimationController _entryController;
  late Animation<double> _flipAnimation;

  // [新增] 用於處理手勢放開後，平滑回正的控制器與動畫
  late AnimationController _tiltResetController;
  late Animation<double> _tiltXAnimation;
  late Animation<double> _tiltYAnimation;

  // 用於控制 3D 傾斜的角度 (這不是動畫，是根據手勢即時計算的)
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  final double _maxTiltAngle = 0.3; // 最大傾斜弧度

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 翻轉慢一點，比較華麗
    );

    // 翻轉：從 -0.5pi (側對使用者) 翻轉到 0 (正對)
    _flipAnimation = Tween<double>(begin: -1.57, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut), // 使用彈性曲線
    );

    // [新增] 初始化回正動畫控制器 (時間設短一點，反應更俐落)
    _tiltResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // [新增] 監聽回正動畫，即時更新傾斜角度並觸發畫面重繪
    _tiltResetController.addListener(() {
      setState(() {
        _tiltX = _tiltXAnimation.value;
        _tiltY = _tiltYAnimation.value;
      });
    });

    // 延遲一點點開始翻轉，等 Hero 動畫飛到位
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tiltResetController.dispose(); // [新增] 釋放回正控制器的資源，避免 Memory Leak
    super.dispose();
  }

  // 處理手勢滑動，計算傾斜角度
  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    _tiltResetController.stop(); // [新增] 如果動畫回正到一半，手指又摸上去，立刻停止回正

    setState(() {
      // 根據手指在螢幕上的相對位置計算 X 和 Y 的傾斜
      // offset.dx / width -> 得到 0~1 之間的比例，再轉為 -0.5 ~ 0.5，最後乘以最大角度
      _tiltY = ((details.localPosition.dx / size.width) - 0.5) * _maxTiltAngle * 2;
      _tiltX = ((details.localPosition.dy / size.height) - 0.5) * -_maxTiltAngle * 2; // Y軸反轉
    });
  }

  // 手指抬起，平滑還原
  void _handlePanEnd(DragEndDetails details) {
    // 這裡我們不用動畫控制器，直接用簡單的遞減，讓它看起來像有慣性 
    // [修改備註]：為了提升效能與避免掉幀，這裡已經將原本的 Timer 邏輯升級為原生的 Tween 動畫

    // [新增] 設定從「當前手指放開的角度」回到「0 (正中心)」的補間動畫
    _tiltXAnimation = Tween<double>(begin: _tiltX, end: 0.0).animate(
      CurvedAnimation(parent: _tiltResetController, curve: Curves.easeOutBack), // easeOutBack 會有一點彈性質感
    );
    _tiltYAnimation = Tween<double>(begin: _tiltY, end: 0.0).animate(
      CurvedAnimation(parent: _tiltResetController, curve: Curves.easeOutBack),
    );

    // [新增] 觸發回正動畫，確保每次都從頭開始播放
    _tiltResetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85), // 半透明黑色背景
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // 點擊任意處關閉
        onPanUpdate: (details) => _handlePanUpdate(details, size), // 監聽滑動
        onPanEnd: _handlePanEnd, // 監聽抬起
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 動畫核心：AnimatedBuilder
              AnimatedBuilder(
                animation: Listenable.merge([_entryController, _tiltResetController]), // [修改] 同時監聽進場與回正兩個動畫控制器
                builder: (context, child) {
                  // 組合兩個 Transform：一個是用於進場翻轉，一個是用於 3D 傾斜
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 關鍵：開啟透視效果，才有 3D 感
                      ..rotateY(_tiltY) // 手勢 Y 軸傾斜
                      ..rotateX(_tiltX + _flipAnimation.value), // 手勢 X 軸傾斜 + 進場翻轉
                    child: child,
                  );
                },
                child: Hero(
                  tag: 'badge_${widget.title}', // 唯一的 Tag，與列表對應
                  child: BadgeVisual(
                    icon: widget.icon,
                    baseColor: widget.baseColor,
                    isUnlocked: widget.isUnlocked,
                    size: 200, // 大圖尺寸
                    isDetail: true, // 告訴元件這是詳情模式
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // 下方文字資訊
              Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (widget.isUnlocked)
                const Text("🏆 已達成此成就！", style: TextStyle(color: Colors.greenAccent, fontSize: 18))
              else
                Text("🔒 尚缺部分步數即可解鎖", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
              const SizedBox(height: 80),
              const Text("(手指滑動勳章檢視 3D 效果)", style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// 簡單的計時器，用於平滑還原 3D 角度
// class Timer {
//   Timer.periodic(Duration duration, void Function(Timer timer) callback) {
//     _timer = java.util.Timer();
//     _timer.scheduleAtFixedRate(java.util.TimerTask(callback), 0, duration.inMilliseconds.toLong());
//   }
//   late java.util.Timer _timer;
//   void cancel() => _timer.cancel();
// }

// =========================================
// 第三部分：勳章視覺主體 (Premium 質感設計)
// =========================================
class BadgeVisual extends StatelessWidget {
  
  final IconData icon;
  final Color baseColor;
  final bool isUnlocked;
  final double size;
  final bool isDetail;

  const BadgeVisual({
    super.key,
    required this.icon,
    required this.baseColor,
    required this.isUnlocked,
    required this.size,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 1. 質感漸層 (金屬質感)
        // 修改 BadgeVisual 內的 gradient 部分
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isUnlocked
            ? [
                baseColor.withValues(alpha: 0.4),
                baseColor, // 主色
                baseColor.withValues(alpha: 0.2), 
              ]
            : [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.10), // ✅ 補上中間的過渡色，讓陣列長度保持為 3
                Colors.white.withValues(alpha: 0.15), 
              ],
        stops: const [0.1, 0.5, 0.9],
      ),
        // 2. 邊框
        border: Border.all(
          color: isUnlocked ? baseColor.withValues(alpha: 0.8) : Colors.white12,
          width: isDetail ? 8 : 4, // 詳情圖邊框變粗
        ),
        // 3. 質感陰影
        boxShadow: [
          // 內陰影 (營造凹陷感)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(2, 2),
            spreadRadius: -2,
          ),
          if (isUnlocked) // 外發光
            BoxShadow(
              color: baseColor.withValues(alpha: 0.6),
              blurRadius: isDetail ? 40 : 15,
              spreadRadius: isDetail ? 5 : 0,
            )
        ],
      ),
      child: Center(
        // 對 Icon 也要應用陰影，營造雕刻感
        child: Icon(
          icon,
          color: isUnlocked ? Colors.white : Colors.white10,
          size: size * 0.5, // 圖示大小為勳章的一半
          shadows: [
            if (isUnlocked)
              Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(2, 2), blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
// screens/badge_screen.dart
import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF121212), // 深色質感背景
      appBar: AppBar(
        title: const Text("成就勳章", style: TextStyle(color: Colors.white70)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: badgeData.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 一行兩個
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85, // 方塊比例
          ),
          itemBuilder: (context, index) {
            final badge = badgeData[index];
            final bool isUnlocked = steps >= badge['goal'];

            // 互動勳章元件
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
// 第一部分：列表中的互動勳章 (保留壓下縮放邏輯)
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // 反應快一點
    );

    // 縮放動畫：從 1.0 縮小到 0.93
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 透明度動畫：壓下時微微變暗
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
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
        opaque: false, // 讓背景透明，看得到下方頁面
        barrierDismissible: true, // 點擊背景可關閉
        barrierColor: Colors.black.withOpacity(0.8), // 背景遮罩顏色
        pageBuilder: (context, _, __) => BadgeDetailDialog(
          title: widget.title,
          icon: widget.icon,
          baseColor: widget.baseColor,
          isUnlocked: widget.isUnlocked,
        ),
        transitionsBuilder: (context, animation, _, child) {
          // 簡單的淡入動畫
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // [功能] 監聽手勢實現壓下反饋
      onTapDown: (_) => _controller.forward(), // 按下：變小
      onTapUp: (_) {
        _controller.reverse(); // 抬起：還原
        _showDetail(); // 觸發詳情
      },
      onTapCancel: () => _controller.reverse(), // 取消：還原

      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value, // 應用縮放
            child: Opacity(
              opacity: _opacityAnimation.value, // 應用透明度
              child: child,
            ),
          );
        },

        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (widget.isUnlocked) // 解鎖時有發光陰影
                BoxShadow(
                  color: widget.baseColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
            ],
          ),
          
          child: Column(
            mainAxisAlignment:MainAxisAlignment.center,
            children: [
              //[功能] Hero 動畫 - 起點
                Hero(
                tag: 'badge_${widget.title}', // 唯一的 Tag
                child: 
                BadgeVisual(
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
                  color: widget.isUnlocked ? widget.baseColor.withOpacity(0.8) : Colors.white10,
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
// 第二部分：詳情彈窗 (簡化版 - 只有 Hero 飛入)
// =========================================
class BadgeDetailDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 這裡改用 StatelessWidget，因為不需要處理手勢動畫狀態了
    return Scaffold(
      backgroundColor: Colors.transparent, // 背景已在 PageRouteBuilder 設定
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // 點擊任意處關閉彈窗
        child: Container(
          color: Colors.transparent, // 確保整個螢幕都能接收點擊
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // [功能] Hero 動畫 - 終點
                Hero(
                  tag: 'badge_$title', // 與起點相同的 Tag
                  child: BadgeVisual(
                    icon: icon,
                    baseColor: baseColor,
                    isUnlocked: isUnlocked,
                    size: 220, // 放大尺寸
                    isDetail: true, // 詳情模式啟用更強的光影
                  ),
                ),
                const SizedBox(height: 40),
                // 下方文字資訊
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
                const SizedBox(height: 10),
                if (isUnlocked)
                  const Text("🏆 已達成此成就！", style: TextStyle(color: Colors.greenAccent, fontSize: 18))
                else
                  Text(
                    "🔒 未解鎖",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                  ),
                const SizedBox(height: 100), // 留白，讓視覺集中在中間
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================
// 第三部分：勳章視覺主體 (保持 Premium 質感)
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
    // 為了讓 Hero 動畫過程中的材質不閃爍，這裡的 Container 屬性盡量保持單純
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 質感漸層
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
              ? [
                  baseColor.withOpacity(0.6),
                  baseColor,
                  baseColor.withOpacity(0.4),
                ]
              : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.15),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
        // 邊框
        border: Border.all(
          color: isUnlocked ? baseColor.withOpacity(0.8) : Colors.white12,
          width: isDetail ? 6 : 3, // 詳情圖邊框變粗
        ),
        // 質感陰影
        boxShadow: [
          // 內陰影效果 (用黑色的、blur 較小的 shadow 模擬)
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          if (isUnlocked) // 外發光
            BoxShadow(
              color: baseColor.withOpacity(0.5),
              blurRadius: isDetail ? 40 : 10,
              spreadRadius: isDetail ? 5 : 0,
            )
        ],
      ),
      child: Material( // 加上 Material 確保 Icon 的 Hero 動畫順暢
        type: MaterialType.transparency,
        child: Center(
          child: Icon(
            icon,
            color: isUnlocked ? Colors.white : Colors.white10,
            size: size * 0.5,
            shadows: [
              if (isUnlocked)
                Shadow(color: Colors.black.withOpacity(0.3), offset: const Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}
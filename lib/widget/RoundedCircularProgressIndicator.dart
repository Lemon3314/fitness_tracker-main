import 'dart:math' as math;
import 'package:flutter/material.dart';

class RoundedCircularProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const RoundedCircularProgressIndicator({
    super.key,
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoundedCircularProgressPainter(
          progress: progress,
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          progressColor: progressColor,
        ),
      ),
    );
  }
}

class _RoundedCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _RoundedCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // 讓進度條兩端變圓角的關鍵

    // 1. 畫最底層的背景圓環
    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    if (progress <= 0) return;

    // 計算已經完成了幾個「完整圈」以及「當前圈的剩餘進度」
    int laps = progress.floor();
    double remainder = progress - laps;

    // 處理進度剛好是整數圈的情況 (例如 progress = 1.0 或 2.0)
    if (progress > 0 && remainder == 0.0) {
      laps -= 1;
      remainder = 1.0;
    }

    final double startAngle = -math.pi / 2;

    // 2. 如果進度超過一圈 (laps > 0)，先畫出一圈完整的底層進度
    if (laps > 0) {
      // 這裡畫出完整的底環，不需要端點圓角，所以直接給 2 * pi
      canvas.drawArc(rect, startAngle, math.pi * 2, false, progressPaint);
    }

    // 3. 畫「當前這一圈」的覆蓋進度與立體陰影
    if (remainder > 0.0) {
      double currentAngle = startAngle + remainder * math.pi * 2;
      double sweepAngle = remainder * math.pi * 2;

      // 【Flutter 繪圖小技巧】
      // 如果 sweepAngle 剛好等於 2 * pi，Flutter 會自動把它畫成一個「沒有圓角端點」的封閉圓。
      // 所以我們故意減去極小的值，強迫它畫出 StrokeCap.round 的圓角端點。
      if (sweepAngle >= math.pi * 2) {
        sweepAngle = math.pi * 2 - 0.001;
      }

      // 當進度大於一圈，或者剛好等於一圈時，在進度條「頭部」畫一個陰影
      if (laps > 0 || remainder == 1.0) {
        double headX = center.dx + radius * math.cos(currentAngle);
        double headY = center.dy + radius * math.sin(currentAngle);

        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 1) // 陰影顏色與透明度
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0); // 模糊效果

        // 在進度條端點正下方畫一個小圓點當作陰影
        canvas.drawCircle(Offset(headX, headY), strokeWidth / 2, shadowPaint);
      }

      // 最後畫上當前進度的弧線 (這條弧線會覆蓋在陰影之上，讓陰影只從邊緣透出來)
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_RoundedCircularProgressPainter oldDelegate) {
    // 最佳實踐：確保所有影響外觀的變數改變時都會重繪
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
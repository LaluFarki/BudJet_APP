import 'dart:math';
import 'package:flutter/material.dart';

class DonutSegment {
  final double percentage; // 0.0 - 1.0
  final Color color;

  const DonutSegment({
    required this.percentage,
    required this.color,
  });
}

class BudgetDonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String totalText;
  final double size;

  const BudgetDonutChart({
    super.key,
    required this.segments,
    required this.totalText,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              segments: segments,
              strokeWidth: 26,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalText,
                style: const TextStyle(
                  color: Color(0xFF1E1E1E), // textDark
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;

  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // Mulai dari atas (jam 12)

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = segment.percentage * 2 * pi;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round; // Ujung membulat

      // Untuk memberikan jarak (gap) antar potongan, kurangi sweepAngle sedikit
      // Namun karena strokeCap.round membuat ujungnya melebihi sudut asli, 
      // gapnya perlu lumayan besar atau kita pakai cara khusus.
      // Di sini kita pakai cara sederhana: beri sedikit jarak
      final adjustedSweep = sweepAngle > 0.05 ? sweepAngle - 0.15 : sweepAngle; 
      
      canvas.drawArc(
        rect,
        startAngle + 0.075, // Geser sedikit agar ada gap awalan
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

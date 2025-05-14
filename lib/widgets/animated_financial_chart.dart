import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/enhanced_animations.dart';
import '../themes/app_theme.dart';

/// An animated line chart for financial data visualization
class AnimatedLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final double height;
  final bool showGradient;
  final Color lineColor;
  final String? label;
  final bool animate;

  const AnimatedLineChart({
    super.key,
    required this.dataPoints,
    this.height = 120,
    this.showGradient = true,
    this.lineColor = AppTheme.primaryColor,
    this.label,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart = SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          dataPoints: dataPoints,
          lineColor: lineColor,
          showGradient: showGradient,
          animationProgress: animate ? 0 : 1.0, // Start with 0 progress if animating
        ),
        size: Size.infinite,
      ),
    );

    // Apply animation if requested
    if (animate) {
      chart = chart
          .animate()
          .custom(
            duration: EnhancedAnimations.standardDuration,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _LineChartPainter(
                  dataPoints: dataPoints,
                  lineColor: lineColor,
                  showGradient: showGradient,
                  animationProgress: value,
                ),
                size: Size(double.infinity, height),
              );
            },
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[  
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        chart,
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final bool showGradient;
  final double animationProgress;

  _LineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.showGradient,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    // Find min and max values for scaling
    final double minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final double maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final double range = (maxValue - minValue) == 0 ? 1 : (maxValue - minValue);

    // Calculate horizontal and vertical spacing
    final double horizontalSpacing = size.width / (dataPoints.length - 1);
    // Add some padding at the top and bottom
    final double verticalPadding = size.height * 0.1;
    final double availableHeight = size.height - (2 * verticalPadding);

    // Create path for the line
    final path = Path();
    final List<Offset> points = [];

    // Calculate points based on animation progress
    final int pointsToShow = (dataPoints.length * animationProgress).round();

    for (int i = 0; i < pointsToShow; i++) {
      final double x = i * horizontalSpacing;
      final double normalizedValue = (dataPoints[i] - minValue) / range;
      final double y = size.height - verticalPadding - (normalizedValue * availableHeight);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw gradient if requested
    if (showGradient && points.isNotEmpty) {
      final gradientPath = Path();
      gradientPath.addPath(path, Offset.zero);
      gradientPath.lineTo(points.last.dx, size.height);
      gradientPath.lineTo(0, size.height);
      gradientPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      );

      final gradientPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(gradientPath, gradientPaint);
    }

    // Draw dots at each data point
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showGradient != showGradient;
  }
}

/// An animated bar chart for financial data visualization
class AnimatedBarChart extends StatelessWidget {
  final List<BarChartEntry> data;
  final double height;
  final bool animate;
  final String? label;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.animate = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart = SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BarChartPainter(
          data: data,
          animationProgress: animate ? 0 : 1.0,
          textColor: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
        ),
        size: Size.infinite,
      ),
    );

    // Apply animation if requested
    if (animate) {
      chart = chart
          .animate()
          .custom(
            duration: EnhancedAnimations.standardDuration,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _BarChartPainter(
                  data: data,
                  animationProgress: value,
                  textColor: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                ),
                size: Size(double.infinity, height),
              );
            },
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[  
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        chart,
      ],
    );
  }
}

class BarChartEntry {
  final String label;
  final double value;
  final Color color;

  BarChartEntry({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartEntry> data;
  final double animationProgress;
  final Color textColor;

  _BarChartPainter({
    required this.data,
    required this.animationProgress,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double barWidth = size.width / data.length - 16; // Leave some spacing
    final textStyle = TextStyle(color: textColor, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw bars and labels
    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final barHeight = size.height * 0.75 * (entry.value / maxValue) * animationProgress;
      final startX = i * (size.width / data.length) + 8; // Center each bar

      // Draw bar
      final barPaint = Paint()
        ..color = entry.color
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            entry.color,
            entry.color.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromLTWH(
          startX,
          size.height - barHeight,
          barWidth,
          barHeight,
        ));

      // Draw rounded rectangle for bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX,
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);

      // Draw label below bar
      textPainter.text = TextSpan(text: entry.label, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          startX + (barWidth / 2) - (textPainter.width / 2),
          size.height - barHeight - 16,
        ),
      );

      // Draw value on top of bar
      textPainter.text = TextSpan(
        text: entry.value.toStringAsFixed(0),
        style: textStyle.copyWith(fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          startX + (barWidth / 2) - (textPainter.width / 2),
          size.height - barHeight - 30,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.data != data;
  }
}

/// A circular progress chart with animation
class AnimatedCircularChart extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final Color color;
  final Color backgroundColor;
  final String label;
  final bool animate;
  final Widget? centerWidget;

  const AnimatedCircularChart({
    super.key,
    required this.value,
    required this.label,
    this.size = 150,
    this.color = AppTheme.primaryColor,
    this.backgroundColor = Colors.grey,
    this.animate = true,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _CircularChartPainter(
              value: animate ? 0 : value,
              color: color,
              backgroundColor: backgroundColor.withValues(alpha: 0.2),
            ),
            size: Size.square(size),
          ),
          // Center content
          centerWidget ?? Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: size / 5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    // Apply animation if requested
    if (animate) {
      chart = chart
          .animate()
          .custom(
            duration: EnhancedAnimations.standardDuration,
            curve: Curves.easeOutQuad,
            builder: (context, progress, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: _CircularChartPainter(
                      value: value * progress,
                      color: color,
                      backgroundColor: backgroundColor.withValues(alpha: 0.2),
                    ),
                    size: Size.square(size),
                  ),
                  // Animated text
                  Text(
                    '${((value * progress) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: size / 5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              );
            },
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        chart,
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;

  _CircularChartPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10; // Leave some padding
    const startAngle = -90 * (3.14159 / 180); // Start from the top (in radians)
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
      
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
      
    final sweepAngle = value * 2 * 3.14159; // Full circle is 2*pi radians
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularChartPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

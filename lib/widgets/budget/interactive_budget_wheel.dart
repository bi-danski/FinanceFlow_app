import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

import '../../models/budget_model.dart';

class InteractiveBudgetWheel extends StatefulWidget {
  final List<Budget> budgets;
  final Function(String category, double newAmount) onBudgetChanged;
  final double totalBudget;

  const InteractiveBudgetWheel({
    super.key,
    required this.budgets,
    required this.onBudgetChanged,
    required this.totalBudget,
  });

  @override
  State<InteractiveBudgetWheel> createState() => _InteractiveBudgetWheelState();
}

class _InteractiveBudgetWheelState extends State<InteractiveBudgetWheel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _selectedSegmentIndex;
  double _startDragAngle = 0.0;
  double _currentDragValue = 0.0;
  bool _isDragging = false;
  
  // Colors for budget segments
  final List<Color> _segmentColors = [
    Colors.blue.shade400,
    Colors.purple.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.red.shade400,
    Colors.teal.shade400,
    Colors.indigo.shade400,
    Colors.pink.shade400,
    Colors.amber.shade400,
    Colors.cyan.shade400,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to get segment color based on index
  // Currently used in CustomPainter directly

  void _handlePanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPosition = details.localPosition;
    final touchVector = touchPosition - center;
    final touchAngle = _calculateAngle(touchVector);
    
    setState(() {
      _startDragAngle = touchAngle;
      _isDragging = true;
      
      // Determine which segment was touched
      _selectedSegmentIndex = _getSegmentIndexAtAngle(touchAngle);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_selectedSegmentIndex == null) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final touchPosition = details.localPosition;
    final touchVector = touchPosition - center;
    final currentAngle = _calculateAngle(touchVector);
    
    // Calculate angle change
    double angleDelta = currentAngle - _startDragAngle;
    
    // Adjust for crossing the 0/360 boundary
    if (angleDelta > 180) {
      angleDelta -= 360;
    } else if (angleDelta < -180) {
      angleDelta += 360;
    }
    
    // Convert to budget change (scale factor can be adjusted)
    final scaleFactor = widget.totalBudget / 360 * 3; // Adjust sensitivity
    final budgetDelta = angleDelta * scaleFactor;
    
    setState(() {
      _currentDragValue = budgetDelta;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectedSegmentIndex == null) return;
    
    final selectedBudget = widget.budgets[_selectedSegmentIndex!];
    final newAmount = (selectedBudget.amount + _currentDragValue).clamp(10.0, widget.totalBudget * 0.8);
    
    // Trigger haptic-like animation
    _animationController.reset();
    _animationController.forward();
    
    // Call the callback to update the budget
    widget.onBudgetChanged(selectedBudget.category, newAmount);
    
    setState(() {
      _isDragging = false;
      _selectedSegmentIndex = null;
      _currentDragValue = 0.0;
    });
  }

  double _calculateAngle(Offset vector) {
    // Convert to degrees and ensure it's 0-360
    final degrees = (vector_math.degrees(atan2(vector.dy, vector.dx)) + 360) % 360;
    return degrees;
  }

  int? _getSegmentIndexAtAngle(double angle) {
    if (widget.budgets.isEmpty) return null;
    
    double currentAngle = 0;
    for (int i = 0; i < widget.budgets.length; i++) {
      final segmentAngle = (widget.budgets[i].amount / widget.totalBudget) * 360;
      if (angle >= currentAngle && angle < currentAngle + segmentAngle) {
        return i;
      }
      currentAngle += segmentAngle;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Using the available space for the wheel
        
        return GestureDetector(
          onPanStart: (details) => _handlePanStart(details, size),
          onPanUpdate: (details) => _handlePanUpdate(details, size),
          onPanEnd: _handlePanEnd,
          child: CustomPaint(
            size: size,
            painter: BudgetWheelPainter(
              budgets: widget.budgets,
              totalBudget: widget.totalBudget,
              segmentColors: _segmentColors,
              selectedIndex: _selectedSegmentIndex,
              animationValue: _animationController.value,
              isDragging: _isDragging,
              currentDragValue: _currentDragValue,
            ),
          ),
        );
      },
    );
  }
}

class BudgetWheelPainter extends CustomPainter {
  final List<Budget> budgets;
  final double totalBudget;
  final List<Color> segmentColors;
  final int? selectedIndex;
  final double animationValue;
  final bool isDragging;
  final double currentDragValue;

  BudgetWheelPainter({
    required this.budgets,
    required this.totalBudget,
    required this.segmentColors,
    required this.selectedIndex,
    required this.animationValue,
    required this.isDragging,
    required this.currentDragValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(center.dx, center.dy) * 0.85;
    
    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, shadowPaint);
    
    // Set up segment parameters
    final segmentPaint = Paint()..style = PaintingStyle.fill;
    double startAngle = -90 * (pi / 180); // Start from top (in radians)
    
    // Draw each budget segment
    for (int i = 0; i < budgets.length; i++) {
      final budget = budgets[i];
      double segmentAmount = budget.amount;
      
      // If this is the selected segment being dragged, show preview of change
      if (isDragging && selectedIndex == i) {
        segmentAmount += currentDragValue;
        segmentAmount = segmentAmount.clamp(10.0, totalBudget * 0.8);
      }
      
      final sweepAngle = (segmentAmount / totalBudget) * 2 * pi;
      
      // Determine segment appearance
      final isSelected = selectedIndex == i;
      final segmentRadius = radius * (isSelected ? 1.05 : 1.0);
      
      // Segment color with animation effects
      Color segmentColor = segmentColors[i % segmentColors.length];
      if (isSelected) {
        // Pulse effect for selected segment
        final pulseValue = (sin(animationValue * pi * 2) * 0.1) + 0.9;
        segmentColor = segmentColor.withValues(alpha: 0.9 * pulseValue);
      }
      
      segmentPaint.color = segmentColor;
      
      // Draw the segment
      final segmentRect = Rect.fromCircle(
        center: center,
        radius: segmentRadius,
      );
      canvas.drawArc(
        segmentRect,
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );
      
      // Add border for better separation between segments
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        segmentRect,
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // Draw category label in the middle of each segment
      final labelAngle = startAngle + (sweepAngle / 2);
      final labelRadius = segmentRadius * 0.7;
      final labelPosition = center + Offset(
        cos(labelAngle) * labelRadius,
        sin(labelAngle) * labelRadius,
      );
      
      final textStyle = TextStyle(
        color: Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: isSelected ? 14 : 12,
        shadows: [
          Shadow(blurRadius: 3, color: Colors.black.withValues(alpha: 0.5)),
        ],
      );
      
      final textSpan = TextSpan(
        text: budget.category,
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        labelPosition - Offset(textPainter.width / 2, textPainter.height / 2),
      );
      
      // Update start angle for next segment
      startAngle += sweepAngle;
    }
    
    // Draw inner circle
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.3, innerCirclePaint);
    
    // Draw total budget in center
    final totalText = '\$${totalBudget.toStringAsFixed(0)}';
    final totalTextStyle = TextStyle(
      color: Colors.black.withValues(alpha: 0.8),
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );
    
    final totalTextSpan = TextSpan(
      text: totalText,
      style: totalTextStyle,
    );
    
    final totalTextPainter = TextPainter(
      text: totalTextSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    totalTextPainter.layout();
    totalTextPainter.paint(
      canvas,
      center - Offset(totalTextPainter.width / 2, totalTextPainter.height / 2),
    );
    
    // Draw "Total" label
    final labelText = 'Total Budget';
    final labelTextStyle = TextStyle(
      color: Colors.black.withValues(alpha: 0.6),
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
    
    final labelTextSpan = TextSpan(
      text: labelText,
      style: labelTextStyle,
    );
    
    final labelTextPainter = TextPainter(
      text: labelTextSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    labelTextPainter.layout();
    labelTextPainter.paint(
      canvas,
      center - Offset(labelTextPainter.width / 2, -totalTextPainter.height / 2 - 5),
    );
  }

  @override
  bool shouldRepaint(covariant BudgetWheelPainter oldDelegate) {
    return oldDelegate.budgets != budgets ||
           oldDelegate.totalBudget != totalBudget ||
           oldDelegate.selectedIndex != selectedIndex ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.currentDragValue != currentDragValue;
  }
}

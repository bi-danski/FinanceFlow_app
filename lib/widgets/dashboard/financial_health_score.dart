import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/enhanced_animations.dart';
import '../../widgets/animated_progress_indicator.dart';

/// A visual representation of the user's overall financial health
/// with key contributing metrics and improvement suggestions
class FinancialHealthScoreCard extends StatelessWidget {
  final double score; // 0-100 financial health score
  final List<ScoreMetric> contributingMetrics;
  final double? previousScore; // Previous period score for comparison
  final VoidCallback? onImproveScore;

  const FinancialHealthScoreCard({
    super.key,
    required this.score,
    required this.contributingMetrics,
    this.previousScore,
    this.onImproveScore,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate score difference for trend indicator
    final scoreDiff = previousScore != null ? score - previousScore! : 0.0;
    final hasTrend = previousScore != null;
    
    // Color gradient based on score
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green.shade700;
    } else if (score >= 60) {
      scoreColor = Colors.blue.shade700;
    } else if (score >= 40) {
      scoreColor = Colors.amber.shade700;
    } else if (score >= 20) {
      scoreColor = Colors.orange.shade700;
    } else {
      scoreColor = Colors.red.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Health',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (hasTrend)
                  _buildTrendIndicator(context, scoreDiff),
              ],
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // Main content with score circle and metrics
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Health score circular indicator
                AnimatedCircularProgressIndicator(
                  progress: score / 100,
                  size: 120,
                  primaryColor: scoreColor,
                  strokeWidth: 12,
                  centerText: score.toInt().toString(),
                  label: _getScoreLabel(score),
                  animationDelayMs: 300,
                ),
                
                const SizedBox(width: 16),
                
                // Contributing metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contributing Factors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        contributingMetrics.length > 3 ? 3 : contributingMetrics.length,
                        (index) => _buildMetricItem(context, contributingMetrics[index], index),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Action button
            if (onImproveScore != null) ...[
              const SizedBox(height: 20),
              Center(
                child: EnhancedAnimations.animatedButton(
                  ElevatedButton.icon(
                    onPressed: onImproveScore,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Improve Score'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scoreColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  delayMillis: 800,
                ),
              ),
            ],
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .moveY(begin: 30, end: 0, curve: Curves.easeOutQuint);
  }

  Widget _buildTrendIndicator(BuildContext context, double scoreDiff) {
    final isPositive = scoreDiff > 0;
    final isNeutral = scoreDiff == 0;
    final color = isPositive ? Colors.green.shade700 : isNeutral ? Colors.grey : Colors.red.shade700;
    final icon = isPositive ? Icons.trending_up : isNeutral ? Icons.trending_flat : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${scoreDiff.abs().toStringAsFixed(1)} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    )
    .animate(delay: const Duration(milliseconds: 600))
    .fadeIn()
    .shimmer(color: color.withValues(alpha: 0.3));
  }

  Widget _buildMetricItem(BuildContext context, ScoreMetric metric, int index) {
    final Color metricColor;
    
    // Set color based on metric score
    if (metric.score >= 80) {
      metricColor = Colors.green.shade700;
    } else if (metric.score >= 60) {
      metricColor = Colors.blue.shade700;
    } else if (metric.score >= 40) {
      metricColor = Colors.amber.shade700;
    } else if (metric.score >= 20) {
      metricColor = Colors.orange.shade700;
    } else {
      metricColor = Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: metricColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      metric.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${metric.score.toInt()}/100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: metricColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: metric.score / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(metricColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate(delay: Duration(milliseconds: 500 + (index * 100)))
    .fadeIn()
    .slideX(begin: 0.1, end: 0);
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
}

/// Model class for score contributing metrics
class ScoreMetric {
  final String id;
  final String name;
  final double score; // 0-100 score for this metric
  final String? description;
  final double? previousScore; // For trend calculation

  const ScoreMetric({
    required this.id,
    required this.name,
    required this.score,
    this.description,
    this.previousScore,
  });
}

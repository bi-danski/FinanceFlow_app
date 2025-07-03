import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/goal_model.dart';
import '../../themes/app_theme.dart';
import '../../viewmodels/goal_viewmodel.dart';

class GoalDetailsScreen extends StatelessWidget {
  final Goal goal;
  const GoalDetailsScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFmt = DateFormat('MMM dd, yyyy');
    final double progress = goal.progressPercentage.clamp(0, 100).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency.format(goal.currentAmount),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            Text('of ${currency.format(goal.targetAmount)}'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor(progress)),
            ),
            const SizedBox(height: 8),
            Text('${progress.toStringAsFixed(1)}% completed'),
            const SizedBox(height: 24),
            if (goal.description?.isNotEmpty == true) ...[
              Text('Description', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(goal.description!),
              const SizedBox(height: 16),
            ],
            if (goal.targetDate != null) ...[
              Text('Target date: ${dateFmt.format(goal.targetDate!)}'),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Funds'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final amount = await _showAmountDialog(context);
                  if (amount == null || amount <= 0) return; // nothing to add
                  // ignore: use_build_context_synchronously
                  final vm = context.read<GoalViewModel>();
                  await vm.updateGoalProgress(goal, amount);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _progressColor(double progress) {
    if (progress < 30) return AppTheme.errorColor;
    if (progress < 70) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  Future<double?> _showAmountDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add funds'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '', labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            final val = double.tryParse(ctrl.text.trim());
            Navigator.pop(ctx, val);
          }, child: const Text('Add')),
        ],
      ),
    );
    return result;
  }
}

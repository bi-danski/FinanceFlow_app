import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class AddGoalButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddGoalButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Add Goal'),
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
    );
  }
}

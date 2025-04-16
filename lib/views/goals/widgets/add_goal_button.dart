import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class AddGoalButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddGoalButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

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

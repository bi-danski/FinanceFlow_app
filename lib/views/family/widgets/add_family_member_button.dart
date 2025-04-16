import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class AddFamilyMemberButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddFamilyMemberButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add),
      label: const Text('Add Member'),
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
    );
  }
}

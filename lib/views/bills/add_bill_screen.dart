import 'package:flutter/material.dart';

/// Minimal placeholder screen for adding a new bill / recurring payment.
/// This keeps navigation from Quick Actions functional until a full feature
/// is implemented.
class AddBillScreen extends StatelessWidget {
  const AddBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill')),
      body: const Center(
        child: Text(
          'Add Bill screen coming soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

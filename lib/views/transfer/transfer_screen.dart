import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromAccount;
  String? _toAccount;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  List<String> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final transactions = await TransactionService.instance.getRecentTransactions(100);
    final set = <String>{};
    for (final t in transactions) {
      if (t.fromAccount?.isNotEmpty ?? false) set.add(t.fromAccount!);
      if (t.toAccount?.isNotEmpty ?? false) set.add(t.toAccount!);
    }
    setState(() => _accounts = set.toList());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccount == _toAccount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accounts must differ')));
      return;
    }
    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final amount = double.parse(_amountController.text);
    final service = TransactionService.instance;

    final outTx = TransactionModel(
      title: 'Transfer to $_toAccount',
      amount: -amount,
      date: _date,
      category: 'Transfer',
      type: TransactionType.transfer,
      fromAccount: _fromAccount,
      toAccount: _toAccount,
      userId: userId,
      notes: _noteController.text,
      isSynced: false,
      status: TransactionStatus.completed,
    );
    final inTx = TransactionModel(
      title: 'Transfer from $_fromAccount',
      amount: amount,
      date: _date,
      category: 'Transfer',
      type: TransactionType.transfer,
      fromAccount: _fromAccount,
      toAccount: _toAccount,
      userId: userId,
      notes: _noteController.text,
      isSynced: false,
      status: TransactionStatus.completed,
    );

    final ok1 = await service.addTransaction(outTx);
    final ok2 = await service.addTransaction(inTx);
    setState(() => _isSaving = false);
    if (ok1 != null && ok2 != null && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _fromAccount,
                      decoration: const InputDecoration(labelText: 'From Account'),
                      items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _fromAccount = v),
                      validator: (v) => v == null || v.isEmpty ? 'Select account' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _toAccount,
                      decoration: const InputDecoration(labelText: 'To Account'),
                      items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _toAccount = v),
                      validator: (v) => v == null || v.isEmpty ? 'Select account' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid amount' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text('Date: ${DateFormat.yMMMd().format(_date)}')),
                        TextButton(onPressed: _pickDate, child: const Text('Select')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _save, child: const Text('Save Transfer')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

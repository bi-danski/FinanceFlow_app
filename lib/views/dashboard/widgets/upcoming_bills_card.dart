import 'package:provider/provider.dart';
import 'package:financeflow_app/viewmodels/bill_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financeflow_app/utils/formatters.dart'; // Assuming you have formatters here
import 'package:financeflow_app/models/bill_model.dart';
import 'package:financeflow_app/constants/app_constants.dart'; // For routes

class UpcomingBillsCard extends StatefulWidget {
  const UpcomingBillsCard({super.key});

  @override
  State<UpcomingBillsCard> createState() => _UpcomingBillsCardState();
}

class _UpcomingBillsCardState extends State<UpcomingBillsCard> {
  late Future<List<Bill>> _upcomingBillsFuture;
  BillViewModel? _billViewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = Provider.of<BillViewModel>(context, listen: false);
    if (_billViewModel != vm) {
      _billViewModel = vm;
      _upcomingBillsFuture = _billViewModel!.getUpcomingBills(limit: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bill>>(
      future: _upcomingBillsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading upcoming bills: ${snapshot.error}'),
            )
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Bills',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 40, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 8),
                        Text('No upcoming bills found.', style: TextStyle(color: Theme.of(context).disabledColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bills = snapshot.data!;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Bills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (bills.length > 3) // Or some other logic if you want 'View All' always
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppConstants.scheduledPaymentsRoute);
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final dueDate = bill.dueDate;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
                      title: Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(dueDate)}'),
                      trailing: Text(
                        Formatters.formatCurrency(bill.amount, context),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.transactionDetailsRoute,
                          arguments: bill.id,
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

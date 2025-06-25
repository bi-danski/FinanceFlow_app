import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BillReminder {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isPaid;

  const BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.isPaid = false,
  });
}

class BillRemindersCard extends StatelessWidget {
  final List<BillReminder> bills;
  final bool isLoading;
  final Function(BillReminder) onMarkAsPaid;
  final Function() onViewAllBills;
  
  const BillRemindersCard({
    super.key,
    required this.bills,
    this.isLoading = false,
    required this.onMarkAsPaid,
    required this.onViewAllBills,
  });

  @override
  Widget build(BuildContext context) {
    // Sort bills by due date (closest first)
    final sortedBills = [...bills]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    // Filter upcoming bills (due in the next 30 days and not paid)
    final upcomingBills = sortedBills.where((bill) => 
      !bill.isPaid && 
      bill.dueDate.difference(DateTime.now()).inDays <= 30
    ).toList();
    
    return Card(
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All'),
                  onPressed: onViewAllBills,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (upcomingBills.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming bills due',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingBills.length > 5 ? 5 : upcomingBills.length,
                itemBuilder: (context, index) {
                  final bill = upcomingBills[index];
                  final daysUntilDue = bill.dueDate.difference(DateTime.now()).inDays;
                  
                  // Determine urgency color
                  Color statusColor;
                  if (daysUntilDue < 0) {
                    statusColor = Colors.red; // Overdue
                  } else if (daysUntilDue <= 3) {
                    statusColor = Colors.orange; // Due soon
                  } else if (daysUntilDue <= 7) {
                    statusColor = Colors.amber; // Due this week
                  } else {
                    statusColor = Colors.green; // Due later
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Theme.of(context).cardColor.withValues(alpha: 179),  // 0.7 * 255 = 179
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 51),  // 0.2 * 255 = 51
                        child: Icon(
                          Icons.calendar_today,
                          color: statusColor,
                        ),
                      ),
                      title: Text(
                        bill.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due: ${DateFormat.MMMd().format(bill.dueDate)}',
                          ),
                          Text(
                            _getDueStatusText(daysUntilDue),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${bill.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => onMarkAsPaid(bill),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Pay'),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ).animate()
                    .fadeIn(delay: Duration(milliseconds: index * 100))
                    .slideX(begin: index.isEven ? -0.1 : 0.1, end: 0);
                },
              ),
            if (upcomingBills.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: TextButton(
                    onPressed: onViewAllBills,
                    child: Text('+ ${upcomingBills.length - 5} more bills'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0);
  }
  
  String _getDueStatusText(int daysUntilDue) {
    if (daysUntilDue < 0) {
      return 'Overdue by ${-daysUntilDue} days';
    } else if (daysUntilDue == 0) {
      return 'Due today!';
    } else if (daysUntilDue == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }
}

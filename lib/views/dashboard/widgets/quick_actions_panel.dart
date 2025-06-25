import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuickActionsPanel extends StatefulWidget {
  final List<String> recentPayees;
  final Function(String action) onActionSelected;
  final Function(String payee) onPayeeSelected;
  
  const QuickActionsPanel({
    super.key,
    required this.recentPayees,
    required this.onActionSelected,
    required this.onPayeeSelected,
  });

  @override
  State<QuickActionsPanel> createState() => _QuickActionsPanelState();
}

class _QuickActionsPanelState extends State<QuickActionsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> quickActions = [
      {
        'icon': Icons.add_circle_outline,
        'color': Colors.green,
        'label': 'Add Expense',
        'action': 'add_expense',
      },
      {
        'icon': Icons.arrow_upward,
        'color': Colors.blue,
        'label': 'Add Income',
        'action': 'add_income',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'color': Colors.purple,
        'label': 'Transfer',
        'action': 'transfer',
      },
      {
        'icon': Icons.list_alt,
        'color': Colors.orange,
        'label': 'New Budget',
        'action': 'new_budget',
      },
      {
        'icon': Icons.flag_outlined,
        'color': Colors.teal,
        'label': 'New Goal',
        'action': 'new_goal',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'color': Colors.indigo,
        'label': 'New Bill',
        'action': 'new_bill',
      },
    ];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Actions'),
              Tab(text: 'Recent Payees'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          SizedBox(
            height: 150,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Quick Actions Grid
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quickActions.length,
                    itemBuilder: (context, index) {
                      final action = quickActions[index];
                      return InkWell(
                        onTap: () => widget.onActionSelected(action['action']),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: action['color'].withOpacity(0.2),
                              radius: 24,
                              child: Icon(
                                action['icon'],
                                color: action['color'],
                              ),
                            ).animate()
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                delay: Duration(milliseconds: index * 50),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              action['label'],
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Recent Payees List
                widget.recentPayees.isEmpty
                    ? const Center(
                        child: Text('No recent payees found'),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.recentPayees.length,
                          itemBuilder: (context, index) {
                            // Verify index is valid
                            if (index >= widget.recentPayees.length) {
                              return const SizedBox.shrink();
                            }
                            
                            final payee = widget.recentPayees[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 51),  // 0.2 * 255 = 51
                                child: Text(
                                  payee.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.primaries[index % Colors.primaries.length],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(payee),
                              subtitle: const Text('Tap to create transaction'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => widget.onPayeeSelected(payee),
                            ).animate()
                              .fadeIn(delay: Duration(milliseconds: index * 50))
                              .slideX(begin: 0.1, end: 0);
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0);
  }
}

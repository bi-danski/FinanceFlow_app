import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:intl/intl.dart';

import '../../models/enhanced_goal_model.dart';
import '../../widgets/app_navigation_drawer.dart';

class EnhancedGoalsScreen extends StatefulWidget {
  const EnhancedGoalsScreen({super.key});

  @override
  State<EnhancedGoalsScreen> createState() => _EnhancedGoalsScreenState();
}

class _EnhancedGoalsScreenState extends State<EnhancedGoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 2; // Goals index in the drawer
  
  // Sample data - in a real app, this would come from a provider or repository
  final List<EnhancedGoal> _activeGoals = [
    EnhancedGoal(
      title: 'New Laptop',
      description: 'Save for a MacBook Pro',
      targetAmount: 2000,
      currentAmount: 1200,
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      targetDate: DateTime.now().add(const Duration(days: 90)),
      color: Colors.blue,
      icon: Icons.laptop_mac,
      milestones: [
        GoalMilestone(
          title: '25% Milestone',
          description: 'Quarter of the way there!',
          type: GoalMilestoneType.percentage,
          targetValue: 25,
          isReached: true,
          reachedDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        GoalMilestone(
          title: '50% Milestone',
          description: 'Halfway there!',
          type: GoalMilestoneType.percentage,
          targetValue: 50,
          isReached: true,
          reachedDate: DateTime.now().subtract(const Duration(days: 10)),
        ),
        GoalMilestone(
          title: '75% Milestone',
          description: 'Almost there!',
          type: GoalMilestoneType.percentage,
          targetValue: 75,
          isReached: false,
        ),
        GoalMilestone(
          title: 'Goal Complete',
          description: 'You did it!',
          type: GoalMilestoneType.percentage,
          targetValue: 100,
          isReached: false,
        ),
      ],
    ),
    EnhancedGoal(
      title: 'Vacation Fund',
      description: 'Trip to Bali',
      targetAmount: 3000,
      currentAmount: 900,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      targetDate: DateTime.now().add(const Duration(days: 180)),
      color: Colors.orange,
      icon: Icons.beach_access,
      milestones: [
        GoalMilestone(
          title: 'First \$500',
          description: 'Starting strong!',
          type: GoalMilestoneType.amount,
          targetValue: 500,
          isReached: true,
          reachedDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
        GoalMilestone(
          title: '\$1000 Mark',
          description: 'Keep going!',
          type: GoalMilestoneType.amount,
          targetValue: 1000,
          isReached: false,
        ),
        GoalMilestone(
          title: '\$2000 Mark',
          description: 'Almost there!',
          type: GoalMilestoneType.amount,
          targetValue: 2000,
          isReached: false,
        ),
      ],
    ),
    EnhancedGoal(
      title: 'Emergency Fund',
      description: '3 months of expenses',
      targetAmount: 5000,
      currentAmount: 1500,
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      targetDate: DateTime.now().add(const Duration(days: 270)),
      color: Colors.green,
      icon: Icons.health_and_safety,
    ),
  ];
  
  final List<EnhancedGoal> _completedGoals = [
    EnhancedGoal(
      title: 'New Phone',
      description: 'iPhone 15',
      targetAmount: 1000,
      currentAmount: 1000,
      startDate: DateTime.now().subtract(const Duration(days: 120)),
      targetDate: DateTime.now().subtract(const Duration(days: 10)),
      status: GoalStatus.completed,
      color: Colors.purple,
      icon: Icons.phone_iphone,
    ),
  ];

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

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Goals'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsList(_activeGoals),
          _buildGoalsList(_completedGoals),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add new goal
          _showAddGoalDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalsList(List<EnhancedGoal> goals) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new goal',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(goals[index])
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: index * 100))
          .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildGoalCard(EnhancedGoal goal) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showGoalDetailsDialog(goal);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: goal.color.withAlpha(40),
                    child: Icon(
                      goal.icon,
                      color: goal.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          goal.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (goal.status == GoalStatus.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearPercentIndicator(
                          percent: goal.progressPercentage,
                          lineHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          progressColor: goal.color,
                          barRadius: const Radius.circular(6),
                          animation: true,
                          animationDuration: 1000,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(goal.currentAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format(goal.targetAmount),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CircularPercentIndicator(
                      radius: 30,
                      lineWidth: 6,
                      percent: goal.progressPercentage,
                      center: Text(
                        '${(goal.progressPercentage * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.grey.shade200,
                      progressColor: goal.color,
                      animation: true,
                      animationDuration: 1000,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        dateFormat.format(goal.targetDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated Completion',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        goal.timeToCompletionEstimate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: goal.isCompleted ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (goal.milestones.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: goal.milestones.length,
                    itemBuilder: (context, index) {
                      final milestone = goal.milestones[index];
                      return _buildMilestoneItem(milestone, goal.color);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneItem(GoalMilestone milestone, Color color) {
    final isReached = milestone.isReached;
    final dateFormat = DateFormat('MMM d');
    
    String subtitleText;
    switch (milestone.type) {
      case GoalMilestoneType.percentage:
        subtitleText = '${milestone.targetValue.round()}%';
        break;
      case GoalMilestoneType.amount:
        subtitleText = '\$${milestone.targetValue}';
        break;
      case GoalMilestoneType.date:
        final date = DateTime.fromMillisecondsSinceEpoch(milestone.targetValue.toInt());
        subtitleText = dateFormat.format(date);
        break;
    }
    
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isReached ? color.withAlpha(40) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReached ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isReached ? Icons.check_circle : Icons.circle_outlined,
            color: isReached ? color : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            milestone.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isReached ? color : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitleText,
            style: TextStyle(
              fontSize: 10,
              color: isReached ? color : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isReached && milestone.reachedDate != null)
            Text(
              dateFormat.format(milestone.reachedDate!),
              style: TextStyle(
                fontSize: 9,
                color: isReached ? color.withAlpha(200) : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  void _showGoalDetailsDialog(EnhancedGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.description),
              const SizedBox(height: 16),
              // Add more detailed information here
              Text('Progress: ${(goal.progressPercentage * 100).round()}%'),
              Text('Current: \$${goal.currentAmount}'),
              Text('Target: \$${goal.targetAmount}'),
              Text('Days remaining: ${goal.daysRemaining}'),
              // Add milestone details, contribution history, etc.
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddContributionDialog(goal);
            },
            child: const Text('Add Contribution'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    // This would be a form to add a new goal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Goal'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form fields would go here
              Text('Goal creation form would go here'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Add logic to create a new goal
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddContributionDialog(EnhancedGoal goal) {
    // This would be a form to add a contribution to a goal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Contribution to ${goal.title}'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form fields would go here
              Text('Contribution form would go here'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Add logic to add a contribution
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

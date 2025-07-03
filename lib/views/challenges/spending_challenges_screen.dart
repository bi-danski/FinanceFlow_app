import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../models/spending_challenge_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';

class SpendingChallengesScreen extends StatefulWidget {
  const SpendingChallengesScreen({super.key});

  @override
  State<SpendingChallengesScreen> createState() => _SpendingChallengesScreenState();
}

class _SpendingChallengesScreenState extends State<SpendingChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 9; // Insights index in the drawer
  
  // Sample challenges data
  final List<SpendingChallenge> _challenges = [
    SpendingChallenge(
      title: 'No-Spend Weekend',
      description: 'Avoid all non-essential spending this weekend',
      type: ChallengeType.noSpend,
      difficulty: ChallengeDifficulty.medium,
      status: ChallengeStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      categories: ['Entertainment', 'Dining', 'Shopping'],
      icon: Icons.weekend,
      color: Colors.purple,
      availableBadges: [
        ChallengeBadge(
          name: 'Weekend Warrior',
          description: 'Complete the No-Spend Weekend challenge',
          icon: Icons.military_tech,
          unlockThreshold: 1.0,
        ),
      ],
      rules: [
        ChallengeRule(
          description: 'No restaurant spending',
          isSatisfied: true,
        ),
        ChallengeRule(
          description: 'No entertainment spending',
          isSatisfied: true,
        ),
        ChallengeRule(
          description: 'No shopping',
          isSatisfied: true,
        ),
      ],
    ),
    SpendingChallenge(
      title: 'Coffee Budget',
      description: 'Limit coffee spending to \$20 this week',
      type: ChallengeType.budgetLimit,
      difficulty: ChallengeDifficulty.easy,
      status: ChallengeStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 4)),
      categories: ['Coffee', 'Dining'],
      targetAmount: 20.0,
      currentAmount: 12.50,
      icon: Icons.coffee,
      color: Colors.brown,
      availableBadges: [
        ChallengeBadge(
          name: 'Coffee Connoisseur',
          description: 'Stay within your coffee budget',
          icon: Icons.coffee_maker,
          unlockThreshold: 1.0,
        ),
      ],
    ),
    SpendingChallenge(
      title: 'Lunch Savings',
      description: 'Save \$50 by bringing lunch from home',
      type: ChallengeType.savingsTarget,
      difficulty: ChallengeDifficulty.medium,
      status: ChallengeStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 14)),
      categories: ['Food', 'Dining'],
      targetAmount: 50.0,
      currentAmount: 27.50,
      icon: Icons.lunch_dining,
      color: Colors.green,
      availableBadges: [
        ChallengeBadge(
          name: 'Lunch Master',
          description: 'Save \$50 on lunch',
          icon: Icons.savings,
          unlockThreshold: 0.5,
        ),
        ChallengeBadge(
          name: 'Lunch Champion',
          description: 'Complete the lunch savings challenge',
          icon: Icons.emoji_events,
          unlockThreshold: 1.0,
        ),
      ],
    ),
    SpendingChallenge(
      title: 'Daily Expense Tracking',
      description: 'Track all expenses every day for a week',
      type: ChallengeType.habitBuilding,
      difficulty: ChallengeDifficulty.easy,
      status: ChallengeStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 4)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      categories: [],
      icon: Icons.track_changes,
      color: Colors.blue,
      availableBadges: [
        ChallengeBadge(
          name: 'Tracking Pro',
          description: 'Track expenses for 7 days straight',
          icon: Icons.trending_up,
          unlockThreshold: 1.0,
        ),
      ],
      rules: [
        ChallengeRule(
          description: 'Log all expenses each day',
          isSatisfied: true,
        ),
        ChallengeRule(
          description: 'Categorize all transactions',
          isSatisfied: true,
        ),
        ChallengeRule(
          description: 'Review daily spending',
          isSatisfied: true,
        ),
      ],
    ),
  ];
  
  final List<SpendingChallenge> _completedChallenges = [
    SpendingChallenge(
      title: 'Grocery Budget',
      description: 'Stay under \$200 for groceries this month',
      type: ChallengeType.budgetLimit,
      difficulty: ChallengeDifficulty.medium,
      status: ChallengeStatus.completed,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 5)),
      categories: ['Groceries'],
      targetAmount: 200.0,
      currentAmount: 185.75,
      icon: Icons.shopping_cart,
      color: Colors.orange,
      availableBadges: [
        ChallengeBadge(
          name: 'Budget Shopper',
          description: 'Complete the grocery budget challenge',
          icon: Icons.shopping_basket,
          unlockThreshold: 1.0,
        ),
      ],
      earnedBadges: [
        ChallengeBadge(
          name: 'Budget Shopper',
          description: 'Complete the grocery budget challenge',
          icon: Icons.shopping_basket,
          unlockThreshold: 1.0,
        ),
      ],
    ),
    SpendingChallenge(
      title: 'No Online Shopping',
      description: 'Avoid online shopping for two weeks',
      type: ChallengeType.noSpend,
      difficulty: ChallengeDifficulty.hard,
      status: ChallengeStatus.completed,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 16)),
      categories: ['Shopping'],
      icon: Icons.shopping_bag,
      color: Colors.red,
      availableBadges: [
        ChallengeBadge(
          name: 'Digital Detox',
          description: 'Complete the no online shopping challenge',
          icon: Icons.do_not_disturb,
          unlockThreshold: 1.0,
        ),
      ],
      earnedBadges: [
        ChallengeBadge(
          name: 'Digital Detox',
          description: 'Complete the no online shopping challenge',
          icon: Icons.do_not_disturb,
          unlockThreshold: 1.0,
        ),
      ],
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
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    // Close drawer if open
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Navigate only if not already on target route
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
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
          _buildChallengesList(_challenges),
          _buildChallengesList(_completedChallenges),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddChallengeDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChallengesList(List<SpendingChallenge> challenges) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No challenges yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new challenge',
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
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        return _buildChallengeCard(challenges[index])
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: index * 100))
          .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildChallengeCard(SpendingChallenge challenge) {
    final isCompleted = challenge.status == ChallengeStatus.completed;
    final isFailed = challenge.status == ChallengeStatus.failed;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showChallengeDetailsDialog(challenge);
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
                    backgroundColor: challenge.color.withAlpha(40),
                    child: Icon(
                      challenge.icon,
                      color: challenge.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          challenge.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildChallengeStatusBadge(challenge.status),
                ],
              ),
              const SizedBox(height: 16),
              LinearPercentIndicator(
                percent: challenge.progressPercentage,
                lineHeight: 10,
                backgroundColor: Colors.grey.shade200,
                progressColor: _getStatusColor(challenge.status),
                barRadius: const Radius.circular(5),
                animation: true,
                animationDuration: 1000,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(challenge.progressPercentage * 100).round()}% Complete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(challenge.status),
                    ),
                  ),
                  Text(
                    _getPointsText(challenge),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDifficultyText(challenge.difficulty),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDifficultyColor(challenge.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isCompleted && !isFailed)
                    Text(
                      '${challenge.daysRemaining} days left',
                      style: TextStyle(
                        fontSize: 12,
                        color: challenge.daysRemaining < 3 ? Colors.red : Colors.grey.shade600,
                        fontWeight: challenge.daysRemaining < 3 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              if (challenge.earnedBadges.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Badges Earned: ${challenge.earnedBadges.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeStatusBadge(ChallengeStatus status) {
    String text;
    Color color;
    IconData icon;
    
    switch (status) {
      case ChallengeStatus.notStarted:
        text = 'Not Started';
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        break;
      case ChallengeStatus.active:
        text = 'Active';
        color = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case ChallengeStatus.completed:
        text = 'Completed';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ChallengeStatus.failed:
        text = 'Failed';
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.notStarted:
        return Colors.grey;
      case ChallengeStatus.active:
        return Colors.blue;
      case ChallengeStatus.completed:
        return Colors.green;
      case ChallengeStatus.failed:
        return Colors.red;
    }
  }

  String _getDifficultyText(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.expert:
        return 'Expert';
    }
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.expert:
        return Colors.purple;
    }
  }

  String _getPointsText(SpendingChallenge challenge) {
    return '${challenge.pointsEarned} pts';
  }

  void _showChallengeDetailsDialog(SpendingChallenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(challenge.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.description),
              const SizedBox(height: 16),
              // Add more detailed information here
              Text('Status: ${challenge.status.toString().split('.').last}'),
              Text('Progress: ${(challenge.progressPercentage * 100).round()}%'),
              if (challenge.type == ChallengeType.budgetLimit || challenge.type == ChallengeType.savingsTarget)
                Text('Amount: \$${challenge.currentAmount} / \$${challenge.targetAmount}'),
              Text('Days remaining: ${challenge.daysRemaining}'),
              // Add rules, badges, etc.
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
        ],
      ),
    );
  }

  void _showAddChallengeDialog() {
    // This would be a form to add a new challenge
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Challenge'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form fields would go here
              Text('Challenge creation form would go here'),
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
              // Add logic to create a new challenge
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

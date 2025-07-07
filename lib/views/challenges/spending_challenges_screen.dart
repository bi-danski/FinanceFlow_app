import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../models/spending_challenge_model.dart';
import '../../viewmodels/challenge_view_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import 'add_challenge_screen.dart';

class SpendingChallengesScreen extends StatefulWidget {
  const SpendingChallengesScreen({super.key});

  @override
  State<SpendingChallengesScreen> createState() => _SpendingChallengesScreenState();
}

class _SpendingChallengesScreenState extends State<SpendingChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 9; // Insights index in the drawer

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddChallengeScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ChallengeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Text('Error: ${viewModel.error}'),
            );
          }

          final activeChallenges = viewModel.challenges
              .where((c) => c.status == ChallengeStatus.active || c.status == ChallengeStatus.notStarted)
              .toList();
          final completedChallenges = viewModel.challenges
              .where((c) => c.status == ChallengeStatus.completed || c.status == ChallengeStatus.failed)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChallengesList(activeChallenges),
              _buildChallengesList(completedChallenges),
            ],
          );
        },
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


}

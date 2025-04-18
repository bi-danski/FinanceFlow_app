import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../viewmodels/insights_viewmodel.dart';
import '../../models/insight_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 9; // AI Insights tab selected
  late TabController _tabController;
  bool _isGeneratingInsights = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInsights();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    final insightsViewModel = Provider.of<InsightsViewModel>(context, listen: false);
    await insightsViewModel.loadInsights();
  }

  Future<void> _generateNewInsights() async {
    setState(() {
      _isGeneratingInsights = true;
    });
    
    try {
      final insightsViewModel = Provider.of<InsightsViewModel>(context, listen: false);
      await insightsViewModel.generateInsights();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New insights generated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate insights: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInsights = false;
        });
      }
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final insightsViewModel = Provider.of<InsightsViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          if (_isGeneratingInsights)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Generate new insights',
              onPressed: _generateNewInsights,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Insights'),
            Tab(text: 'Financial Health'),
            Tab(text: 'Spending Patterns'),
            Tab(text: 'Saving Opportunities'),
          ],
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: insightsViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsList(insightsViewModel.insights),
                _buildInsightsList(insightsViewModel.getInsightsByType('Financial Health')),
                _buildInsightsList(insightsViewModel.getInsightsByType('Spending Pattern')),
                _buildInsightsList(insightsViewModel.getInsightsByType('Saving Opportunity')),
              ],
            ),
    );
  }

  Widget _buildInsightsList(List<Insight> insights) {
    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.lightbulb,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No insights available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the refresh button to generate new insights',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateNewInsights,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate Insights'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return _buildInsightCard(insight);
      },
    );
  }

  Widget _buildInsightCard(Insight insight) {
    final iconData = _getInsightIcon(insight.type);
    final iconColor = _getInsightColor(insight.type);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: insight.isRead
            ? BorderSide.none
            : const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _showInsightDetails(insight),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.type,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(insight.date),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!insight.isRead)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInsightDetails(Insight insight) async {
    // Mark as read
    if (!insight.isRead) {
      final insightsViewModel = Provider.of<InsightsViewModel>(context, listen: false);
      await insightsViewModel.markInsightAsRead(insight.id!);
    }
    
    // Show detail dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => _buildInsightDetailDialog(insight),
      );
    }
  }

  Widget _buildInsightDetailDialog(Insight insight) {
    final iconData = _getInsightIcon(insight.type);
    final iconColor = _getInsightColor(insight.type);
    
    Widget content;
    
    // Create specialized content based on insight type
    switch (insight.type) {
      case 'Spending Pattern':
        if (insight.data != null) {
          final spendingInsight = SpendingPatternInsight.fromInsight(insight);
          content = _buildSpendingPatternContent(spendingInsight);
        } else {
          content = Text(insight.description);
        }
        break;
      case 'Budget Alert':
        if (insight.data != null) {
          final budgetInsight = BudgetAlertInsight.fromInsight(insight);
          content = _buildBudgetAlertContent(budgetInsight);
        } else {
          content = Text(insight.description);
        }
        break;
      case 'Saving Opportunity':
        if (insight.data != null) {
          final savingInsight = SavingOpportunityInsight.fromInsight(insight);
          content = _buildSavingOpportunityContent(savingInsight);
        } else {
          content = Text(insight.description);
        }
        break;
      case 'Financial Health':
        if (insight.data != null) {
          final healthInsight = FinancialHealthInsight.fromInsight(insight);
          content = _buildFinancialHealthContent(healthInsight);
        } else {
          content = Text(insight.description);
        }
        break;
      default:
        content = Text(insight.description);
    }
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(iconData, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(insight.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                insight.type,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 16),
            Text(
              'Generated on ${DateFormat('MMMM d, yyyy').format(insight.date)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final insightsViewModel = Provider.of<InsightsViewModel>(context, listen: false);
            insightsViewModel.dismissInsight(insight.id!);
            Navigator.pop(context);
          },
          child: const Text('Dismiss'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildSpendingPatternContent(SpendingPatternInsight insight) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isIncrease = insight.percentageChange > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(insight.description),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Previous ${insight.timeFrame}',
          currencyFormat.format(insight.previousAmount),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Current ${insight.timeFrame}',
          currencyFormat.format(insight.currentAmount),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Change',
          '${isIncrease ? '+' : ''}${insight.percentageChange.toStringAsFixed(1)}%',
          valueColor: isIncrease ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'What this means:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isIncrease
              ? 'Your spending in this category has increased. Consider reviewing your habits to identify potential savings.'
              : 'Your spending in this category has decreased. Great job managing your expenses!',
        ),
      ],
    );
  }

  Widget _buildBudgetAlertContent(BudgetAlertInsight insight) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(insight.description),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Budget Amount',
          currencyFormat.format(insight.budgetAmount),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Spent Amount',
          currencyFormat.format(insight.spentAmount),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Percentage Used',
          '${insight.percentageUsed.toStringAsFixed(1)}%',
          valueColor: insight.percentageUsed > 90 ? Colors.red : Colors.orange,
        ),
        const SizedBox(height: 16),
        const Text(
          'Recommendation:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          insight.percentageUsed > 90
              ? 'Consider adjusting your spending in this category for the remainder of the month to avoid exceeding your budget.'
              : 'Monitor your spending in this category closely for the rest of the month.',
        ),
      ],
    );
  }

  Widget _buildSavingOpportunityContent(SavingOpportunityInsight insight) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(insight.description),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Category',
          insight.category,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Potential Monthly Savings',
          currencyFormat.format(insight.potentialSavings),
          valueColor: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Annual Savings Potential',
          currencyFormat.format(insight.potentialSavings * 12),
          valueColor: Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'Suggestion:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(insight.suggestion),
      ],
    );
  }

  Widget _buildFinancialHealthContent(FinancialHealthInsight insight) {
    Color healthColor;
    switch (insight.overallHealth) {
      case 'good':
        healthColor = Colors.green;
        break;
      case 'moderate':
        healthColor = Colors.orange;
        break;
      default:
        healthColor = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(insight.description),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Savings Rate',
          '${(insight.savingsRate * 100).toStringAsFixed(1)}%',
          valueColor: insight.savingsRate >= AppConstants.goodSavingsRateThreshold
              ? Colors.green
              : insight.savingsRate >= AppConstants.moderateSavingsRateThreshold
                  ? Colors.orange
                  : Colors.red,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Debt-to-Income Ratio',
          '${(insight.debtToIncomeRatio * 100).toStringAsFixed(1)}%',
          valueColor: insight.debtToIncomeRatio <= AppConstants.goodDebtToIncomeRatio
              ? Colors.green
              : insight.debtToIncomeRatio <= AppConstants.moderateDebtToIncomeRatio
                  ? Colors.orange
                  : Colors.red,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Emergency Fund',
          '${insight.emergencyFundMonths.toStringAsFixed(1)} months',
          valueColor: insight.emergencyFundMonths >= AppConstants.goodEmergencyFundMonths
              ? Colors.green
              : insight.emergencyFundMonths >= AppConstants.moderateEmergencyFundMonths
                  ? Colors.orange
                  : Colors.red,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Overall Health',
          insight.overallHealth.substring(0, 1).toUpperCase() + insight.overallHealth.substring(1),
          valueColor: healthColor,
        ),
        const SizedBox(height: 16),
        const Text(
          'Recommendations:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...insight.recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(recommendation)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'Spending Pattern':
        return FontAwesomeIcons.chartLine;
      case 'Budget Alert':
        return FontAwesomeIcons.triangleExclamation;
      case 'Saving Opportunity':
        return FontAwesomeIcons.piggyBank;
      case 'Financial Health':
        return FontAwesomeIcons.heartPulse;
      case 'Debt Management':
        return FontAwesomeIcons.creditCard;
      case 'Income Optimization':
        return FontAwesomeIcons.moneyBillTrendUp;
      case 'Goal Progress':
        return FontAwesomeIcons.bullseye;
      case 'Expense Anomaly':
        return FontAwesomeIcons.magnifyingGlassDollar;
      default:
        return FontAwesomeIcons.lightbulb;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'Spending Pattern':
        return Colors.blue;
      case 'Budget Alert':
        return Colors.orange;
      case 'Saving Opportunity':
        return Colors.green;
      case 'Financial Health':
        return Colors.purple;
      case 'Debt Management':
        return Colors.red;
      case 'Income Optimization':
        return Colors.teal;
      case 'Goal Progress':
        return Colors.amber;
      case 'Expense Anomaly':
        return Colors.deepOrange;
      default:
        return AppTheme.primaryColor;
    }
  }
}

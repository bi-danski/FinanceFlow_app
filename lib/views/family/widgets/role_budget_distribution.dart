import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:financeflow_app/models/family_member_model.dart';
import 'package:financeflow_app/viewmodels/family_viewmodel.dart';

class RoleBudgetDistribution extends StatelessWidget {
  const RoleBudgetDistribution({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FamilyViewModel>(context);
    
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _calculateRoleBudgets(viewModel.familyMembers);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Budget Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: data.map((member) => PieChartSectionData(
                  title: '${member.role.capitalize()}\n\$${member.budget.toStringAsFixed(0)}',
                  value: member.budget,
                  color: member.role == 'parent' ? Colors.blue : 
                         member.role == 'child' ? Colors.orange : Colors.grey,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 120,
                  titlePositionPercentageOffset: 0.55,
                )).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FamilyMember> _calculateRoleBudgets(List<FamilyMember> members) {
    final Map<String, double> roleBudgets = {};
    
    // Calculate total budget per role
    for (final member in members) {
      roleBudgets.update(
        member.role,
        (value) => value + member.budget,
        ifAbsent: () => member.budget,
      );
    }

    // Create FamilyMember objects for each role with aggregated budget
    return roleBudgets.entries.map((entry) => FamilyMember(
      name: entry.key,
      budget: entry.value,
      role: entry.key,
    )).toList();
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

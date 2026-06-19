import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class NutritionChartWidget extends StatelessWidget {
  const NutritionChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        
        // Calculate totals for today
        double totalCarbs = 0;
        double totalProtein = 0;
        double totalFat = 0;

        final today = DateTime.now();
        final todaysLogs = appState.foodLogs.where((log) => 
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day);

        for (var log in todaysLogs) {
          totalCarbs += log.carbs;
          totalProtein += log.protein;
          totalFat += log.fat;
        }

        double totalMacros = totalCarbs + totalProtein + totalFat;
        if (totalMacros == 0) totalMacros = 1; // Prevent division by zero

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: totalCarbs == 0 && totalProtein == 0 && totalFat == 0 
                            ? Center(child: Text('No food logged today', style: TextStyle(color: Colors.grey[400])))
                            : PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.blue,
                                      value: totalCarbs / totalMacros * 100,
                                      title: '${(totalCarbs / totalMacros * 100).toStringAsFixed(0)}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      color: Colors.redAccent,
                                      value: totalProtein / totalMacros * 100,
                                      title: '${(totalProtein / totalMacros * 100).toStringAsFixed(0)}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      color: Colors.amber,
                                      value: totalFat / totalMacros * 100,
                                      title: '${(totalFat / totalMacros * 100).toStringAsFixed(0)}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Legend
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(Colors.blue, 'Carbs', '${totalCarbs.toStringAsFixed(1)}g'),
                          const SizedBox(height: 8),
                          _buildLegendItem(Colors.redAccent, 'Protein', '${totalProtein.toStringAsFixed(1)}g'),
                          const SizedBox(height: 8),
                          _buildLegendItem(Colors.amber, 'Fat', '${totalFat.toStringAsFixed(1)}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text('$label: $value', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

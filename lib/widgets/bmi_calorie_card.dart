import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class BmiCalorieCard extends StatelessWidget {
  const BmiCalorieCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final profile = appState.userProfile;
        if (profile == null) return const SizedBox.shrink();

        int remaining = appState.remainingCalories;
        int total = profile.dailyCalorieRequirement;
        double progress = (total - remaining) / total;
        if (progress > 1.0) progress = 1.0;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              profile.bmi.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getBmiColor(profile.bmiCategory).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile.bmiCategory,
                                style: TextStyle(
                                  color: _getBmiColor(profile.bmiCategory),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                         Text(
                          'Calocredits',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 4),
                            Text(
                              '${appState.calocredits}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Calorie Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Calories Remaining',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$remaining / $total kcal',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: Colors.grey[200],
                    color: progress > 0.9 ? Colors.redAccent : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBmiColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'overweight':
        return Colors.orangeAccent;
      case 'obese':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}

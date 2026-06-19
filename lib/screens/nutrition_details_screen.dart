import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/nutrition_chart_widget.dart';

class NutritionDetailsScreen extends StatelessWidget {
  const NutritionDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Breakdown'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NutritionChartWidget(),
            const SizedBox(height: 24),
            Text(
              'Daily Food Log',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailedLogs(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedLogs(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final today = DateTime.now();
        final todaysLogs = appState.foodLogs.where((log) => 
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day).toList();

        if (todaysLogs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No meals logged today yet.'),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todaysLogs.length,
          itemBuilder: (context, index) {
            final log = todaysLogs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.restaurant_rounded, color: Theme.of(context).primaryColor),
                ),
                title: Text(log.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${log.calories} kcal'),
                    Text('C: ${log.carbs}g • P: ${log.protein}g • F: ${log.fat}g', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: Text(
                  '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            );
          },
        );
      }
    );
  }
}

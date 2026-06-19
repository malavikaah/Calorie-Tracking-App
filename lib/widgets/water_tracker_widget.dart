import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class WaterTrackerWidget extends StatelessWidget {
  const WaterTrackerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        double fillPercentage = appState.waterIntakeMl / appState.dailyWaterGoal;
        if (fillPercentage > 1.0) fillPercentage = 1.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Cylinder representation
                Container(
                  width: 60,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      FractionallySizedBox(
                        heightFactor: fillPercentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[300]!.withOpacity(0.8),
                            borderRadius: BorderRadius.only(
                              bottomLeft: const Radius.circular(28),
                              bottomRight: const Radius.circular(28),
                              topLeft: fillPercentage == 1.0 ? const Radius.circular(28) : Radius.zero,
                              topRight: fillPercentage == 1.0 ? const Radius.circular(28) : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Water Tracker',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${appState.waterIntakeMl} ml / ${appState.dailyWaterGoal} ml',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildWaterButton(context, 250, '+250ml', appState),
                          const SizedBox(width: 8),
                          _buildWaterButton(context, 500, '+500ml', appState),
                          const Spacer(),
                          if (appState.canUndoWater)
                            IconButton(
                              onPressed: () => appState.undoWater(),
                              icon: const Icon(Icons.undo_rounded, color: Colors.redAccent),
                              tooltip: 'Undo last entry',
                            ),
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

  Widget _buildWaterButton(BuildContext context, int amount, String label, AppState appState) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        appState.addWater(amount);
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../services/pdf_export_service.dart';

class NutriInsightsScreen extends StatelessWidget {
  const NutriInsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final summary = appState.nutriInsightsSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutri Insights Portal'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightsHeader(context, appState),
            const SizedBox(height: 24),
            Text(
              'Nutrition Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricGrid(context, summary),
            const SizedBox(height: 24),
            _buildStabilityChart(context),
            const SizedBox(height: 24),
            _buildHealthAlerts(appState),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await PdfExportService.generateAndPrintReport(appState.userProfile, appState.nutriInsightsSummary);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showShareDialog(context, appState),
                  icon: const Icon(Icons.share),
                  label: const Text('Share with Dietitian'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<String>>(
          stream: appState.getChatParticipantsStream(),
          builder: (context, snapshot) {
            final emails = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('Share Report'),
              content: emails.isEmpty 
                ? const Text('You haven\'t chatted with any dietitians yet.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: emails.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(emails[index]),
                          onTap: () async {
                            await appState.shareReportWithDietitian(emails[index]);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report shared in chat!')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildInsightsHeader(BuildContext context, AppState appState) {
    bool hasConsistencyBadge = appState.purchasedItems.contains('badge_consistency');

    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.mintGreen,
                  child: Icon(Icons.person, size: 30, color: AppTheme.darkGreen),
                ),
                if (hasConsistencyBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        appState.userProfile?.name ?? 'User',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (hasConsistencyBadge) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.military_tech, color: Colors.amber, size: 20),
                      ],
                    ],
                  ),
                  Text(
                    'Member ID: #CALO-${DateTime.now().year}-001',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SYNCED',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, Map<String, dynamic> summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildMetricCard(context, 'Avg Calories', '${summary['avgDailyCalories']} kcal', Icons.analytics),
        _buildMetricCard(context, 'BMI Status', summary['bmiTrend'], Icons.monitor_weight),
        _buildMetricCard(context, 'Stability', summary['lastSevenDaysStability'], Icons.trending_up),
        _buildMetricCard(context, 'Alert Status', summary['healthAlertsActive'] ? 'Action Required' : 'Optimal', Icons.notification_important),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStabilityChart(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Nutritional Stability', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 1),
                      const FlSpot(1, 1.5),
                      const FlSpot(2, 1.4),
                      const FlSpot(3, 2),
                      const FlSpot(4, 1.8),
                      const FlSpot(5, 2.2),
                      const FlSpot(6, 1.9),
                    ],
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAlerts(AppState appState) {
    if (appState.userProfile?.healthCondition == 'none') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Health Observations', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring: ${appState.userProfile!.healthCondition.toUpperCase()}',
                      style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AI insights suggest focusing on specific macros to better manage your ${appState.userProfile!.healthCondition} condition.',
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class CreditShopScreen extends StatelessWidget {
  const CreditShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CaloCredit Hub'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'How to Earn'),
              Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Spend Credits'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildEarnTab(context),
            _buildShopTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEarnCard(
          context,
          'Daily Logging',
          'Log your meals every day.',
          '12 Credits',
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildEarnCard(
          context,
          'Consistency Streak',
          'Keep a streak alive for extra bonuses!',
          '5+ Credits',
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildEarnCard(
          context,
          'Golden Hour',
          'Log your foods before 8:00 PM.',
          '5 Credits',
          Icons.wb_sunny_outlined,
          Colors.amber,
        ),
        _buildEarnCard(
          context,
          'Diet Diversity',
          'Log 3 or more distinct food items today.',
          '15 Credits',
          Icons.restaurant_menu,
          Colors.purple,
        ),
        _buildEarnCard(
          context,
          'Water Goal',
          'Reach your daily hydration target.',
          '10 Credits',
          Icons.water_drop_outlined,
          Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildEarnCard(BuildContext context, String title, String subtitle, String reward, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.mintGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            reward,
            style: const TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildShopTab(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: [
              _buildShopItem(
                context,
                appState,
                id: 'default_theme',
                name: 'Classic Theme',
                description: 'The original CaloTrack green.',
                price: 0,
                icon: Icons.eco_outlined,
                color: AppTheme.primaryGreen,
              ),
              _buildShopItem(
                context,
                appState,
                id: 'ocean_theme',
                name: 'Ocean Theme',
                description: 'Deep sea blues.',
                price: 50,
                icon: Icons.water_drop_outlined,
                color: Colors.blue,
              ),
              _buildShopItem(
                context,
                appState,
                id: 'midnight_theme',
                name: 'Midnight Theme',
                description: 'Premium dark mode experience.',
                price: 75,
                icon: Icons.nightlight_round,
                color: Colors.indigo,
              ),
              _buildShopItem(
                context,
                appState,
                id: 'badge_consistency',
                name: 'Consistent King',
                description: 'Display your dedication.',
                price: 100,
                icon: Icons.military_tech,
                color: Colors.amber,
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }


  Widget _buildShopItem(BuildContext context, AppState appState, {
    required String id,
    required String name,
    required String description,
    required int price,
    required IconData icon,
    required Color color,
  }) {
    bool isOwned = appState.purchasedItems.contains(id);
    bool isTheme = id.contains('theme');
    bool isActive = appState.activeTheme == id;

    String buttonText;
    if (isOwned) {
      if (isTheme) {
        buttonText = isActive ? 'SELECTED' : 'APPLY';
      } else {
        buttonText = 'OWNED';
      }
    } else {
      buttonText = '🪙 $price';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isOwned && isTheme && isActive) 
                    ? null 
                    : () => _handleItemAction(context, appState, id, price, name, isOwned, isTheme),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isOwned && isActive) ? Colors.grey : AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemAction(BuildContext context, AppState appState, String id, int price, String name, bool isOwned, bool isTheme) async {
    if (isOwned) {
      if (isTheme) {
        appState.setTheme(id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Applied $name')));
      }
    } else {
      if (appState.calocredits >= price) {
        bool success = await appState.spendCalocredits(price, id);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchased $name!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough credits.')));
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'chat_screen.dart';

class DietitianDashboardScreen extends StatelessWidget {
  const DietitianDashboardScreen({Key? key}) : super(key: key);

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Provider.of<AppState>(context, listen: false).logout();
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF4F9F1), // Matching theme background
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/logo_small.png', height: 40),
            ),
            const SizedBox(width: 12),
            const Text('Dietitian Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final participants = appState.getChatParticipants();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${appState.dietitianProfile?.name ?? 'Doctor'}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${participants.length} active patients today.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: participants.isEmpty
                    ? const Center(child: Text('No active consultations yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final userEmail = participants[index];
                          return FutureBuilder<String>(
                            future: appState.getNameByEmail(userEmail),
                            builder: (context, snapshot) {
                              final displayName = snapshot.data ?? userEmail;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.person_rounded, color: Theme.of(context).primaryColor, size: 30),
                                  ),
                                  title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(userEmail, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.chat_rounded, color: Theme.of(context).primaryColor, size: 20),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(otherEmail: userEmail),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

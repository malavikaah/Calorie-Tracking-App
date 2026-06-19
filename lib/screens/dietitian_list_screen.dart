import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/dietitian_profile.dart';
import 'chat_screen.dart';

class DietitianListScreen extends StatelessWidget {
  const DietitianListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Dietitians'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Provider.of<AppState>(context, listen: false).getDietitians(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No dietitians available at the moment.',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final dietitians = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dietitians.length,
            itemBuilder: (context, index) {
              final dietitian = dietitians[index];
              final DietitianProfile profile = dietitian['profile'];
              final String email = dietitian['email'];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.health_and_safety, color: primaryColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              profile.specialization,
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.experience} Experience',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chat_bubble_outline, color: primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(otherEmail: email),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

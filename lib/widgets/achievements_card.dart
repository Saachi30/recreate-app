import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = context.watch<AuthProvider>().user?.achievements ?? [];

    return Card(
      color: const Color.fromARGB(255, 246, 247, 246),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.emoji_events, color: Colors.amber),
              title: Text('Achievements'),
              contentPadding: EdgeInsets.zero,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return ListTile(
                  title: Text(achievement.title),
                  subtitle: Text(achievement.description),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 246, 247, 246),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.purple),
              title: Text('Available Rewards'),
              contentPadding: EdgeInsets.zero,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('10% Off Solar Installation'),
                  subtitle: Text('Premium • Expires in 30 days'),
                  trailing: Text('2000 pts',
                      style: TextStyle(color: Colors.green)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

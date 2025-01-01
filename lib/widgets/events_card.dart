import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EventsCard extends StatelessWidget {
  const EventsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AuthProvider>().user?.events ?? [];

    return Card(
      color: const Color.fromARGB(255, 246, 247, 246),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.event, color: Colors.green),
              title: Text('Upcoming Events'),
              contentPadding: EdgeInsets.zero,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text('Date: ${event.date}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
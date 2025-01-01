import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEventCard(
            'Community Solar Workshop',
            '2024-01-15',
            'Learn about solar panel installation and maintenance.',
            true,
          ),
          const SizedBox(height: 16),
          _buildEventCard(
            'Energy Saving Webinar',
            '2024-02-01',
            'Tips and tricks for reducing your energy consumption.',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String date, String description, bool isRegistered) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Date: $date'),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isRegistered ? null : () {},
              child: Text(isRegistered ? 'Registered' : 'Register Now'),
            ),
          ],
        ),
      ),
    );
  }
}
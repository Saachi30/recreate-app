import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/bill_upload_screen.dart';
import '../screens/leaderboard_screen.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Card(
      color: const Color.fromARGB(255, 246, 247, 246),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(user?.name ?? ''),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFFFFD700)),
              title: Text(
                '${user?.greenPoints ?? 0} Green Points',
                style: const TextStyle(color: Color(0xFF27AE60)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Upload Bill'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BillUploadScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 163, 206, 181),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Grid Return'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BillUploadScreen(
                            isGridReturn: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 163, 206, 181),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Add spacing between button rows
            ElevatedButton.icon(
              icon: const Icon(Icons.leaderboard),
              label: const Text('Leaderboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 163, 206, 181),
                minimumSize: const Size(double.infinity, 36), // Makes button full width
              ),
            ),
          ],
        ),
      ),
    );
  }
}
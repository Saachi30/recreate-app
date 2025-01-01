import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  // Dummy achievements data
  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'Green Energy Pioneer',
      'description': 'Successfully converted agricultural waste to energy',
      'icon': '🌱',
      'date': '2024-03-15',
    },
    {
      'title': 'Energy Producer',
      'description': 'Generated 100 kWh of renewable energy',
      'icon': '⚡',
      'date': '2024-02-20',
    },
    {
      'title': 'Community Leader',
      'description': 'Helped 5 other farmers start energy production',
      'icon': '👥',
      'date': '2024-01-10',
    }
  ];

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Contract ID copied: ${text.substring(0, 8)}...'),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Please login to view profile'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Profile',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Add refresh logic if needed
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header with Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green[50]!,
                          Colors.blue[50]!,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Avatar and Basic Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.green[100],
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.email,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        'Property ID: ${user.propertyID}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Green Points Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.eco, color: Colors.green, size: 32),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text(
                                        'Green Points',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        user.greenPoints.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Contract History
                  if (user.contractHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Contracts',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${user.contractHistory.length} total',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...user.contractHistory.take(5).map((contract) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      contract,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Contract ID: ${contract.substring(0, 8)}...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.copy_outlined),
                                      onPressed: () => _copyToClipboard(contract),
                                      tooltip: 'Copy contract ID',
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Achievements
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievements',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._achievements.map((achievement) => ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  achievement['icon'] as String,  // Explicitly cast to String
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              title: Text(
                                achievement['title'] as String,  // Explicitly cast to String
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(achievement['description'] as String),  // Explicitly cast to String
                                  const SizedBox(height: 4),
                                  Text(
                                    achievement['date'] as String,  // Explicitly cast to String
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
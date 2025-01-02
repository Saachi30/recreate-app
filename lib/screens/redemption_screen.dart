import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RedemptionScreen extends StatefulWidget {
  final int currentPoints;
  const RedemptionScreen({super.key, required this.currentPoints});

  @override
  State<RedemptionScreen> createState() => _RedemptionScreenState();
}

class _RedemptionScreenState extends State<RedemptionScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _selectedCategory = 'Achievement Badges';

  final List<Map<String, dynamic>> _rewards = [
    {
      'category': 'Achievement Badges',
      'items': [
        {
          'title': 'Green Pioneer',
          'description': 'Early adopter of renewable energy',
          'points': 100,
          'icon': '🌱',
          'type': 'badge'
        },
        {
          'title': 'Energy Champion',
          'description': 'Generated 1000+ kWh of clean energy',
          'points': 250,
          'icon': '⚡',
          'type': 'badge'
        },
        {
          'title': 'Sustainability Leader',
          'description': 'Influenced 10+ farmers to join',
          'points': 500,
          'icon': '👑',
          'type': 'badge'
        },
      ]
    },
    {
      'category': 'Digital Certificates',
      'items': [
        {
          'title': 'Green Energy Producer',
          'description': 'Official certification of contribution',
          'points': 300,
          'icon': '📜',
          'type': 'certificate'
        },
        {
          'title': 'Sustainability Expert',
          'description': 'Advanced knowledge certification',
          'points': 450,
          'icon': '🎓',
          'type': 'certificate'
        },
      ]
    },
    {
      'category': 'Partner Discounts',
      'items': [
        {
          'title': '10% Off Solar Equipment',
          'description': 'Valid at SolarTech Partners',
          'points': 200,
          'icon': '🏷️',
          'type': 'discount'
        },
        {
          'title': '15% Off Energy Audit',
          'description': 'Professional energy assessment',
          'points': 150,
          'icon': '📊',
          'type': 'discount'
        },
        {
          'title': '20% Off Workshop',
          'description': 'Renewable energy workshop registration',
          'points': 100,
          'icon': '🎫',
          'type': 'discount'
        },
      ]
    },
  ];

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Congratulations!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have successfully redeemed:\n$title',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Great!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    if (widget.currentPoints < reward['points']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points to redeem ${reward['title']}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // First update the user's points
        await _firestore.collection('Consumers').doc(user.uid).update({
          'greenPoints': FieldValue.increment(-reward['points']),
        });

        // Then add to redeemed rewards
        await _firestore.collection('Consumers').doc(user.uid).update({
          'achievements': FieldValue.arrayUnion([
            {
              'title': reward['title'],
              'description': reward['description'],
              'type': reward['type'],
              'icon': reward['icon'],
              'pointsCost': reward['points'],
              'redeemedAt': DateTime.now().toIso8601String(),
            }
          ]),
        });

        if (!mounted) return;
        
        // Show success dialog
        _showSuccessDialog(reward['title']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Redeem Points',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
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
                    Text(
                      'Available Points',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      widget.currentPoints.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _rewards.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category['category']),
                      selected: _selectedCategory == category['category'],
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category['category']);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _rewards
                  .firstWhere(
                      (category) => category['category'] == _selectedCategory)['items']
                  .length,
              itemBuilder: (context, index) {
                final reward = _rewards
                    .firstWhere(
                        (category) => category['category'] == _selectedCategory)['items'][index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        reward['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    title: Text(
                      reward['title'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward['description'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reward['points']} points',
                          style: GoogleFonts.poppins(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _redeemReward(reward),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.currentPoints >= reward['points']
                            ? Colors.green
                            : Colors.grey,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Redeem',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
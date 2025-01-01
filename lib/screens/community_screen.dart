import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../models/post.dart';
import 'package:recmarketapp/screens/events_screen.dart';
import 'package:recmarketapp/screens/create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Post> _posts = [
    Post(
      id: '1',
      userId: '1',
      userName: 'Jane Cooper',
      content: 'Just installed solar panels! Excited to contribute to green energy! 🌞',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 15,
      comments: ['Great job!', 'How much did it cost?'],
      imageUrl: null,
    ),
    Post(
      id: '2',
      userId: '2',
      userName: 'Robert Green',
      content: 'Attending the Community Solar Workshop next week. Who else is joining? 🌱',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 10,
      comments: ['I\'ll be there!'],
      imageUrl: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: _posts[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

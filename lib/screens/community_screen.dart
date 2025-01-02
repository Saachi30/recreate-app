import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Update these import paths according to your project structure
import '../providers/auth_provider.dart';
import '../models/user.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String propertyId;
  final String content;
  final DateTime timestamp;
  int likes;
  final List<String> comments;
  final String? imageUrl;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.propertyId,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.imageUrl,
    required this.likedBy,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      propertyId: data['propertyId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: List<String>.from(data['comments'] ?? []),
      imageUrl: data['imageUrl'],
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _createPost(User? currentUser) async {
    if (_contentController.text.trim().isEmpty || currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_image != null) {
        final ref = _storage.ref().child('posts/${DateTime.now().toString()}');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('UserPosts').add({
        'userId': currentUser.email,
        'userName': currentUser.name,
        'propertyId': currentUser.propertyID,
        'content': _contentController.text,
        'timestamp': Timestamp.now(),
        'likes': 0,
        'comments': [],
        'imageUrl': imageUrl,
        'likedBy': [],
      });

      _contentController.clear();
      setState(() {
        _image = null;
        _isLoading = false;
      });
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  Future<void> _likePost(Post post, User? currentUser) async {
    if (currentUser == null) return;

    try {
      final postRef = _firestore.collection('UserPosts').doc(post.id);
      if (post.likedBy.contains(currentUser.email)) {
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUser.email]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUser.email]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  Future<void> _addComment(Post post, User? currentUser) async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    try {
      final comment = '${currentUser.name} : ${_commentController.text}';
      await _firestore.collection('UserPosts').doc(post.id).update({
        'comments': FieldValue.arrayUnion([comment]),
      });
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  void _showCreatePostDialog(User? currentUser) {
    if (currentUser == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_image != null) ...[
                Image.file(
                  _image!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _pickImage,
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _createPost(currentUser),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.user;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Community',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('UserPosts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs
                  .map((doc) => Post.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Text(
                                  post.userName[0].toUpperCase(),
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${post.userName} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${DateTime.now().difference(post.timestamp).inHours}h ago',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(post.content),
                          if (post.imageUrl != null) ...[
                            const SizedBox(height: 16),
                            Image.network(
                              post.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  post.likedBy.contains(currentUser?.email)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post.likedBy.contains(currentUser?.email)
                                      ? Colors.red
                                      : null,
                                ),
                                onPressed: () => _likePost(post, currentUser),
                              ),
                              Text('${post.likes}'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.comment),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context).viewInsets.bottom,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: _commentController,
                                              decoration: const InputDecoration(
                                                hintText: 'Add a comment...',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                _addComment(post, currentUser);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Comment'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Text('${post.comments.length}'),
                            ],
                          ),
                          if (post.comments.isNotEmpty) ...[
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: post.comments.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(post.comments[index]),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePostDialog(currentUser),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
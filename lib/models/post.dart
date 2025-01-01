class Post {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> comments;
  final String? imageUrl;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.imageUrl,
  });
}
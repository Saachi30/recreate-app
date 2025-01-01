class Article {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final String source;
  final String publishedAt;

  Article({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    required this.source,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      source: json['source']['name'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
    );
  }
}
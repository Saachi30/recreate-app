// news_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class Article {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final String publishedAt;

  Article({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      source: json['source']['name'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt']).toLocal().toString(),
    );
  }
}

class NewsService {
  static const String _apiKey = '64416b065d9a418d9687b7f2b4c79695';
  static const String _baseUrl = 'https://newsapi.org/v2';

  static final List<String> _searchKeywords = [
    'sustainable energy',
    'renewable energy',
    'solar energy',
    'wind energy',
    'energy productions',
    'renewable energy sources',
    'green energy',
    'sustainable energy agriculture',
    'renewable energy farming',
    'agricultural waste energy',
    'energy production companies',
    'green energy agriculture',
    'biomass energy farming'
  ];

  static Future<List<Article>> fetchArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/everything').replace(
          queryParameters: {
            'q': _searchKeywords.join(' OR '),
            'language': 'en',
            'sortBy': 'publishedAt',
            'pageSize': '6',
            'apiKey': _apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => Article.fromJson(article)).toList();
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch articles: $e');
    }
  }
}
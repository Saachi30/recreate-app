import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recmarketapp/screens/renewable_energy_ar.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/news_service.dart';
import 'contract_screen.dart';
// import 'renewable_energy_ar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:recmarketapp/screens/bill_upload_screen.dart';



final FlutterTts flutterTts = FlutterTts();
final stt.SpeechToText speech = stt.SpeechToText();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _error = '';
  int _activeTabIndex = 0;
  int? _expandedFaqIndex;
  List<Article> _articles = [];
  bool _isLoadingArticles = true;
  String _articlesError = '';
  bool _isListening = false;
  bool _blindMode = false;
  bool _isSpeaking = false;
  bool _hasAnnounced = false;

  final List<Map<String, dynamic>> methods = [
    {
      'title': 'Biogas Production',
      'description': 'Crop residues to biogas',
      'icon': '🌱',
      'details': 'Organic matter into methane'
    },
    {
      'title': 'Biomass Combustion',
      'description': 'Heat from biomass',
      'icon': '🔥',
      'details': 'Burn dry biomass for energy'
    },
    {
      'title': 'Bioethanol Conversion',
      'description': 'Waste to bioethanol',
      'icon': '🌾',
      'details': 'Ferment cellulosic waste'
    },
    {
      'title': 'Pyrolysis Process',
      'description': 'Biochar from waste',
      'icon': '⚗️',
      'details': 'Thermal decomposition process'
    },
    {
      'title': 'Syngas Generation',
      'description': 'Gasify biomass for syngas',
      'icon': '💨',
      'details': 'High-temp clean syngas'
    }
  ];

  final List<Map<String, dynamic>> benefits = [
    {
      'title': 'Reduced Fossil Fuel Dependency',
      'description': 'Switch to renewables',
      'icon': '🌍',
      'stats': '60% less fossil fuel use'
    },
    {
      'title': 'Waste Management',
      'description': 'Sustainable farm waste',
      'icon': '♻️',
      'stats': '90% waste processed'
    },
    {
      'title': 'Soil Health Improvement',
      'description': 'Better soil via biochar',
      'icon': '🌱',
      'stats': '30% more fertility'
    },
    {
      'title': 'Additional Income',
      'description': 'Earn from waste',
      'icon': '💰',
      'stats': '\$5000/year extra'
    },
    {
      'title': 'Environmental Impact',
      'description': 'Lower emissions',
      'icon': '🌿',
      'stats': '40% less emissions'
    }
  ];

  final List<Map<String, String>> faqs = [
    {
      'q': 'What are Renewable Energy Credits (RECs)?',
      'a':
          'Renewable Energy Credits (RECs) are market-based instruments that represent the environmental benefits of renewable electricity generation. Each REC represents one megawatt-hour (MWh) of renewable electricity generated and delivered to the grid.',
      'icon': '🏷️'
    },
    {
      'q': 'How does blockchain improve REC trading?',
      'a':
          'Blockchain technology enhances REC trading by providing transparent, immutable records of renewable energy generation and transactions. It eliminates double-counting, reduces fraud, enables real-time verification.',
      'icon': '⛓️'
    },
    {
      'q': 'What equipment do I need to start converting waste to energy?',
      'a':
          'The required equipment depends on your chosen conversion method. For biogas, you\'ll need an anaerobic digester. For biomass combustion, you\'ll need a biomass boiler.',
      'icon': '🔧'
    },
    {
      'q': 'How much can I earn from agricultural waste conversion?',
      'a':
          'Earnings vary based on your farm size, waste volume, and chosen conversion method. On average, farmers can generate additional income of \$3,000-\$10,000 annually.',
      'icon': '💰'
    },
    {
      'q': 'What are the environmental benefits of waste-to-energy?',
      'a':
          'Waste-to-energy conversion reduces greenhouse gas emissions, minimizes landfill waste, improves soil health through biochar application, and helps combat climate change.',
      'icon': '🌱'
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _initializeAccessibility();
  }

  Future<void> _initializeAccessibility() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await speech.initialize();
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }
  void _toggleBlindMode() async {
    setState(() {
      _blindMode = !_blindMode;
    });

    if (_isSpeaking) {
      await flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    }

    if (_blindMode) {
      setState(() {
        _isSpeaking = true;
      });
      await flutterTts.speak("Blind mode enabled. Voice commands are now active. Tap at the center of the screen to trade energy");
    }
  }

  void _announceKeyFeatures() async {
    if (!_blindMode || _isSpeaking) return;
    
    setState(() {
      _isSpeaking = true;
    });
    const announcement = "Welcome to RECreate. You can use voice commands for: Trade Energy, Upload Bills, and Redemption. Say 'help' for assistance.";
    await flutterTts.speak(announcement);
  }

  void _startListening() async {
    // Only allow voice commands in blind mode
    if (!_blindMode) return;

    if (!_isListening) {
      bool available = await speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              _handleVoiceCommand(result.recognizedWords.toLowerCase());
              setState(() => _isListening = false);
            }
          },
        );
      }
    }
  }


  void _handleVoiceCommand(String command) async {
    if (!_blindMode) return;

    setState(() {
      _isSpeaking = true;
    });

    if (command.contains('help')) {
      await flutterTts.speak("Available commands: trade energy, upload bills, redemption");
      return;
    }
    if (command.contains('trade') || command.contains('energy')) {
      _navigateToFeature(const ContractScreen());
    } else if (command.contains('upload') || command.contains('bill')) {
      _navigateToFeature(const BillUploadScreen());
    } else if (command.contains('redemption')) {
      // _navigateToFeature(const RedemptionScreen());
    }
  }

  void _navigateToFeature(Widget screen) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }
  TextStyle _getAdaptiveTextStyle({
    required double normalSize,
    required FontWeight weight,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: _blindMode ? normalSize * 1.5 : normalSize,
      fontWeight: weight,
      color: color ?? (_blindMode ? Colors.black : Colors.grey[700]),
    );
  }
  Future<void> _loadArticles() async {
    try {
      setState(() {
        _isLoadingArticles = true;
        _articlesError = '';
      });

      final articles = await NewsService.fetchArticles();

      setState(() {
        _articles = articles;
        _isLoadingArticles = false;
      });
    } catch (e) {
      setState(() {
        _articlesError = e.toString();
        _isLoadingArticles = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();

  return Scaffold(
      appBar: AppBar(
        title: const Text('RECreate'),
        actions: [
          IconButton(
            icon: Icon(_blindMode ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleBlindMode,
            tooltip: 'Toggle Blind Mode',
          ),
          if (authProvider.user == null)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              ),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: () => authProvider.logout(),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
      ]
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(seconds: 1));
        setState(() => _isLoading = false);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (authProvider.user != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Welcome, ${authProvider.user!.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            _buildHeroSection(),
            _buildArticlesSection(),
            _buildGuideSection(),
            _buildFAQSection(),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        child: const Icon(Icons.chat),
        backgroundColor: Colors.green,
      ),
  );
}

  Widget _buildArticlesSection() {
    if (_isLoadingArticles) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Articles',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const Card(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_articlesError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Articles',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _articlesError,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Latest Articles',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _loadArticles,
                child: Text(
                  'Refresh',
                  style: GoogleFonts.poppins(
                      color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8, // Adjusted for better content fit
            ),
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              final article = _articles[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          article.imageUrl,
                          height: 100, // Reduced height
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100, // Reduced height
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: GoogleFonts.poppins(
                                fontSize: 13, // Reduced font size
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                article.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 11, // Reduced font size
                                  color: Colors.grey[600],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    article.source,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  article.publishedAt.split(' ')[0],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agricultural Waste to Energy Guide',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _activeTabIndex = 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeTabIndex == 0
                        ? const Color.fromARGB(255, 58, 183, 73).withOpacity(0.6)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Conversion Methods',
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      color: _activeTabIndex == 0
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _activeTabIndex = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeTabIndex == 1
                        ? Colors.blue.withOpacity(0.6)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Benefits',
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      color: _activeTabIndex == 1
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: GridView.builder(
              key: ValueKey(_activeTabIndex),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1, // Adjusted for better content fit
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount:
                  _activeTabIndex == 0 ? methods.length : benefits.length,
              itemBuilder: (context, index) {
                final item =
                    _activeTabIndex == 0 ? methods[index] : benefits[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['icon'],
                          style: const TextStyle(fontSize: 28), // Reduced size
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 13, // Reduced font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 11, // Reduced font size
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activeTabIndex == 0
                              ? item['details']
                              : item['stats'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _expandedFaqIndex == index
                      ? Colors.grey.shade50
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (_expandedFaqIndex == index) {
                          _expandedFaqIndex = null;
                        } else {
                          _expandedFaqIndex = index;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                faqs[index]['icon']!,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  faqs[index]['q']!,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _expandedFaqIndex == index ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox(height: 0),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                left: 36,
                              ),
                              child: Text(
                                faqs[index]['a']!,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            crossFadeState: _expandedFaqIndex == index
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Handle viewing all FAQs
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening full FAQ page'),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                'View All FAQs',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Make your energy transactions',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Green',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Join RECit and convert your company to green and sustainable by buying and selling renewable energy certificates.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 20), // Add spacing
              _buildTradeEnergyButton(), // New separate button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard('40%', 'Energy Cost\nReduction', Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('10K+', 'Farmers\nBenefiting', Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('2M+', 'CO₂ Reduced\nYearly', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildTradeEnergyButton() {
  final authProvider = context.read<AuthProvider>();
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), // Increased width
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (authProvider.user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContractScreen()),
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt,
                  size: 28,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Trade Energy',
                  style: GoogleFonts.poppins(
                    fontSize: 14, // Slightly larger font size for emphasis
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildStatCard(String value, String label, MaterialColor color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on $label stats')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color[600],
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


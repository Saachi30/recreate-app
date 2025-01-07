import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/bill_upload_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/contract_screen.dart';
import 'screens/redemption_screen.dart';

// Create a global instance of FlutterTts
final FlutterTts flutterTts = FlutterTts();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize TTS
  await flutterTts.setLanguage("en-US");
  await flutterTts.setSpeechRate(0.5);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoConnect',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFE8F8F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF27AE60),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CommunityScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
    const BillUploadScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceCurrentScreen();
    });
  }

  void _announceCurrentScreen() async {
    String announcement = "You are on the ${_getScreenName(_selectedIndex)} screen. ";
    if (_selectedIndex == 0) {
      announcement += "Voice commands are now active. Tap at the center of the screen to trade energy.";
    }
    await flutterTts.speak(announcement);
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Community";
      case 2:
        return "Leaderboard";
      case 3:
        return "Profile";
      case 4:
        return "Bill Upload";
      default:
        return "Unknown";
    }
  }

  void _navigateToScreen(Widget screen) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF27AE60),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _announceCurrentScreen();
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmerEducationScreen extends StatefulWidget {
  const FarmerEducationScreen({super.key});

  @override
  State<FarmerEducationScreen> createState() => _FarmerEducationScreenState();
}

class _FarmerEducationScreenState extends State<FarmerEducationScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentQuestionIndex = 0;
  List<String> _userAnswers = [];
  bool _isPlaying = false;
  int _score = 0;
  late SharedPreferences _prefs;

  final List<Map<String, dynamic>> _questions = [
    {
      'question':
          'What is the primary benefit of converting agricultural waste to renewable energy?',
      'options': [
        'Just waste disposal',
        'Additional income through energy generation',
        'Reducing fertilizer usage',
        'Improving soil quality'
      ],
      'correctAnswer': 1,
      'explanation':
          'Converting agricultural waste to renewable energy provides farmers with an additional income stream through energy generation while also managing waste sustainably.'
    },
    {
      'question':
          'Which agricultural waste is most suitable for biogas production?',
      'options': [
        'Dry leaves and twigs',
        'Animal manure and crop residues',
        'Plastic waste',
        'Metal waste'
      ],
      'correctAnswer': 1,
      'explanation':
          'Animal manure and crop residues are ideal for biogas production as they contain organic matter that can be easily broken down by bacteria.'
    },
    {
      'question':
          'What is the first step in converting crop residue to bioenergy?',
      'options': [
        'Burning it directly',
        'Collection and proper storage',
        'Mixing with chemicals',
        'Spreading in fields'
      ],
      'correctAnswer': 1,
      'explanation':
          'Proper collection and storage of crop residue is crucial to maintain its energy potential and ensure efficient conversion to bioenergy.'
    },
    {
      'question':
          'How can farmers benefit from selling excess renewable energy to the grid?',
      'options': [
        'Through net metering benefits',
        'By getting carbon credits',
        'Through government subsidies',
        'All of the above'
      ],
      'correctAnswer': 3,
      'explanation':
          'Farmers can benefit through multiple channels: net metering benefits, carbon credits, and government subsidies for renewable energy generation.'
    },
    {
      'question':
          'What is the role of anaerobic digestion in agricultural waste management?',
      'options': [
        'It only produces fertilizer',
        'It only manages waste',
        'It produces both biogas and biofertilizer',
        'It only reduces odor'
      ],
      'correctAnswer': 2,
      'explanation':
          'Anaerobic digestion converts agricultural waste into both biogas (for energy) and biofertilizer (for soil enrichment).'
    },
    {
      'question':
          'Which renewable energy technology is most suitable for small farmers?',
      'options': [
        'Large solar farms',
        'Small biogas plants',
        'Wind turbines',
        'Hydroelectric plants'
      ],
      'correctAnswer': 1,
      'explanation':
          'Small biogas plants are ideal for small farmers as they can be operated with minimal investment and available agricultural waste.'
    },
    {
      'question':
          'What are the environmental benefits of converting agricultural waste to energy?',
      'options': [
        'Reduced greenhouse gas emissions',
        'Better waste management',
        'Improved soil health',
        'All of the above'
      ],
      'correctAnswer': 3,
      'explanation':
          'Converting agricultural waste to energy provides multiple environmental benefits including reduced emissions, better waste management, and improved soil health.'
    }
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _userAnswers = List.filled(_questions.length, '');
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _initTTS();
    _prefs = await SharedPreferences.getInstance();
    await _loadProgress();
    _initAnimation();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _userAnswers = List.filled(_questions.length, '');
  }

  Future<void> _loadProgress() async {
    _score = _prefs.getInt('quiz_score') ?? 0;
    _currentQuestionIndex = _prefs.getInt('current_question') ?? 0;
  }

  Future<void> _saveProgress() async {
    await _prefs.setInt('quiz_score', _score);
    await _prefs.setInt('current_question', _currentQuestionIndex);
  }

  Future<void> _speak(String text) async {
    if (_isPlaying) {
      await flutterTts.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    await flutterTts.speak(text);
    setState(() => _isPlaying = false);
  }

  void _checkAnswer(int selectedIndex) {
    if (_userAnswers[_currentQuestionIndex].isNotEmpty) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = selectedIndex == currentQuestion['correctAnswer'];

    setState(() {
      _userAnswers[_currentQuestionIndex] = selectedIndex.toString();
      if (isCorrect) _score += 10;
    });

    _showExplanationDialog(isCorrect, currentQuestion['explanation']);
    _saveProgress();
  }

  void _showExplanationDialog(bool isCorrect, String explanation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrect ? 'Correct!' : 'Incorrect',
          style: TextStyle(
            color: isCorrect ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(explanation),
            const SizedBox(height: 16),
            Text(
              'Current Score: $_score',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentQuestionIndex < _questions.length - 1) {
                _animationController.forward(from: 0).then((_) {
                  setState(() {
                    _currentQuestionIndex++;
                  });
                });
              } else {
                _showCompletionDialog();
              }
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    final percentage = (_score / (_questions.length * 10) * 100).round();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 70 ? Icons.emoji_events : Icons.stars,
              color: Colors.amber,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Final Score: $_score/${_questions.length * 10}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You got $percentage% correct!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              percentage >= 70
                  ? 'Congratulations! You\'re on your way to becoming a renewable energy producer!'
                  : 'Keep learning about renewable energy opportunities in farming!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentQuestionIndex = 0;
                _userAnswers = List.filled(_questions.length, '');
                _score = 0;
              });
              _saveProgress();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewable Energy Education'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Score: $_score',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentQuestion['question'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                  _isPlaying ? Icons.stop : Icons.volume_up),
                              onPressed: () =>
                                  _speak(currentQuestion['question']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...(currentQuestion['options'] as List<String>)
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected =
                              _userAnswers[_currentQuestionIndex] ==
                                  index.toString();
                          final isCorrect =
                              index == currentQuestion['correctAnswer'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? (isCorrect ? Colors.green : Colors.red)
                                      : Colors.white,
                                  foregroundColor:
                                      isSelected ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                onPressed: () => _checkAnswer(index),
                                child: Row(
                                  children: [
                                    Text(
                                      '${String.fromCharCode(65 + index)}.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        option,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    flutterTts.stop();
    super.dispose();
  }
}

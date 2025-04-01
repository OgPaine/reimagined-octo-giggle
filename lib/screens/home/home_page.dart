import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../category_data.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/theme_color_picker_dialog.dart';
import '../../../parent_auth.dart';
import 'home_app_bar.dart';
import 'home_body.dart';
import 'rotate_prompt.dart';
import 'package:gabbly/screens/settings.dart'; // Adjust path if needed

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = '';
  bool _editMode = false;
  final FlutterTts _flutterTts = FlutterTts();

  final Map<String, int> _wordUsage = {};
  int _totalWordsSpoken = 0;
  Duration _initialScreenTime = Duration.zero;
  DateTime? _sessionStartTime;
  // Statistics data is kept empty until statistics are shown.
  final Map<String, int> _usageEvents = {};
  final Map<String, int> _categoryTapCounts = {};
  final Map<String, int> _wordSequenceCounts = {};

  // New state variable for statistics display and collection
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    debugPrint("[DEBUG] HomePage initState called");
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _sessionStartTime = DateTime.now();
    debugPrint("[DEBUG] Session started at: $_sessionStartTime");
    await Future.wait([
      _initTts(),
      _ensureParentPasswordExists(),
      _loadCategories(),
      _loadStatistics(),
    ]);
    if (categories.isNotEmpty && mounted) {
      setState(() {
        _selectedCategory = categories.keys.first;
      });
      debugPrint("[DEBUG] Selected category set to: $_selectedCategory");
    }
  }

  Future<void> _initTts() async {
    // Set some default values.
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    debugPrint("[DEBUG] TTS initialized");
  }

  Future<void> _ensureParentPasswordExists() async {
    final prefs = await SharedPreferences.getInstance();
    final passwordSetupCompleted = prefs.getBool('password_setup_completed') ?? false;
    debugPrint("[DEBUG] Password setup completed: $passwordSetupCompleted");
    if (!passwordSetupCompleted) {
      if (!mounted) return;
      await showSetParentPasswordDialog(context);
      await prefs.setBool('password_setup_completed', true);
      debugPrint("[DEBUG] Parent password set and saved");
    }
  }

  Future<void> _loadCategories() async {
    final box = Hive.box('categoriesBox');
    final storedCategories = box.get('categories');
    if (storedCategories != null && storedCategories is Map) {
      categories.clear();
      final loaded = Map<String, dynamic>.from(storedCategories);
      loaded.forEach((key, value) {
        categories[key] = List<Map<String, String>>.from(
          (value as List).map((item) => Map<String, String>.from(item)),
        );
        _categoryTapCounts[key] = _categoryTapCounts[key] ?? 0;
      });
      debugPrint("[DEBUG] Categories loaded: ${categories.keys}");
    } else {
      debugPrint("[DEBUG] No stored categories found");
    }
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    _showStats = prefs.getBool('show_statistics') ?? false;
    debugPrint("[DEBUG] Loaded statistics setting: show_stats=$_showStats");
    if (!_showStats) return;
    _totalWordsSpoken = prefs.getInt('totalWordsSpoken') ?? 0;
    _initialScreenTime = Duration(milliseconds: prefs.getInt('screenTimeMillis') ?? 0);
    try {
      _wordUsage.addAll(
        Map<String, int>.from(jsonDecode(prefs.getString('wordUsage') ?? '{}')),
      );
      _categoryTapCounts.addAll(
        Map<String, int>.from(jsonDecode(prefs.getString('categoryTapCounts') ?? '{}')),
      );
      _usageEvents.addAll(
        Map<String, int>.from(jsonDecode(prefs.getString('usageEvents') ?? '{}')),
      );
      _wordSequenceCounts.addAll(
        Map<String, int>.from(jsonDecode(prefs.getString('wordSequences') ?? '{}')),
      );
      debugPrint("[DEBUG] Statistics loaded: totalWords=$_totalWordsSpoken, screenTimeMillis=${_initialScreenTime.inMilliseconds}");
    } catch (e) {
      debugPrint("[DEBUG] Error loading statistics: $e");
    }
  }

  Future<void> _persistCategories() async {
    final box = Hive.box('categoriesBox');
    await box.put('categories', categories);
    debugPrint("[DEBUG] Categories saved: ${categories.keys}");
  }

  Future<void> _persistStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_showStats) return;
    await prefs.setInt('totalWordsSpoken', _totalWordsSpoken);
    await prefs.setInt('screenTimeMillis', _getCurrentScreenTime().inMilliseconds);
    await prefs.setString('wordUsage', jsonEncode(_wordUsage));
    await prefs.setString('categoryTapCounts', jsonEncode(_categoryTapCounts));
    await prefs.setString('usageEvents', jsonEncode(_usageEvents));
    await prefs.setString('wordSequences', jsonEncode(_wordSequenceCounts));
    debugPrint("[DEBUG] Statistics persisted");
  }

  Duration _getCurrentScreenTime() {
    return _sessionStartTime != null
        ? _initialScreenTime + DateTime.now().difference(_sessionStartTime!)
        : _initialScreenTime;
  }

  void _trackWordUsage(String word) {
    _wordUsage[word] = (_wordUsage[word] ?? 0) + 1;
    _totalWordsSpoken++;
    debugPrint("[DEBUG] _trackWordUsage: '$word' count=${_wordUsage[word]}, totalWords=$_totalWordsSpoken");
  }

  void _trackCategoryTap(String category) {
    _categoryTapCounts[category] = (_categoryTapCounts[category] ?? 0) + 1;
    debugPrint("[DEBUG] _trackCategoryTap: '$category' count=${_categoryTapCounts[category]}");
  }

  void _trackWordSequence(String firstWord, String secondWord) {
    final sequence = '$firstWord -> $secondWord';
    _wordSequenceCounts[sequence] = (_wordSequenceCounts[sequence] ?? 0) + 1;
    debugPrint("[DEBUG] _trackWordSequence: '$sequence' count=${_wordSequenceCounts[sequence]}");
  }

  void _openThemePicker() {
    debugPrint("[DEBUG] Opening theme picker");
    showDialog(
      context: context,
      builder: (_) => const ThemeColorPickerDialog(),
    );
  }

  void _openSettings() {
    debugPrint("[DEBUG] Opening settings screen");
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SettingsScreen(
                initialEditMode: _editMode,
                initialShowStats: _showStats,
              )),
    ).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _editMode = prefs.getBool('edit_mode') ?? _editMode;
        _showStats = prefs.getBool('show_statistics') ?? _showStats;
      });
      debugPrint("[DEBUG] Returned from settings: edit_mode=$_editMode, show_stats=$_showStats");
    });
  }

  // Updated _speakWord function that loads TTS settings from SharedPreferences
  void _speakWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('tts_language') ?? 'en-US';
    final voice = prefs.getString('tts_voice') ?? 'Voice A (en-US)';
    final speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
    final pitch = prefs.getDouble('tts_pitch') ?? 1.0;

    await _flutterTts.setLanguage(language);
    await _flutterTts.setVoice({'name': voice, 'locale': language});
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setPitch(pitch);

    await _flutterTts.speak(word);
    _trackWordUsage(word);
    final box = Hive.box('appStateBox');
    final lastSpokenWord = box.get('lastSpokenWord');
    if (lastSpokenWord is String && lastSpokenWord.isNotEmpty) {
      _trackWordSequence(lastSpokenWord, word);
    }
    box.put('lastSpokenWord', word);
    _persistStatistics();
    debugPrint("[DEBUG] _speakWord: '$word' spoken");
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _trackCategoryTap(category);
    debugPrint("[DEBUG] Category changed to: $category");
  }

  @override
  void dispose() {
    _persistStatistics();
    debugPrint("[DEBUG] HomePage disposed. Persisted statistics.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: HomeAppBar(
        themeProvider: themeProvider,
        onSettingsPressed: _openSettings,
        onThemeChangePressed: _openThemePicker,
      ),
      body: isPortrait
          ? const RotatePrompt()
          : HomeBody(
              selectedCategory: _selectedCategory,
              editMode: _editMode,
              onCategoryChanged: _onCategoryChanged,
              onEditModeChanged: (edit) {
                setState(() {
                  _editMode = edit;
                  debugPrint("[DEBUG] Edit mode changed to: $edit");
                });
              },
              onSpeak: _speakWord,
              onDeleteCategory: (index) {
                final categoryKey = categories.keys.elementAt(index);
                setState(() {
                  categories.remove(categoryKey);
                  _selectedCategory =
                      categories.isNotEmpty ? categories.keys.first : '';
                });
                _persistCategories();
                debugPrint("[DEBUG] Deleted category: $categoryKey");
              },
              onPersistCategories: _persistCategories,
            ),
    );
  }
}

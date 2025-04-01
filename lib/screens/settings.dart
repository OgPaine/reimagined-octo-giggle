import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme_provider.dart';
import 'statistics_screen.dart';
import 'about_page.dart';
import '../../../parent_auth.dart';  // Import parent authentication helper
import '../widgets/theme_color_picker_dialog.dart';


// Helper function to convert an integer to a Roman numeral.
String intToRoman(int number) {
  final romanMap = <int, String>{
    10: 'X',
    9: 'IX',
    5: 'V',
    4: 'IV',
    1: 'I',
  };
  var result = '';
  romanMap.forEach((value, numeral) {
    while (number >= value) {
      result += numeral;
      number -= value;
    }
  });
  return result;
}

// Class to hold a voice option.
class VoiceOption {
  final String raw;   // Raw voice identifier
  final String label; // Display label (e.g., "Voice I")
  VoiceOption({required this.raw, required this.label});
}

const Map<String, String> languageDisplayNames = {
  "ar": "Arabic",
  "as-IN": "Assamese (India)",
  "bg-BG": "Bulgarian (Bulgaria)",
  "bn-BD": "Bengali (Bangladesh)",
  "bn-IN": "Bengali (India)",
  "brx-IN": "Bodo (India)",
  "bs-BA": "Bosnian (Bosnia and Herzegovina)",
  "ca-ES": "Catalan (Spain)",
  "cs-CZ": "Czech (Czech Republic)",
  "cy-GB": "Welsh (United Kingdom)",
  "da-DK": "Danish (Denmark)",
  "de-DE": "German (Germany)",
  "doi-IN": "Dogri (India)",
  "el-GR": "Greek (Greece)",
  "en-AU": "English (Australia)",
  "en-GB": "English (United Kingdom)",
  "en-IN": "English (India)",
  "en-NG": "English (Nigeria)",
  "en-US": "English (United States)",
  "es-ES": "Spanish (Spain)",
  "es-US": "Spanish (United States)",
  "et-EE": "Estonian (Estonia)",
  "fi-FI": "Finnish (Finland)",
  "fil-PH": "Filipino (Philippines)",
  "fr-CA": "French (Canada)",
  "fr-FR": "French (France)",
  "gu-IN": "Gujarati (India)",
  "he-IL": "Hebrew (Israel)",
  "hi-IN": "Hindi (India)",
  "hr-HR": "Croatian (Croatia)",
  "hu-HU": "Hungarian (Hungary)",
  "id-ID": "Indonesian (Indonesia)",
  "is-IS": "Icelandic (Iceland)",
  "it-IT": "Italian (Italy)",
  "ja-JP": "Japanese (Japan)",
  "jv-ID": "Javanese (Indonesia)",
  "km-KH": "Khmer (Cambodia)",
  "kn-IN": "Kannada (India)",
  "ko-KR": "Korean (South Korea)",
  "kok-IN": "Konkani (India)",
  "ks-IN": "Kashmiri (India)",
  "lt-LT": "Lithuanian (Lithuania)",
  "lv-LV": "Latvian (Latvia)",
  "mai-IN": "Maithili (India)",
  "ml-IN": "Malayalam (India)",
  "mni-IN": "Manipuri (India)",
  "mr-IN": "Marathi (India)",
  "ms-MY": "Malay (Malaysia)",
  "nb-NO": "Norwegian Bokmål (Norway)",
  "ne-NP": "Nepali (Nepal)",
  "nl-BE": "Dutch (Belgium)",
  "nl-NL": "Dutch (Netherlands)",
  "or-IN": "Odia (India)",
  "pa-IN": "Punjabi (India)",
  "pl-PL": "Polish (Poland)",
  "pt-BR": "Portuguese (Brazil)",
  "pt-PT": "Portuguese (Portugal)",
  "ro-RO": "Romanian (Romania)",
  "ru-RU": "Russian (Russia)",
  "sa-IN": "Sanskrit (India)",
  "sat-IN": "Santali (India)",
  "sd-IN": "Sindhi (India)",
  "si-LK": "Sinhala (Sri Lanka)",
  "sk-SK": "Slovak (Slovakia)",
  "sl-SI": "Slovenian (Slovenia)",
  "sq-AL": "Albanian (Albania)",
  "sr-RS": "Serbian (Serbia)",
  "su-ID": "Sundanese (Indonesia)",
  "sv-SE": "Swedish (Sweden)",
  "sw-KE": "Swahili (Kenya)",
  "ta-IN": "Tamil (India)",
  "te-IN": "Telugu (India)",
  "th-TH": "Thai (Thailand)",
  "tr-TR": "Turkish (Turkey)",
  "uk-UA": "Ukrainian (Ukraine)",
  "ur-IN": "Urdu (India)",
  "ur-PK": "Urdu (Pakistan)",
  "vi-VN": "Vietnamese (Vietnam)",
  "yue-HK": "Cantonese (Hong Kong)",
  "zh-CN": "Chinese (China)",
  "zh-TW": "Chinese (Taiwan)"
};

// -------------------- Settings Screen --------------------
enum SettingsSection { settings, statistics, about }

class SettingsScreen extends StatefulWidget {
  final bool initialEditMode;
  final bool initialShowStats;

  const SettingsScreen({
    super.key,
    required this.initialEditMode,
    this.initialShowStats = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsSection _selectedSection = SettingsSection.settings;
  late bool _editMode;
  late bool _showStats;
  bool _isSidebarExpanded = false;

  // -------------------- TTS-related --------------------
  List<String> _availableLanguages = [];
  String _selectedLanguage = 'en-US';

  List<dynamic>? _rawVoices;
  List<VoiceOption> _availableVoices = [];
  String _selectedVoice = 'Voice A (en-US)';

  double _speechRate = 0.5;
  double _pitch = 1.0;

  // Default values for reset
  final String _defaultLanguage = 'en-US';
  final double _defaultSpeechRate = 0.5;
  final double _defaultPitch = 1.0;

  // -------------------- Caching for Dropdown Items --------------------
  List<DropdownMenuItem<String>>? _cachedLanguageItems;
  List<DropdownMenuItem<String>>? _cachedVoiceItems;

  // We keep track of the "hash" of the current list so we only rebuild
  // dropdown items if the list changes
  int _cachedLanguagesHash = 0;
  int _cachedVoicesHash = 0;

  @override
  void initState() {
    super.initState();
    _editMode = widget.initialEditMode;
    _showStats = widget.initialShowStats;
    _loadSettings();
    _loadGoogleTtsData();
  }

  // -------------------- SharedPreferences Load/Save --------------------
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _editMode = prefs.getBool('edit_mode') ?? _editMode;
      _showStats = prefs.getBool('show_statistics') ?? _showStats;
      _selectedLanguage = prefs.getString('tts_language') ?? _selectedLanguage;
      _selectedVoice = prefs.getString('tts_voice') ?? _selectedVoice;
      _speechRate = prefs.getDouble('tts_speech_rate') ?? _speechRate;
      _pitch = prefs.getDouble('tts_pitch') ?? _pitch;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('edit_mode', _editMode);
    await prefs.setBool('show_statistics', _showStats);
    await prefs.setString('tts_language', _selectedLanguage);
    await prefs.setString('tts_voice', _selectedVoice);
    await prefs.setDouble('tts_speech_rate', _speechRate);
    await prefs.setDouble('tts_pitch', _pitch);
  }

  // -------------------- Stats load for the StatisticsScreen --------------------
  Future<Map<String, dynamic>> _loadSavedStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final totalWords = prefs.getInt('totalWordsSpoken') ?? 0;
    final screenTimeMillis = prefs.getInt('screenTimeMillis') ?? 0;
    final wordUsage = jsonDecode(prefs.getString('wordUsage') ?? '{}');
    final categoryTapCounts = jsonDecode(prefs.getString('categoryTapCounts') ?? '{}');
    final usageEvents = jsonDecode(prefs.getString('usageEvents') ?? '{}');
    final wordSequences = jsonDecode(prefs.getString('wordSequences') ?? '{}');
    return {
      'totalWords': totalWords,
      'screenTime': Duration(milliseconds: screenTimeMillis),
      'wordUsage': wordUsage,
      'categoryTapCounts': categoryTapCounts,
      'usageEvents': usageEvents,
      'wordSequences': wordSequences,
    };
  }

  // -------------------- TTS Loading --------------------
Future<void> _loadGoogleTtsData() async {
  final tts = FlutterTts();
  await tts.setEngine("com.google.android.tts");

  final rawLanguages = await tts.getLanguages;
  final rawVoices = await tts.getVoices;

  setState(() {
    // Safely cast rawLanguages to a List<dynamic> if possible, else use an empty list.
    final languagesList = rawLanguages is List ? rawLanguages : <dynamic>[];
    _availableLanguages = languagesList.map((lang) => lang.toString()).toList();
    _availableLanguages.sort();

    // If _selectedLanguage is missing, default to the first
    if (_availableLanguages.isNotEmpty &&
        !_availableLanguages.any((lang) => lang == _selectedLanguage)) {
      _selectedLanguage = _availableLanguages.first;
    }

    // Same approach for voices
    final voicesList = rawVoices is List ? rawVoices : <dynamic>[];
    _rawVoices = voicesList;
    _filterVoicesForSelectedLanguage();
  });
}

  // -------------------- Voice Filtering & Caching --------------------
  void _filterVoicesForSelectedLanguage() {
    if (_rawVoices == null) return;
    final options = <VoiceOption>[];

    for (var voice in _rawVoices!) {
      if (voice is Map) {
        // Determine if voice requires network
        final networkRaw = voice['network_required'];
        bool networkRequired = false;
        if (networkRaw is bool) {
          networkRequired = networkRaw;
        } else if (networkRaw is String) {
          networkRequired = networkRaw.toLowerCase() == 'true';
        } else if (networkRaw is int) {
          networkRequired = networkRaw != 0;
        }

        final offline = !networkRequired;
        final locale = (voice['locale'] ?? '').toString();
        if (offline && locale.toLowerCase() == _selectedLanguage.toLowerCase()) {
          final rawName = (voice['name'] ?? 'Unknown').toString();
          // Exclude voices with 'network' in their name
          if (!rawName.toLowerCase().contains("network")) {
            options.add(VoiceOption(raw: rawName, label: rawName));
          }
        }
      }
    }

    options.sort((a, b) => a.raw.compareTo(b.raw));
    // Convert each voice to "Voice I", "Voice II", etc.
    for (int i = 0; i < options.length; i++) {
      options[i] = VoiceOption(raw: options[i].raw, label: "Voice ${intToRoman(i + 1)}");
    }

    setState(() {
      _availableVoices = options;
      if (_availableVoices.isNotEmpty) {
        // If the currently selected voice isn't in the new list, pick the first
        final found = _availableVoices.any((v) => v.raw == _selectedVoice);
        if (!found) {
          _selectedVoice = _availableVoices.first.raw;
        }
      } else {
        _selectedVoice = "";
      }
    });
    // Force re-caching
    _cachedVoiceItems = null;
  }

  // Rebuild dropdown items only if the underlying data changes
  List<DropdownMenuItem<String>> _buildLanguageDropdownItems() {
    // Compute a simple hash for _availableLanguages
    final newHash = _availableLanguages.fold<int>(0, (acc, lang) => acc ^ lang.hashCode);

    if (_cachedLanguageItems != null && newHash == _cachedLanguagesHash) {
      // The list hasn't changed; reuse the cached items
      return _cachedLanguageItems!;
    }

    _cachedLanguagesHash = newHash;
    _cachedLanguageItems = _availableLanguages.map((lang) {
      final displayName = languageDisplayNames[lang] ?? lang;
      return DropdownMenuItem(
        value: lang,
        child: Text(displayName, overflow: TextOverflow.ellipsis),
      );
    }).toList();

    return _cachedLanguageItems!;
  }

  List<DropdownMenuItem<String>> _buildVoiceDropdownItems() {
    // Compute a simple hash for _availableVoices
    final newHash = _availableVoices.fold<int>(0, (acc, voice) => acc ^ voice.raw.hashCode);

    if (_cachedVoiceItems != null && newHash == _cachedVoicesHash) {
      // The list hasn't changed; reuse the cached items
      return _cachedVoiceItems!;
    }

    _cachedVoicesHash = newHash;
    _cachedVoiceItems = _availableVoices.map((option) {
      return DropdownMenuItem<String>(
        value: option.raw,
        child: Text(option.label),
      );
    }).toList();

    return _cachedVoiceItems!;
  }

  // -------------------- TTS Testing & Reset --------------------
  Future<void> _playTestSentence() async {
    final tts = FlutterTts();
    await tts.setEngine("com.google.android.tts");
    await tts.setLanguage(_selectedLanguage);
    await tts.setVoice({'name': _selectedVoice, 'locale': _selectedLanguage});
    await tts.setSpeechRate(_speechRate);
    await tts.setPitch(_pitch);
    await tts.speak("This is a test sentence.");
  }

  Future<void> _resetTtsSettings() async {
    setState(() {
      _selectedLanguage = _defaultLanguage;
      _speechRate = _defaultSpeechRate;
      _pitch = _defaultPitch;
      _selectedVoice = '';
      _availableVoices.clear();
      // Force re-caching
      _cachedLanguageItems = null;
      _cachedVoiceItems = null;
    });

    await _saveSettings();
    await _loadGoogleTtsData();

    if (_availableVoices.isNotEmpty) {
      setState(() {
        _selectedVoice = _availableVoices.first.raw;
      });
      await _saveSettings();
    }
  }

  // -------------------- Reset Parent Password & Stats --------------------
  Future<void> _resetParentPassword() async {
    await showSetParentPasswordDialog(context);
  }

  Future<void> _resetStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalWordsSpoken', 0);
    await prefs.setInt('screenTimeMillis', 0);
    await prefs.setString('wordUsage', '{}');
    await prefs.setString('categoryTapCounts', '{}');
    await prefs.setString('usageEvents', '{}');
    await prefs.setString('wordSequences', '{}');
  }

  // -------------------- Build Methods --------------------
  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryColor,
      ),
      body: Row(
        children: [
          _buildExpandableSidebar(primaryColor),
          const VerticalDivider(width: 1),
          Expanded(child: _buildSectionContent(_selectedSection)),
        ],
      ),
    );
  }

  // Expandable sidebar with items
  Widget _buildExpandableSidebar(Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 200 : 60,
      color: primaryColor.withAlpha(20),
      child: ListView(
        children: [
          _buildArrowTile(primaryColor),
          _buildSideBarItem(
            title: 'Settings',
            section: SettingsSection.settings,
            primaryColor: primaryColor,
            showText: _isSidebarExpanded,
            icon: Icons.settings,
          ),
          _buildSideBarItem(
            title: 'Statistics',
            section: SettingsSection.statistics,
            primaryColor: primaryColor,
            showText: _isSidebarExpanded,
            icon: Icons.insert_chart,
          ),
          _buildSideBarItem(
            title: 'About',
            section: SettingsSection.about,
            primaryColor: primaryColor,
            showText: _isSidebarExpanded,
            icon: Icons.info,
          ),
        ],
      ),
    );
  }

  Widget _buildArrowTile(Color primaryColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        children: [
          Icon(_isSidebarExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios),
          if (_isSidebarExpanded)
            const SizedBox(width: 8),
          if (_isSidebarExpanded)
            const Flexible(
              child: Text(
                "Collapse",
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
    );
  }

  Widget _buildSideBarItem({
    required String title,
    required SettingsSection section,
    required Color primaryColor,
    required bool showText,
    required IconData icon,
  }) {
    return ListTile(
      selected: _selectedSection == section,
      selectedTileColor: primaryColor.withAlpha(50),
      title: Row(
        children: [
          Icon(icon),
          if (showText) ...[
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ]
        ],
      ),
      onTap: () => _handleSectionTap(section),
    );
  }

  void _handleSectionTap(SettingsSection section) async {
    if (section == SettingsSection.settings) {
      setState(() => _selectedSection = section);
    } else if (section == SettingsSection.statistics) {
      final stats = await _loadSavedStatistics();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatisticsScreen(
            wordUsage: Map<String, int>.from(stats['wordUsage']),
            totalWordsSpoken: stats['totalWords'],
            screenTime: stats['screenTime'],
            usageEvents: Map<String, int>.from(stats['usageEvents']),
            categoryTapCounts: Map<String, int>.from(stats['categoryTapCounts']),
            wordSequenceCounts: Map<String, int>.from(stats['wordSequences']),
            initialStatisticsEnabled: _showStats,
          ),
        ),
      );
    } else if (section == SettingsSection.about) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AboutPage()),
      );
    }
  }

  // -------------------- Main Content for Each Section --------------------
  Widget _buildSectionContent(SettingsSection section) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section == SettingsSection.settings) ...[
            // Appearance Section
            ListTile(
              title: const Text('Appearance'),
              subtitle: const Text('Customize the app theme'),
              trailing: IconButton(
                icon: const Icon(Icons.color_lens),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ThemeColorPickerDialog(),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),

            // Edit Mode Toggle
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Edit Mode'),
              subtitle: const Text(
                'Enable to reorder or customize categories on the Home screen.',
              ),
              value: _editMode,
              onChanged: (value) async {
                setState(() => _editMode = value);
                await _saveSettings();
                if (!mounted) return;
                // If we want to pop back to the previous screen with the new edit value
                Navigator.pop(context, _editMode);
              },
            ),
            const Divider(thickness: 1),

            // Show Statistics Toggle
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Show Statistics'),
              subtitle: const Text(
                'Display comprehensive usage statistics and track data.',
              ),
              value: _showStats,
              onChanged: (value) async {
                setState(() => _showStats = value);
                await _saveSettings();
              },
            ),
            const Divider(thickness: 1),

            // Voice & Speech Settings
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(
                'Voice & Speech Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            // Language / Accent Selection
            ListTile(
              title: const Text('Language / Accent'),
              subtitle: Text(
                'Currently: ${languageDisplayNames[_selectedLanguage] ?? _selectedLanguage}',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: SizedBox(
                width: 180,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLanguage,
                  items: _buildLanguageDropdownItems(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _selectedLanguage = value);
                    await _saveSettings();
                    _filterVoicesForSelectedLanguage();
                  },
                ),
              ),
            ),

// Voice Selection
ListTile(
  title: const Text('Voice Selection'),
  subtitle: Text(
    _availableVoices.isNotEmpty
        ? 'Currently: ${_availableVoices.firstWhere(
              (v) => v.raw == _selectedVoice,
              orElse: () => _availableVoices.first,
            ).label}'
        : 'None',
    style: const TextStyle(color: Colors.grey),
  ),
  trailing: DropdownButton<String>(
    value: _selectedVoice.isEmpty && _availableVoices.isNotEmpty
        ? _availableVoices.first.raw
        : _selectedVoice,
    items: _buildVoiceDropdownItems(),
    onChanged: (value) async {
      if (value == null) return;
      setState(() => _selectedVoice = value);
      await _saveSettings();
    },
  ),
),

// Speech Rate
ListTile(
  title: const Text('Speech Rate'),
  subtitle: Slider(
    min: 0.1,
    max: 1.0,
    divisions: 9,
    value: _speechRate,
    label: _speechRate.toStringAsFixed(1),
    onChanged: (newValue) {
      setState(() => _speechRate = newValue);
    },
    onChangeEnd: (_) => _saveSettings(),
  ),
),

// Pitch Control
ListTile(
  title: const Text('Pitch Control'),
  subtitle: Slider(
    min: 0.5,
    max: 2.0,
    divisions: 15,
    value: _pitch,
    label: _pitch.toStringAsFixed(1),
    onChanged: (newValue) {
      setState(() => _pitch = newValue);
    },
    onChangeEnd: (_) => _saveSettings(),
  ),
),

// Test & Reset TTS
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Force white text & icon
          ),
          onPressed: _playTestSentence,
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text("Test", style: TextStyle(color: Colors.white)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Force white text & icon
          ),
          onPressed: _resetTtsSettings,
          icon: const Icon(Icons.restore, color: Colors.white),
          label: const Text("Reset TTS", style: TextStyle(color: Colors.white)),
        ),
      ),
    ],
  ),
),


            // Reset Statistics
            const Divider(thickness: 1),
            ListTile(
              title: const Text('Reset Statistics'),
              subtitle: const Text('Tap the info button to reset all statistics.'),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Reset'),
                      content: const Text('Are you sure you want to reset all statistics?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _resetStatistics();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Statistics have been reset.')),
                    );
                  }
                },
              ),
            ),

            // Reset Parent Password
            const Divider(thickness: 1),
            ListTile(
              title: const Text('Reset Parent Password'),
              subtitle: const Text('Reconfigure the parent password.'),
              trailing: IconButton(
                icon: const Icon(Icons.lock_reset),
                onPressed: _resetParentPassword,
              ),
            ),
          ],

          if (section == SettingsSection.statistics)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Statistics content goes here'),
            ),

          if (section == SettingsSection.about)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('About content goes here'),
            ),
        ],
      ),
    );
  }
}
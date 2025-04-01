import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicyContent(),
                const SizedBox(height: 32),
                _buildBackButton(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Privacy Policy'),
        _paragraph('Effective Date: March 23, 2025'),
        _paragraph(
          'Welcome to Gabbly! This Privacy Policy describes how your personal information is collected, used, and shared when you use our mobile application ("App").',
        ),
        ..._buildPolicySections(),
      ],
    );
  }

  List<Widget> _buildPolicySections() {
    final sections = [
      {
        'title': '1. Information We Collect',
        'content': [
          'Gabbly does not collect or transmit any personal data. All information, including user preferences, child profiles, and settings, are stored locally on your device.',
          'The App does not require or request personal information such as your name, email, phone number, or address.',
        ],
      },
      {
        'title': '2. How We Use Your Information',
        'content': [
          'Since no personal data is collected, we do not process or use your personal information in any way.',
        ],
      },
      // Add other sections here...
    ];

    return sections.expand((section) {
      return [
        _sectionTitle(section['title'] as String),
        ...(section['content'] as List<String>).map(_paragraph),
      ];
    }).toList();
  }

  Widget _buildBackButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Back',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

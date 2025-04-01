import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import '../theme/theme_provider.dart';
import 'privacy_policy_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  final String koFiUrl = "https://ko-fi.com/N4N7127TMQ";

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withAlpha((255 * 0.8).round()),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final maxWidth = constraints.maxWidth;
              final avatarRadius = maxWidth * 0.12;
              final contentWidth = maxWidth > 600 ? 600.0 : maxWidth * 0.9;

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // Logo
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage: const AssetImage('assets/images/logo.webp'),
                          backgroundColor: Colors.white,
                        ),

                        const SizedBox(height: 24),

                        // Section Title
                        _buildHeading('About Gabbly', isPortrait, fontSizePortrait: 24, fontSizeLandscape: 20),

                        const SizedBox(height: 16),

                        // Paragraphs
                        _buildParagraph(
                          'Gabbly is a free, innovative app designed to help children communicate effectively using pictures and words. Created with passion and dedication, this app supports children with speech delays by offering a simple and intuitive platform for early language development.',
                          isPortrait,
                        ),
                        _buildParagraph(
                          'Inspired by my own experience with my 3-year-old who is verbally delayed, I developed Gabbly to bridge communication gaps and make daily interactions smoother and more joyful.',
                          isPortrait,
                        ),
                        _buildParagraph(
                          'Your feedback and support are invaluable. Please feel free to reach out with any suggestions or questions. Together, we can make communication more accessible for every child.',
                          isPortrait,
                        ),

                        const SizedBox(height: 32),

                        // Footer Credit
                        const Text(
                          'Made by Prism Designs',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Support Button
                        Link(
                          uri: Uri.parse(koFiUrl),
                          target: LinkTarget.blank,
                          builder: (BuildContext context, FollowLink? openLink) {
                            return ElevatedButton.icon(
                              onPressed: openLink,
                              icon: const Icon(Icons.attach_money, color: Colors.white),
                              label: const Text(
                                'Support on Ko‑fi',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black26,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                minimumSize: Size(
                                  isPortrait ? 200 : 150,
                                  48,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Privacy Policy Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                            );
                          },
                          icon: const Icon(Icons.privacy_tip, color: Colors.white),
                          label: const Text(
                            'Privacy Policy',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black26,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            minimumSize: Size(isPortrait ? 200 : 150, 48),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(String text, bool isPortrait, {double fontSizePortrait = 24, double fontSizeLandscape = 20}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isPortrait ? fontSizePortrait : fontSizeLandscape,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildParagraph(String text, bool isPortrait) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isPortrait ? 16 : 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

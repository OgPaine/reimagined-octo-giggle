import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart'; // This file should export a Riverpod provider named themeProviderRiverpod

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool showSwipeHint = true;
  bool passwordSet = false;
  final introKey = GlobalKey<IntroductionScreenState>();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showSwipeHint = false);
    });
  }

  List<PageViewModel> _buildPages(Color primaryColor) {
    const iconSize = 100.0;

    return [
      PageViewModel(
        title: "Welcome to Gabbly",
        body:
            "Gabbly is a customizable communication aid designed to help users express themselves using words and images. Great for speech therapy, AAC, or everyday support.",
        image: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/logo.webp',
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[ERROR] Failed to load logo image: $error');
              return const Icon(Icons.broken_image, size: 100, color: Colors.white);
            },
          ),
        ),
        decoration: _pageDecoration(primaryColor),
      ),
      PageViewModel(
        title: "Best Viewed in Landscape",
        body:
            "For the best experience, rotate your phone to landscape mode. This layout helps display more categories and words comfortably.",
        image: const Icon(Icons.screen_rotation, size: iconSize, color: Colors.white),
        decoration: _pageDecoration(primaryColor),
      ),
      PageViewModel(
        title: "Settings Overview",
        body:
            "Tap the ⚙️ settings icon in the top-right corner to manage app preferences. You can enable edit mode, view usage statistics, or access About and Privacy Policy screens.",
        image: const Icon(Icons.settings, size: iconSize, color: Colors.white),
        decoration: _pageDecoration(primaryColor),
      ),
      PageViewModel(
        title: "Edit Mode & Gestures",
        bodyWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Turn on Edit Mode in",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Row(
              children: const [
                Icon(Icons.settings, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text("Settings to customize everything.", style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "• Tap and drag to reorganize words and categories.\n"
              "• Double tap a word to edit it: rename, change image, switch category, or delete it.\n",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Row(
              children: const [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text("Tap to add new words.", style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "• Double tap a category name to rename or delete it.\n\n"
              "Tip: Use landscape mode for the best editing experience.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        image: const Icon(Icons.touch_app, size: iconSize, color: Colors.white),
        decoration: _pageDecoration(primaryColor),
      ),
      PageViewModel(
        titleWidget: const Text("Set Parent Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        bodyWidget: SetParentPasswordWidget(onPasswordSet: () {
          setState(() => passwordSet = true);
        }),
        decoration: _pageDecoration(primaryColor),
        image: const Icon(Icons.lock_person, size: iconSize, color: Colors.white),
      ),
      PageViewModel(
        title: "Versions",
        body: "See the available versions and compatibility.",
        image: const Icon(Icons.system_update, size: iconSize, color: Colors.white),
        decoration: _pageDecoration(primaryColor),
      ),
      PageViewModel(
        title: "Scores",
        body: "Learn how scoring works in the app.",
        image: const Icon(Icons.star_rate, size: iconSize, color: Colors.white),
        decoration: _pageDecoration(primaryColor),
      ),
    ];
  }

  PageDecoration _pageDecoration(Color color) {
    return const PageDecoration(
      pageColor: Colors.transparent,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      bodyTextStyle: TextStyle(fontSize: 16, color: Colors.white),
      imagePadding: EdgeInsets.only(top: 16, bottom: 24),
      bodyPadding: EdgeInsets.symmetric(horizontal: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.watch(themeProviderRiverpod);
    final primaryColor = themeNotifier.primaryColor;
    final pages = _buildPages(primaryColor);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withAlpha(242), primaryColor.withAlpha(178)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            IntroductionScreen(
              key: introKey,
              globalBackgroundColor: Colors.transparent,
              pages: pages,
              showBackButton: true,
              showSkipButton: true,
              skip: const Text("Skip", style: TextStyle(color: Colors.white)),
              next: (currentIndex == 4 && !passwordSet)
                  ? const SizedBox.shrink()
                  : const Icon(Icons.arrow_forward, color: Colors.white),
              back: const Icon(Icons.arrow_back, color: Colors.white),
              done: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              freeze: (currentIndex == 4 && !passwordSet),
              onDone: () async {
                final prefs = await SharedPreferences.getInstance();
                if (!mounted) return;
                await prefs.setBool('onboarding_complete', true);
                widget.onDone();
              },
              onSkip: () async {
                final prefs = await SharedPreferences.getInstance();
                if (!mounted) return;
                await prefs.setBool('onboarding_complete', true);
                widget.onDone();
              },
              onChange: (index) async {
                setState(() => currentIndex = index);
                if (index == pages.length - 1) {
                  final prefs = await SharedPreferences.getInstance();
                  if (!mounted) return;
                  await prefs.setBool('onboarding_complete', true);
                  widget.onDone();
                }
              },
              isProgressTap: false,
              isProgress: true,
              dotsDecorator: const DotsDecorator(
                activeColor: Colors.white,
                size: Size.square(8.0),
                activeSize: Size(24.0, 8.0),
                spacing: EdgeInsets.symmetric(horizontal: 3.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                color: Colors.white30,
              ),
            ),
            if (showSwipeHint)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => showSwipeHint = false),
                  child: Container(
                    color: Colors.black.withAlpha(102),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swipe, size: 60, color: Colors.white),
                          SizedBox(height: 16),
                          Text('Swipe to continue', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SetParentPasswordWidget extends StatefulWidget {
  final VoidCallback onPasswordSet;
  const SetParentPasswordWidget({super.key, required this.onPasswordSet});

  @override
  State<SetParentPasswordWidget> createState() => _SetParentPasswordWidgetState();
}

class _SetParentPasswordWidgetState extends State<SetParentPasswordWidget> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Create a parent password to lock settings and prevent unwanted changes.",
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter password',
            errorText: _error,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final password = _controller.text.trim();
            if (password.length < 4) {
              setState(() => _error = "Password must be at least 4 characters");
              return;
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('parent_password', password);
            await prefs.setBool('password_setup_completed', true);

            if (!mounted) return;
            setState(() => _error = null);
            widget.onPasswordSet();

            messenger.showSnackBar(
              const SnackBar(content: Text("Password saved")),
            );
          },
          child: const Text("Save Password"),
        ),
      ],
    );
  }
}

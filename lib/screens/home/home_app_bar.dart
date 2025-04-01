import 'package:flutter/material.dart';
import '../../theme/theme_provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeProvider themeProvider;
  final VoidCallback onSettingsPressed;
  final VoidCallback onThemeChangePressed;

  const HomeAppBar({
    super.key,
    required this.themeProvider,
    required this.onSettingsPressed,
    required this.onThemeChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: themeProvider.primaryColor,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.webp',
            height: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'Gabbly',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.color_lens),
          onPressed: onThemeChangePressed,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}

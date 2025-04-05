import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home/home_page.dart';
import 'screens/onboarding_screen.dart';
import 'theme/theme_provider.dart';
import 'models/onboarding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('categoriesBox');
  await Hive.openBox('appStateBox');
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingProvider);
    final themeProvider = ref.watch(themeProviderRiverpod);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: onboardingComplete
          ? const HomePage()
          : OnboardingScreen(
              onDone: () => ref.read(onboardingProvider.notifier).completeOnboarding(),
            ),
    );
  }
}

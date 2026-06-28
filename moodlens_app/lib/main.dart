import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'theme/mood_theme.dart';
import 'services/analytics_depth_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().ensureAnonymousLogin();

  await ThemeService.loadTheme();
  await AnalyticsDepthService.loadDepth();

  runApp(const MoodLensApp());
}

class MoodLensApp extends StatelessWidget {
  const MoodLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MoodThemes.neutral.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MoodThemes.neutral.accent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

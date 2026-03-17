import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/paper_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/entries_provider.dart';
import 'services/groq_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await GroqService.init();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: NourishApp()));
}

class NourishApp extends StatelessWidget {
  const NourishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nourish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black87,
          surface: const Color(0xFFFAF9F6),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _showOnboarding = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final dailyGoal = prefs.getInt('daily_goal') ?? 2000;
    
    ref.read(dailyGoalProvider.notifier).state = dailyGoal;
    
    setState(() {
      _showOnboarding = !onboardingComplete;
      _loading = false;
    });
  }

  void _onOnboardingComplete() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF9F6),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black87,
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    return const PaperScreen();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/paper_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: SpinoApp()));
}

class SpinoApp extends StatelessWidget {
  const SpinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          surface: const Color(0xFFFAF9F6),
        ),
      ),
      home: const PaperScreen(),
    );
  }
}

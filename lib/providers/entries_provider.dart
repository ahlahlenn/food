import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_entry.dart';
import '../services/storage_service.dart';
import '../services/groq_service.dart';

// Entries provider
final entriesProvider = StateNotifierProvider<EntriesNotifier, List<FoodEntry>>((ref) {
  return EntriesNotifier();
});

class EntriesNotifier extends StateNotifier<List<FoodEntry>> {
  EntriesNotifier() : super([]) {
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    state = await StorageService.loadEntries();
  }

  Future<void> addEntry(String text) async {
    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    
    state = [entry, ...state];
    
    // Parse with Groq
    final parsed = await GroqService.parseFoodEntry(text);
    final updated = entry.copyWith(
      calories: parsed['calories'] ?? 0,
      protein: parsed['protein'] ?? 0,
      carbs: parsed['carbs'] ?? 0,
      fat: parsed['fat'] ?? 0,
      isLoading: false,
    );

    state = state.map((e) => e.id == entry.id ? updated : e).toList();
    await StorageService.saveEntries(state);
  }

  Future<void> updateEntry(String id, String text) async {
    final index = state.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final oldEntry = state[index];
    final updated = oldEntry.copyWith(text: text, isLoading: true);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];

    // Re-parse
    final parsed = await GroqService.parseFoodEntry(text);
    final finalEntry = updated.copyWith(
      calories: parsed['calories'] ?? 0,
      protein: parsed['protein'] ?? 0,
      carbs: parsed['carbs'] ?? 0,
      fat: parsed['fat'] ?? 0,
      isLoading: false,
    );

    state = state.map((e) => e.id == id ? finalEntry : e).toList();
    await StorageService.saveEntries(state);
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await StorageService.saveEntries(state);
  }
}

// Daily totals provider
final dailyTotalsProvider = Provider<Map<String, int>>((ref) {
  final entries = ref.watch(entriesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  final todayEntries = entries.where((e) => e.timestamp.isAfter(today) && !e.isLoading);
  
  int calories = 0, protein = 0, carbs = 0, fat = 0;
  for (final e in todayEntries) {
    calories += e.calories;
    protein += e.protein;
    carbs += e.carbs;
    fat += e.fat;
  }
  
  return {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
});

// Streak provider
final streakProvider = FutureProvider<int>((ref) async {
  return StorageService.getStreak();
});

// Daily goal (default 2000)
final dailyGoalProvider = StateProvider<int>((ref) => 2000);

// Voice recording state
final isRecordingProvider = StateProvider<bool>((ref) => false);

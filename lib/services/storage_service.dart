import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_entry.dart';

class StorageService {
  static const String _entriesKey = 'food_entries';

  static Future<List<FoodEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_entriesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => FoodEntry.fromJson(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> saveEntries(List<FoodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, data);
  }

  static Future<void> addEntry(FoodEntry entry) async {
    final entries = await loadEntries();
    entries.insert(0, entry);
    await saveEntries(entries);
  }

  static Future<void> updateEntry(FoodEntry entry) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      entries[index] = entry;
      await saveEntries(entries);
    }
  }

  static Future<void> deleteEntry(String id) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.id == id);
    await saveEntries(entries);
  }

  static Future<List<FoodEntry>> getTodayEntries() async {
    final entries = await loadEntries();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return entries.where((e) => e.timestamp.isAfter(today)).toList();
  }

  static Future<int> getStreak() async {
    final entries = await loadEntries();
    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final hasEntry = entries.any((e) => 
        e.timestamp.isAfter(dayStart) && 
        e.timestamp.isBefore(dayStart.add(const Duration(days: 1)))
      );

      if (hasEntry) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (streak == 0 && checkDate.day == DateTime.now().day) {
        // Check yesterday if no entry today yet
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

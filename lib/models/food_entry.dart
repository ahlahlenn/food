class FoodEntry {
  final String id;
  final String text;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime timestamp;
  final bool isLoading;

  FoodEntry({
    required this.id,
    required this.text,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.timestamp,
    this.isLoading = false,
  });

  FoodEntry copyWith({
    String? id,
    String? text,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
    id: json['id'],
    text: json['text'],
    calories: json['calories'] ?? 0,
    protein: json['protein'] ?? 0,
    carbs: json['carbs'] ?? 0,
    fat: json['fat'] ?? 0,
    timestamp: DateTime.parse(json['timestamp']),
  );
}

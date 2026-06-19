class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final double carbs;
  final double protein;
  final double fat;
  final DateTime timestamp;
  final String? imagePath;

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      carbs: json['carbs'],
      protein: json['protein'],
      fat: json['fat'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
    );
  }
}

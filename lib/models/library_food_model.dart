class LibraryFood {
  final String name;
  final String category;
  final String imagePath;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final List<String> vitamins;
  final String benefits;

  LibraryFood({
    required this.name,
    required this.category,
    required this.imagePath,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.vitamins,
    required this.benefits,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'imagePath': imagePath,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
      'vitamins': vitamins,
      'benefits': benefits,
    };
  }

  factory LibraryFood.fromJson(Map<String, dynamic> json) {
    return LibraryFood(
      name: json['name'],
      category: json['category'],
      imagePath: json['imagePath'],
      calories: json['calories'],
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      vitamins: List<String>.from(json['vitamins']),
      benefits: json['benefits'],
    );
  }
}

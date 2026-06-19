class UserProfile {
  String name;
  String email;
  int age;
  String gender;
  double height; // in cm
  double weight; // in kg
  String goal; // 'loss', 'gain', 'maintain'
  String healthCondition; // 'diabetes', 'high_bp', 'cholesterol', 'none'

  double bmi;
  String bmiCategory;
  int dailyCalorieRequirement;

  UserProfile({
    required this.name,
    this.email = '',
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.goal,
    required this.healthCondition,
    this.bmi = 0.0,
    this.bmiCategory = '',
    this.dailyCalorieRequirement = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'goal': goal,
      'healthCondition': healthCondition,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'dailyCalorieRequirement': dailyCalorieRequirement,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      email: json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      goal: json['goal'],
      healthCondition: json['healthCondition'],
      bmi: json['bmi'] ?? 0.0,
      bmiCategory: json['bmiCategory'] ?? '',
      dailyCalorieRequirement: json['dailyCalorieRequirement'] ?? 0,
    );
  }
}

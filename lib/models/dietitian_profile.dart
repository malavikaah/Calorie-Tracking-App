class DietitianProfile {
  final String name;
  final String specialization;
  final String education;
  final String experience;
  final String bio;
  final String? certificateUrl;
  final bool isApproved;

  DietitianProfile({
    required this.name,
    required this.specialization,
    required this.education,
    required this.experience,
    required this.bio,
    this.certificateUrl,
    this.isApproved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'education': education,
      'experience': experience,
      'bio': bio,
      'certificateUrl': certificateUrl,
      'isApproved': isApproved,
    };
  }

  factory DietitianProfile.fromJson(Map<String, dynamic> json) {
    return DietitianProfile(
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      education: json['education'] ?? '',
      experience: json['experience'] ?? '',
      bio: json['bio'] ?? '',
      certificateUrl: json['certificateUrl'],
      isApproved: json['isApproved'] ?? false,
    );
  }
}

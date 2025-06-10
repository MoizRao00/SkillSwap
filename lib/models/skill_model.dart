class Skill {
  final String id;      // Firestore document ID
  final String name;    // Skill ka naam

  Skill({required this.id, required this.name});

  // Firestore document se map banane ke liye
  factory Skill.fromMap(String id, Map<String, dynamic> data) {
    return Skill(
      id: id,
      name: data['name'] ?? '',
    );
  }

  // Skill ko Firestore me save karne ke liye map me convert karo

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}

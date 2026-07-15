class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String? email;

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserProfile(
        id: '',
        name: '',
        phone: '',
        role: 'passenger',
      );
    }

    final emailValue = json['email']?.toString().trim();

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'passenger',
      email: emailValue == null || emailValue.isEmpty
          ? null
          : emailValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'email': email,
    };
  }
}
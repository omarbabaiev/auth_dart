class User {
  final int? id;
  final String email;
  final String username;
  final String passwordHash;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final String? bio;
  final String? avatarUrl;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.email,
    required this.username,
    required this.passwordHash,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.bio,
    this.avatarUrl,
    this.isActive = true,
    this.isEmailVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'password_hash': passwordHash,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'bio': bio,
      'avatar_url': avatarUrl,
      'is_active': isActive ? 1 : 0,
      'is_email_verified': isEmailVerified ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      passwordHash: map['password_hash'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      phoneNumber: map['phone_number'],
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      address: map['address'],
      city: map['city'],
      country: map['country'],
      bio: map['bio'],
      avatarUrl: map['avatar_url'],
      isActive: map['is_active'] == 1,
      isEmailVerified: map['is_email_verified'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'bio': bio,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePhoto,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profilePhoto;

  bool get isCustomer => role == 'customer';
  bool get isBarber => role == 'barber';
  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';
  bool get isReception => role == 'reception';
  bool get isShopStaff => isBarber || isOwner || isReception;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
      role: _normalizeRole(json['role']?.toString()),
      profilePhoto: json['profileImage']?.toString() ??
          json['profilePhoto']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        if (profilePhoto != null) 'profilePhoto': profilePhoto,
      };

  UserProfile copyWith({
    String? name,
    String? phone,
    String? profilePhoto,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        profilePhoto: profilePhoto ?? this.profilePhoto,
      );

  static String _normalizeRole(String? raw) => switch ((raw ?? '').toUpperCase()) {
        'CLIENT' => 'customer',
        'BARBER' => 'barber',
        'ADMIN' => 'admin',
        'OWNER' => 'owner',
        'RECEPTION' => 'reception',
        _ => (raw ?? 'customer').toLowerCase(),
      };
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken']?.toString() ?? '',
        refreshToken: json['refreshToken']?.toString() ?? '',
      );
}

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;
  Map<String, dynamic> toJson() => {'identifier': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  Map<String, dynamic> toJson() => {
        'fullName': name,
        'email': email,
        if (phone.isNotEmpty) 'phoneNumber': phone,
        'password': password,
        'role': role.toUpperCase() == 'BARBER'
            ? 'BARBER'
            : role.toUpperCase() == 'ADMIN'
                ? 'ADMIN'
                : 'CLIENT',
      };
}

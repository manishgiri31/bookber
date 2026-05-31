class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.userId,
  });

  final bool isAuthenticated;
  final String? userId;

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
    );
  }

  static const unauthenticated = AuthState(isAuthenticated: false);
}

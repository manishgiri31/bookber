import '../../../core/models/bookber_models.dart';

enum UserRole { customer, barber, admin }

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.barber:
        return 'barber';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole? fromValue(String? value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'barber':
        return UserRole.barber;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}

sealed class AuthState {
  const AuthState();

  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isLoading => this is AuthLoading;
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserProfile user;
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

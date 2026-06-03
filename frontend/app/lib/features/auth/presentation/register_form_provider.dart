import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bookber_models.dart';
import '../domain/auth_state.dart';

class RegisterFormState {
  const RegisterFormState({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.role = UserRole.customer,
    this.specializations = const <String>{},
    this.bio = '',
    this.experienceYears = '',
    this.neighborhood = '',
    this.preferences = const <String>{},
    this.notificationsEnabled = true,
    this.currentStep = 1,
    this.totalSteps = 2,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final UserRole role;
  final Set<String> specializations;
  final String bio;
  final String experienceYears;
  final String neighborhood;
  final Set<String> preferences;
  final bool notificationsEnabled;
  final int currentStep;
  final int totalSteps;

  RegisterFormState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    UserRole? role,
    Set<String>? specializations,
    String? bio,
    String? experienceYears,
    String? neighborhood,
    Set<String>? preferences,
    bool? notificationsEnabled,
    int? currentStep,
    int? totalSteps,
  }) {
    return RegisterFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      role: role ?? this.role,
      specializations: specializations ?? this.specializations,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      neighborhood: neighborhood ?? this.neighborhood,
      preferences: preferences ?? this.preferences,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  bool validateCurrentStep({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String experienceYears,
  }) {
    if (currentStep == 1) {
      if (fullName.trim().isEmpty) return false;
      if (email.trim().isEmpty || !email.contains('@')) return false;
      if (phone.trim().isEmpty) return false;
      if (password.length < 6) return false;
      if (confirmPassword != password) return false;
      if (role == UserRole.barber && experienceYears.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  RegisterRequest buildRegisterRequest({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return RegisterRequest(
      name: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
      role: role.value,
    );
  }
}

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  RegisterFormNotifier() : super(const RegisterFormState());

  void updateFullName(String value) {
    state = state.copyWith(fullName: value);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updatePhone(String value) {
    state = state.copyWith(phone: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  void updateRole(UserRole value) {
    state = state.copyWith(role: value, currentStep: 1);
  }

  void toggleSpecialization(String specialization) {
    final newSpecializations = Set<String>.from(state.specializations);
    if (newSpecializations.contains(specialization)) {
      newSpecializations.remove(specialization);
    } else {
      newSpecializations.add(specialization);
    }
    state = state.copyWith(specializations: newSpecializations);
  }

  void updateBio(String value) {
    state = state.copyWith(bio: value);
  }

  void updateExperienceYears(String value) {
    state = state.copyWith(experienceYears: value);
  }

  void updateNeighborhood(String value) {
    state = state.copyWith(neighborhood: value);
  }

  void togglePreference(String preference) {
    final newPreferences = Set<String>.from(state.preferences);
    if (newPreferences.contains(preference)) {
      newPreferences.remove(preference);
    } else {
      newPreferences.add(preference);
    }
    state = state.copyWith(preferences: newPreferences);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = const RegisterFormState();
  }

  RegisterRequest buildRegisterRequest({
    String? fullName,
    String? email,
    String? phone,
    String? password,
  }) {
    return state.buildRegisterRequest(
      fullName: fullName ?? state.fullName,
      email: email ?? state.email,
      phone: phone ?? state.phone,
      password: password ?? state.password,
    );
  }
}

final registerFormProvider =
    StateNotifierProvider<RegisterFormNotifier, RegisterFormState>(
  (ref) => RegisterFormNotifier(),
);

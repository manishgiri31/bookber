import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/auth_layout.dart';
import '../../../core/widgets/auth_input_field.dart';
import '../../../core/widgets/role_selector.dart';
import '../../../core/widgets/multi_select_chip.dart';
import '../../../core/widgets/step_progress_indicator.dart';
import '../../../core/utils/snackbar.dart';
import '../domain/auth_state.dart';
import 'register_form_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  
  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _bioError;
  String? _experienceError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  void _validateFullName() {
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _fullNameError = 'Full name is required');
    } else {
      setState(() => _fullNameError = null);
    }
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
    } else {
      setState(() => _emailError = null);
    }
  }

  void _validatePhone() {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
    } else {
      setState(() => _phoneError = null);
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
    } else {
      setState(() => _passwordError = null);
    }
  }

  void _validateConfirmPassword() {
    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
    } else if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
    } else {
      setState(() => _confirmPasswordError = null);
    }
  }

  void _validateExperience() {
    if (_experienceController.text.trim().isEmpty) {
      setState(() => _experienceError = 'Experience is required');
    } else {
      setState(() => _experienceError = null);
    }
  }

  Future<void> _handleContinue() async {
    final formState = ref.read(registerFormProvider);
    
    if (formState.currentStep == 1) {
      _validateFullName();
      _validateEmail();
      _validatePhone();
      _validatePassword();
      _validateConfirmPassword();

      if (formState.role == UserRole.barber) {
        _validateExperience();
      }

      if (_fullNameError == null &&
          _emailError == null &&
          _phoneError == null &&
          _passwordError == null &&
          _confirmPasswordError == null &&
          (formState.role == UserRole.customer || _experienceError == null)) {
        ref.read(registerFormProvider.notifier).nextStep();
      }
    } else {
      await _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    final formState = ref.read(registerFormProvider);
    final request = ref.read(registerFormProvider.notifier).buildRegisterRequest(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

    await ref.read(authControllerProvider.notifier).register(request);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    // TODO: Handle image upload
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is AuthError && mounted) {
        BookerSnackbar.error(context, next.message);
      }
    });

    final formState = ref.watch(registerFormProvider);
    final authState = ref.watch(authControllerProvider);

    return AuthLayout(
      child: Column(
        children: [
          // Progress Indicator
          StepProgressIndicator(
            currentStep: formState.currentStep,
            totalSteps: formState.totalSteps,
          ),
          const SizedBox(height: 24),

          // Role Selector (only on step 1)
          if (formState.currentStep == 1) ...[
            RoleSelector(
              selectedRole: formState.role,
              onChanged: (role) {
                ref.read(registerFormProvider.notifier).updateRole(role);
                setState(() {
                  _experienceError = null;
                });
              },
            ),
            const SizedBox(height: 24),
          ],

          // Form Content
          if (formState.currentStep == 1) _buildStep1(formState),
          if (formState.currentStep == 2) _buildStep2(formState),

          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: authState.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: BBColors.brandPrimary,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _handleContinue,
                    child: Text(
                      formState.currentStep == 1 ? 'Continue' : 'Create Account',
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Back Button (step 2 only)
          if (formState.currentStep == 2)
            TextButton(
              onPressed: () => ref.read(registerFormProvider.notifier).previousStep(),
              child: Text('Back'),
            ),

          if (formState.currentStep == 1)
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: BBTypography.bodyM.copyWith(
                        color: context.bbColors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: BBTypography.labelM.copyWith(
                            color: BBColors.brandPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1(RegisterFormState formState) {
    return Column(
      children: [
        AuthInputField(
          label: 'Full Name',
          controller: _fullNameController,
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          errorText: _fullNameError,
          onChanged: (_) => setState(() => _fullNameError = null),
        ),
        const SizedBox(height: 16),
        AuthInputField(
          label: 'Email',
          controller: _emailController,
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _emailError,
          onChanged: (_) => setState(() => _emailError = null),
        ),
        const SizedBox(height: 16),
        AuthInputField(
          label: 'Phone Number',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          errorText: _phoneError,
          onChanged: (_) => setState(() => _phoneError = null),
        ),
        const SizedBox(height: 16),
        AuthInputField(
          label: 'Password',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.next,
          errorText: _passwordError,
          onChanged: (_) => setState(() => _passwordError = null),
        ),
        const SizedBox(height: 16),
        AuthInputField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.done,
          errorText: _confirmPasswordError,
          onChanged: (_) => setState(() => _confirmPasswordError = null),
          onSubmitted: (_) => _handleContinue(),
        ),
        if (formState.role == UserRole.barber) ...[
          const SizedBox(height: 16),
          AuthInputField(
            label: 'Years of Experience',
            controller: _experienceController,
            prefixIcon: Icons.work_outline,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            errorText: _experienceError,
            onChanged: (_) => setState(() => _experienceError = null),
            onSubmitted: (_) => _handleContinue(),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2(RegisterFormState formState) {
    if (formState.role == UserRole.customer) {
      return _buildCustomerStep2(formState);
    } else {
      return _buildBarberStep2(formState);
    }
  }

  Widget _buildCustomerStep2(RegisterFormState formState) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What services do you usually get?',
          style: BBTypography.labelM.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        MultiSelectChip(
          options: const ['Haircut', 'Beard Trim', 'Shave', 'Fade', 'Color', 'Kids Cut'],
          selectedOptions: formState.preferences,
          onSelectionChanged: (selected) {
            ref.read(registerFormProvider.notifier).state = formState.copyWith(preferences: selected);
          },
        ),
        const SizedBox(height: 24),
        AuthInputField(
          label: 'Your Neighborhood',
          controller: _neighborhoodController,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          onChanged: (value) => ref.read(registerFormProvider.notifier).updateNeighborhood(value),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enable Notifications',
              style: BBTypography.labelM.copyWith(color: colors.textPrimary),
            ),
            Switch(
              value: formState.notificationsEnabled,
              onChanged: (value) =>
                  ref.read(registerFormProvider.notifier).toggleNotifications(),
              activeColor: BBColors.brandPrimary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _handleRegister,
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildBarberStep2(RegisterFormState formState) {
    final colors = context.bbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializations',
          style: BBTypography.labelM.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        MultiSelectChip(
          options: const ['Haircut', 'Beard Trim', 'Shave', 'Fade', 'Color', 'Kids Cut'],
          selectedOptions: formState.specializations,
          onSelectionChanged: (selected) {
            ref.read(registerFormProvider.notifier).state = formState.copyWith(specializations: selected);
          },
        ),
        const SizedBox(height: 24),
        AuthInputField(
          label: 'Bio / About',
          controller: _bioController,
          maxLines: 4,
          maxLength: 200,
          errorText: _bioError,
          onChanged: (value) {
            ref.read(registerFormProvider.notifier).updateBio(value);
            setState(() => _bioError = null);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Profile Photo',
          style: BBTypography.labelM.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border, width: 2),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

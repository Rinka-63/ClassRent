import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_mark.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isRegister;

  const LoginScreen({super.key, this.isRegister = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _agencyEmailController = TextEditingController();
  final _agencyPhoneController = TextEditingController();
  final _agencyAddressController = TextEditingController();
  final _agencyCityController = TextEditingController();
  final _agencyDescriptionController = TextEditingController();

  late bool _isRegisterMode;
  bool _isPasswordVisible = false;
  RegistrationType _registrationType = RegistrationType.user;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.isRegister;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _agencyNameController.dispose();
    _agencyEmailController.dispose();
    _agencyPhoneController.dispose();
    _agencyAddressController.dispose();
    _agencyCityController.dispose();
    _agencyDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegisterMode) {
      await controller.register(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        type: _registrationType,
        agencyName: _agencyNameController.text,
        agencyEmail: _agencyEmailController.text,
        agencyPhone: _agencyPhoneController.text,
        agencyAddress: _agencyAddressController.text,
        agencyCity: _agencyCityController.text,
        agencyDescription: _agencyDescriptionController.text,
      );
      return;
    }

    await controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _forgotPassword() async {
    final strings = AppStrings.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.tr(
                'Masukkan email yang valid untuk reset sandi.',
                'Enter a valid email to reset your password.',
              ),
            ),
          ),
        );
      }
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).resetPassword(email);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Email reset sandi telah dikirim. Cek inbox Anda.',
              'Password reset email has been sent. Check your inbox.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppBrandMark(size: 72)),
                  const SizedBox(height: 24),
                  Text(
                    _isRegisterMode
                        ? strings.tr('Buat Akun Baru', 'Create New Account')
                        : strings.tr(
                            'Selamat Datang Kembali',
                            'Welcome Back',
                          ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegisterMode
                        ? strings.tr(
                            'Daftar untuk menikmati layanan ClassRent.',
                            'Register to enjoy ClassRent services.',
                          )
                        : strings.tr(
                            'Masuk dengan email dan kata sandi Anda.',
                            'Sign in with your email and password.',
                          ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        children: [
                          if (_isRegisterMode) ...[
                            SegmentedButton<RegistrationType>(
                              segments: [
                                ButtonSegment(
                                  value: RegistrationType.user,
                                  label: Text(strings.tr('Penyewa', 'Tenant')),
                                  icon: const Icon(Icons.person_outline),
                                ),
                                ButtonSegment(
                                  value: RegistrationType.agencyAdmin,
                                  label: Text(strings.tr('Agensi', 'Agency')),
                                  icon: const Icon(Icons.apartment_outlined),
                                ),
                              ],
                              selected: {_registrationType},
                              onSelectionChanged: (selection) {
                                setState(
                                    () => _registrationType = selection.first);
                              },
                              style: SegmentedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _fullNameController,
                              label: strings.tr('Nama Lengkap', 'Full Name'),
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (!_isRegisterMode) return null;
                                if (value == null || value.trim().length < 3) {
                                  return strings.tr(
                                    'Masukkan nama lengkap Anda.',
                                    'Enter your full name.',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_registrationType ==
                                RegistrationType.agencyAdmin) ...[
                              _buildTextField(
                                controller: _agencyNameController,
                                label: strings.tr('Nama Agensi', 'Agency Name'),
                                icon: Icons.apartment_outlined,
                                validator: (value) {
                                  if (_registrationType !=
                                      RegistrationType.agencyAdmin) return null;
                                  if (value == null ||
                                      value.trim().length < 3) {
                                    return strings.tr(
                                      'Masukkan nama agensi Anda.',
                                      'Enter your agency name.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyEmailController,
                                label:
                                    strings.tr('Email Agensi', 'Agency Email'),
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (_registrationType !=
                                      RegistrationType.agencyAdmin) return null;
                                  if (value == null || !value.contains('@')) {
                                    return strings.tr(
                                      'Masukkan email agensi yang valid.',
                                      'Enter a valid agency email.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyPhoneController,
                                label: strings.tr(
                                  'Telepon Agensi',
                                  'Agency Phone',
                                ),
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (_registrationType !=
                                      RegistrationType.agencyAdmin) return null;
                                  if (value == null ||
                                      value.trim().length < 5) {
                                    return strings.tr(
                                      'Masukkan nomor telepon agensi.',
                                      'Enter the agency phone number.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyAddressController,
                                label: strings.tr(
                                  'Alamat Lengkap Agensi',
                                  'Agency Full Address',
                                ),
                                icon: Icons.location_on_outlined,
                                validator: (value) {
                                  if (_registrationType !=
                                      RegistrationType.agencyAdmin) return null;
                                  if (value == null ||
                                      value.trim().length < 5) {
                                    return strings.tr(
                                      'Masukkan alamat agensi.',
                                      'Enter the agency address.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyCityController,
                                label: strings.tr('Kota Agensi', 'Agency City'),
                                icon: Icons.location_city_outlined,
                                validator: (value) {
                                  if (_registrationType !=
                                      RegistrationType.agencyAdmin) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return strings.tr(
                                      'Masukkan kota agensi.',
                                      'Enter the agency city.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyDescriptionController,
                                label: strings.tr(
                                  'Deskripsi Singkat Agensi',
                                  'Short Agency Description',
                                ),
                                icon: Icons.description_outlined,
                                maxLines: 2,
                                validator: (value) {
                                  if (_registrationType !=
                                      RegistrationType.agencyAdmin) return null;
                                  if (value == null ||
                                      value.trim().length < 10) {
                                    return strings.tr(
                                      'Masukkan deskripsi agensi (min. 10 karakter).',
                                      'Enter an agency description (min. 10 characters).',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          _buildTextField(
                            controller: _emailController,
                            label: strings.tr('Email', 'Email'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return strings.tr(
                                  'Masukkan email yang valid.',
                                  'Enter a valid email.',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: strings.tr('Kata Sandi', 'Password'),
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return strings.tr(
                                  'Sandi minimal 6 karakter.',
                                  'Password must be at least 6 characters.',
                                );
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!_isRegisterMode) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authState.isLoading ? null : _forgotPassword,
                        child: Text(
                          strings.tr('Lupa Sandi?', 'Forgot Password?'),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                  ],
                  FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isRegisterMode
                                ? strings.tr(
                                    'Daftar Sekarang',
                                    'Register Now',
                                  )
                                : strings.tr('Masuk', 'Sign In'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode
                            ? strings.tr(
                                'Sudah punya akun?',
                                'Already have an account?',
                              )
                            : strings.tr(
                                'Belum punya akun?',
                                'Do not have an account?',
                              ),
                        style:
                            const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => setState(
                                () => _isRegisterMode = !_isRegisterMode),
                        child: Text(
                          _isRegisterMode
                              ? strings.tr('Masuk', 'Sign In')
                              : strings.tr('Daftar', 'Register'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: onFieldSubmitted != null
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
      ),
      validator: validator,
    );
  }
}

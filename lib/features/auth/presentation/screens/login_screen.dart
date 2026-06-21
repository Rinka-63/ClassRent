import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';

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
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan email yang valid untuk reset sandi.')),
        );
      }
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).resetPassword(email);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email reset sandi telah dikirim. Cek inbox Anda.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isRegisterMode ? 'Buat Akun Baru' : 'Selamat Datang Kembali',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegisterMode 
                        ? 'Daftar untuk menikmati layanan ClassRent.' 
                        : 'Masuk dengan email dan kata sandi Anda.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
                              segments: const [
                                ButtonSegment(
                                  value: RegistrationType.user,
                                  label: Text('Penyewa'),
                                  icon: Icon(Icons.person_outline),
                                ),
                                ButtonSegment(
                                  value: RegistrationType.agencyAdmin,
                                  label: Text('Agensi'),
                                  icon: Icon(Icons.apartment_outlined),
                                ),
                              ],
                              selected: {_registrationType},
                              onSelectionChanged: (selection) {
                                setState(() => _registrationType = selection.first);
                              },
                              style: SegmentedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Nama Lengkap',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (!_isRegisterMode) return null;
                                if (value == null || value.trim().length < 3) {
                                  return 'Masukkan nama lengkap Anda.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_registrationType == RegistrationType.agencyAdmin) ...[
                              _buildTextField(
                                controller: _agencyNameController,
                                label: 'Nama Agensi',
                                icon: Icons.apartment_outlined,
                                validator: (value) {
                                  if (_registrationType != RegistrationType.agencyAdmin) return null;
                                  if (value == null || value.trim().length < 3) {
                                    return 'Masukkan nama agensi Anda.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyEmailController,
                                label: 'Email Agensi',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (_registrationType != RegistrationType.agencyAdmin) return null;
                                  if (value == null || !value.contains('@')) {
                                    return 'Masukkan email agensi yang valid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyPhoneController,
                                label: 'Telepon Agensi',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (_registrationType != RegistrationType.agencyAdmin) return null;
                                  if (value == null || value.trim().length < 5) {
                                    return 'Masukkan nomor telepon agensi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyAddressController,
                                label: 'Alamat Lengkap Agensi',
                                icon: Icons.location_on_outlined,
                                validator: (value) {
                                  if (_registrationType != RegistrationType.agencyAdmin) return null;
                                  if (value == null || value.trim().length < 5) {
                                    return 'Masukkan alamat agensi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyCityController,
                                label: 'Kota Agensi',
                                icon: Icons.location_city_outlined,
                                validator: (value) {
                                  if (_registrationType != RegistrationType.agencyAdmin) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Masukkan kota agensi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _agencyDescriptionController,
                                label: 'Deskripsi Singkat Agensi',
                                icon: Icons.description_outlined,
                                maxLines: 2,
                                validator: (value) {
                                  if (_registrationType != RegistrationType.agencyAdmin) return null;
                                  if (value == null || value.trim().length < 10) {
                                    return 'Masukkan deskripsi agensi (min. 10 karakter).';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Masukkan email yang valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Kata Sandi',
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() => _isPasswordVisible = !_isPasswordVisible);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Sandi minimal 6 karakter.';
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
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error),
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
                        child: const Text('Lupa Sandi?'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                  ],
                  FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isRegisterMode ? 'Daftar Sekarang' : 'Masuk',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode ? 'Sudah punya akun?' : 'Belum punya akun?',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => setState(() => _isRegisterMode = !_isRegisterMode),
                        child: Text(_isRegisterMode ? 'Masuk' : 'Daftar'),
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
      textInputAction: onFieldSubmitted != null ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: validator,
    );
  }
}

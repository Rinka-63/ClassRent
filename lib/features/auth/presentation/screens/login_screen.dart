import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _agencyNameController = TextEditingController();
  bool _isRegisterMode = false;
  RegistrationType _registrationType = RegistrationType.user;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _agencyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ClassRent', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(_isRegisterMode ? 'Create your account.' : 'Welcome back.'),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isRegisterMode) ...[
                          SegmentedButton<RegistrationType>(
                            segments: const [
                              ButtonSegment(
                                value: RegistrationType.user,
                                label: Text('User'),
                                icon: Icon(Icons.person_outline),
                              ),
                              ButtonSegment(
                                value: RegistrationType.agencyAdmin,
                                label: Text('Agency'),
                                icon: Icon(Icons.apartment_outlined),
                              ),
                            ],
                            selected: {_registrationType},
                            onSelectionChanged: (selection) {
                              setState(() => _registrationType = selection.first);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (!_isRegisterMode) return null;
                              if (value == null || value.trim().length < 3) {
                                return 'Enter your full name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_registrationType == RegistrationType.agencyAdmin) ...[
                            TextFormField(
                              controller: _agencyNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Agency name',
                                prefixIcon: Icon(Icons.apartment_outlined),
                              ),
                              validator: (value) {
                                if (_registrationType != RegistrationType.agencyAdmin) {
                                  return null;
                                }
                                if (value == null || value.trim().length < 3) {
                                  return 'Enter your agency name.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authState.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegisterMode ? 'Register' : 'Login'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(
                      _isRegisterMode
                          ? 'Already have an account? Login'
                          : 'Need an account? Register',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      );
      return;
    }

    await controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}

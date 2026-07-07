import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/domain/entities/app_user.dart';

class AuthState {
  const AuthState({
    required this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  const AuthState.initial()
      : user = null,
        isLoading = true,
        errorMessage = null;

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider))..restoreSession();
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.initial());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.restoreSession();
    state = result.match(
      (failure) => AuthState(user: null, errorMessage: _messageFor(failure)),
      (user) => AuthState(user: user),
    );
  }

  Future<bool> refreshCurrentUser() async {
    final result = await _repository.restoreSession();
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageFor(failure),
        );
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.login(email: email, password: password);
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageFor(failure),
        );
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required RegistrationType type,
    String? agencyName,
    String? agencyEmail,
    String? agencyPhone,
    String? agencyAddress,
    String? agencyCity,
    String? agencyDescription,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.register(
      email: email,
      password: password,
      fullName: fullName,
      type: type,
      agencyName: agencyName,
      agencyEmail: agencyEmail,
      agencyPhone: agencyPhone,
      agencyAddress: agencyAddress,
      agencyCity: agencyCity,
      agencyDescription: agencyDescription,
    );
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageFor(failure),
        );
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.resetPassword(email);
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageFor(failure),
        );
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.updateProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageFor(failure),
        );
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.logout();
    state = result.match(
      (failure) => state.copyWith(
        isLoading: false,
        errorMessage: _messageFor(failure),
      ),
      (_) => const AuthState(user: null),
    );
  }

  String _messageFor(Failure failure) {
    if (failure is AuthFailure) {
      final message = failure.message.toLowerCase();
      if (message.contains('invalid login credentials') ||
          message.contains('invalid credentials') ||
          message.contains('email not confirmed') ||
          failure.code == '400') {
        return 'Email atau kata sandi salah.';
      }
    }
    return failure.message;
  }
}

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(currentUserProvider)?.role ?? UserRole.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isLoading;
});

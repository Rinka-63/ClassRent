import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../shared/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AppUser?>> restoreSession();
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  });
  Future<Either<Failure, AppUser>> register({
    required String email,
    required String password,
    required String fullName,
    required RegistrationType type,
    String? agencyName,
  });
  Future<Either<Failure, AppUser>> updateProfile({
    required String fullName,
    String? phone,
  });
  Future<Either<Failure, Unit>> logout();
}

enum RegistrationType {
  user,
  agencyAdmin;

  String get metadataValue => switch (this) {
        RegistrationType.user => 'user',
        RegistrationType.agencyAdmin => 'agency_admin',
      };
}

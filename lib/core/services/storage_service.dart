import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failure.dart';
import '../supabase/supabase_service.dart';

class StorageService {
  const StorageService(this._service);

  final SupabaseService _service;

  static const String _roomImagesBucket = 'room-images';
  static const String _profileImagesBucket = 'profile-images';

  /// Pick an image from gallery
  Future<Either<Failure, File>> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (result == null) {
        return left(UnknownFailure('No image selected'));
      }

      return right(File(result.path));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  /// Pick an image from camera
  Future<Either<Failure, File>> pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (result == null) {
        return left(UnknownFailure('No image captured'));
      }

      return right(File(result.path));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  /// Upload image to Supabase Storage
  Future<Either<Failure, String>> uploadRoomImage(
    File imageFile,
    String roomId,
  ) async {
    try {
      final client = _service.requireClient;

      // Generate unique filename
      final fileName = '${roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = fileName;

      // Upload file
      await client.storage.from(_roomImagesBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final imageUrl =
          client.storage.from(_roomImagesBucket).getPublicUrl(filePath);

      return right(imageUrl);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, String>> uploadProfileImage(
    File imageFile,
    String ownerId,
  ) async {
    try {
      final client = _service.requireClient;
      final fileName =
          '${ownerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await client.storage.from(_profileImagesBucket).upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return right(
        client.storage.from(_profileImagesBucket).getPublicUrl(fileName),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  /// Upload multiple images
  Future<Either<Failure, List<String>>> uploadRoomImages(
    List<File> imageFiles,
    String roomId,
  ) async {
    try {
      final urls = <String>[];

      for (final file in imageFiles) {
        final result = await uploadRoomImage(file, roomId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (url) => urls.add(url),
        );
      }

      return right(urls);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  /// Delete image from Supabase Storage
  Future<Either<Failure, void>> deleteRoomImage(String imageUrl) async {
    try {
      final client = _service.requireClient;

      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePath =
          pathSegments.skipWhile((s) => s != _roomImagesBucket).join('/');

      await client.storage.from(_roomImagesBucket).remove([filePath]);

      return right(null);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}

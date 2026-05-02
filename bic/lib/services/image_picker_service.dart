import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  Future<dynamic> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      if (kIsWeb) {
        return await image.readAsBytes();
      } else {
        return File(image.path);
      }
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<dynamic> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      if (kIsWeb) {
        return await image.readAsBytes();
      } else {
        return File(image.path);
      }
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  Future<List<dynamic>> pickMultipleImages({int maxImages = 10}) async {
    try {
      List<dynamic> selectedImages = [];

      for (int i = 0; i < maxImages; i++) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (image == null) break;

        if (kIsWeb) {
          selectedImages.add(await image.readAsBytes());
        } else {
          selectedImages.add(File(image.path));
        }

        if (selectedImages.length >= maxImages) break;
      }

      return selectedImages;
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  Future<dynamic> pickAndCropImage({
    required ImageSource source,
    double? aspectRatioX,
    double? aspectRatioY,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      if (kIsWeb) {
        return await image.readAsBytes();
      } else {
        return File(image.path);
      }
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
}

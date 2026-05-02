import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Dio _dio = Dio();

  static const String _apiKey = '69ee8a161f72757af33963b1512fc6ed';

  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  Future<String> _uploadToImgbb({
    required dynamic imageFile,
    required String name,
    required Function(double) onProgress,
  }) async {
    try {
      String base64Image;

      if (kIsWeb) {
        base64Image = base64Encode(imageFile as Uint8List);
      } else {
        final bytes = await (imageFile as File).readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final formData = FormData.fromMap({
        'key': _apiKey,
        'image': base64Image,
        'name': name,
      });

      final response = await _dio.post(
        _uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final url = response.data['data']['url'] as String;
        return url;
      } else {
        throw Exception('Upload failed: ${response.data}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadProfilePicture({
    required String userId,
    required dynamic imageFile,
    required Function(double) onProgress,
  }) async {
    try {
      return await _uploadToImgbb(
        imageFile: imageFile,
        name: 'profile_$userId',
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<String> uploadPostImage({
    required String userId,
    required String postId,
    required dynamic imageFile,
    required Function(double) onProgress,
  }) async {
    try {
      return await _uploadToImgbb(
        imageFile: imageFile,
        name: 'post_${userId}_$postId',
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload post image: $e');
    }
  }

  Future<List<String>> uploadMultiplePostImages({
    required String userId,
    required String postId,
    required List<dynamic> imageFiles,
    required Function(double) onProgress,
  }) async {
    try {
      List<String> downloadUrls = [];
      int totalImages = imageFiles.length;
      int completedUploads = 0;

      for (int i = 0; i < imageFiles.length; i++) {
        final url = await _uploadToImgbb(
          imageFile: imageFiles[i],
          name: 'post_${userId}_${postId}_$i',
          onProgress: (_) {},
        );
        downloadUrls.add(url);

        completedUploads++;
        onProgress(completedUploads / totalImages);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<String> uploadStoryImage({
    required String userId,
    required String storyId,
    required dynamic imageFile,
    required Function(double) onProgress,
  }) async {
    try {
      return await _uploadToImgbb(
        imageFile: imageFile,
        name: 'story_${userId}_$storyId',
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload story image: $e');
    }
  }

  Future<String> uploadVideo({
    required File videoFile,
    String folder = 'reels',
    required Function(double) onProgress,
  }) async {
    final fileName =
        '${folder}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref =
        FirebaseStorage.instance.ref().child('$folder/$fileName');

    final uploadTask = ref.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );

    uploadTask.snapshotEvents.listen((snapshot) {
      final progress =
          snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    await uploadTask;
    return await ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {}

  Future<void> deleteMultipleImages(List<String> imageUrls) async {}

  Future<void> deleteProfilePicture(String userId) async {}

  Future<void> deleteUserPosts(String userId) async {}
}

import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final List<StoryItem> items;
  final bool hasUnseenStories;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.items,
    this.hasUnseenStories = true,
  });
}

class StoryItem {
  final String id;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final bool isSeen;
  final List<String> likes;
  final String? overlayText;

  StoryItem({
    required this.id,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.isSeen = false,
    this.likes = const [],
    this.overlayText,
  });

  factory StoryItem.fromFirestore(Map<String, dynamic> data) {
    DateTime createdAt;
    if (data['createdAt'] != null) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      // Fallback: document ID is millisecondsSinceEpoch (set in create_story_screen)
      final ms = int.tryParse(data['id'] as String? ?? '');
      createdAt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.now();
    }
    return StoryItem(
      id: data['id'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      createdAt: createdAt,
      isSeen: false,
      likes: List<String>.from(data['likes'] ?? []),
      overlayText: data['overlayText'],
    );
  }
}

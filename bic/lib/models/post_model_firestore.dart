import 'package:cloud_firestore/cloud_firestore.dart';

class PostModelFirestore {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String? imageUrl;
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final List<String> likes;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  PostModelFirestore({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    this.imageUrl,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likes = const [],
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  factory PostModelFirestore.fromJson(Map<String, dynamic> json) {
    return PostModelFirestore(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      imageUrl: json['imageUrl'],
      caption: json['caption'],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      likes: List<String>.from(json['likes'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
      'caption': caption,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likes': likes,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  PostModelFirestore copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? imageUrl,
    String? caption,
    int? likesCount,
    int? commentsCount,
    List<String>? likes,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModelFirestore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likes: likes ?? this.likes,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }
}

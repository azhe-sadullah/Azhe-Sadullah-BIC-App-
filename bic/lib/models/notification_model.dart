import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String fromUserId;
  final String fromUsername;
  final String? fromUserAvatar;
  final String toUserId;
  final String? postId;
  final String? postImageUrl;
  final String? commentText;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserAvatar,
    required this.toUserId,
    this.postId,
    this.postImageUrl,
    this.commentText,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserAvatar': fromUserAvatar,
      'toUserId': toUserId,
      'postId': postId,
      'postImageUrl': postImageUrl,
      'commentText': commentText,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUsername: json['fromUsername'] ?? '',
      fromUserAvatar: json['fromUserAvatar'],
      toUserId: json['toUserId'] ?? '',
      postId: json['postId'],
      postImageUrl: json['postImageUrl'],
      commentText: json['commentText'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  String getMessage() {
    switch (type) {
      case 'like':
        return 'لایکی پۆستەکەتی کرد';
      case 'comment':
        return 'کۆمێنتی پۆستەکەتی کرد';
      case 'follow':
        return 'شوێنی کەوتوویت';
      default:
        return '';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? fromUserId,
    String? fromUsername,
    String? fromUserAvatar,
    String? toUserId,
    String? postId,
    String? postImageUrl,
    String? commentText,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      toUserId: toUserId ?? this.toUserId,
      postId: postId ?? this.postId,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      commentText: commentText ?? this.commentText,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

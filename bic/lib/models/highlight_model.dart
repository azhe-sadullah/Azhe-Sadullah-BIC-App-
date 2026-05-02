import 'package:cloud_firestore/cloud_firestore.dart';

class HighlightModel {
  final String id;
  final String userId;
  final String title;
  final String? coverImageUrl;
  final List<String> storyIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  HighlightModel({
    required this.id,
    required this.userId,
    required this.title,
    this.coverImageUrl,
    required this.storyIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HighlightModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HighlightModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      storyIds: List<String>.from(data['storyIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'storyIds': storyIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

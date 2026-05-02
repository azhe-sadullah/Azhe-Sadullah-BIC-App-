import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

Future<bool> fixUserProfile() async {
  try {
    final auth = FirebaseAuth.instance;
    final firestoreService = FirestoreService();

    final currentUser = auth.currentUser;
    if (currentUser == null) return false;

    final existingUser = await firestoreService.getUser(currentUser.uid);
    if (existingUser != null) return true;

    final newUser = UserModel(
      id: currentUser.uid,
      username: currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'user${DateTime.now().millisecondsSinceEpoch}',
      email: currentUser.email ?? '',
      fullName: currentUser.displayName ?? '',
      avatar: currentUser.photoURL ?? '',
      bio: 'بەخێربێن بۆ BIC! 👋',
      postsCount: 0,
      followersCount: 0,
      followingCount: 0,
      isVerified: false,
      followers: [],
      following: [],
      bookmarks: [],
      createdAt: DateTime.now(),
    );

    await firestoreService.createUser(newUser);
    return true;
  } catch (e) {
    debugPrint('fixUserProfile error: $e');
    return false;
  }
}

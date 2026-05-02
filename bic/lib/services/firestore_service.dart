import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get usersCollection => _db.collection('users');
  CollectionReference get postsCollection => _db.collection('posts');
  CollectionReference get commentsCollection => _db.collection('comments');
  CollectionReference get storiesCollection => _db.collection('stories');

  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  Future<void> createUser(UserModel user) async {
    try {
      await usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await usersCollection.doc(userId).update({'fcmToken': token});
    } catch (e) {
      debugPrint('saveFcmToken error: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      QuerySnapshot snapshot = await usersCollection
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      QuerySnapshot snapshot = await usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username: $e');
    }
  }

  Future<String> createPost(Map<String, dynamic> postData) async {
    try {
      DocumentReference docRef = await postsCollection.add(postData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<Map<String, dynamic>?> getPost(String postId) async {
    try {
      DocumentSnapshot doc = await postsCollection.doc(postId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  /// Increment post view count (called when a post detail is opened)
  Future<void> incrementPostViews(String postId) async {
    try {
      await postsCollection.doc(postId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (_) {
      // ئەگەر فیلدەکە نەبوو، set بکە
      await postsCollection.doc(postId).set(
          {'viewsCount': 1}, SetOptions(merge: true));
    }
  }

  /// Get all posts for a user with analytics data
  Future<List<Map<String, dynamic>>> getUserPostsForAnalytics(
      String userId, {DateTime? since}) async {
    final snap = await postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    final all = snap.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .toList();
    if (since == null) return all;
    final sinceTs = Timestamp.fromDate(since);
    return all.where((d) {
      final ts = d['createdAt'];
      return ts is Timestamp && ts.compareTo(sinceTs) >= 0;
    }).toList();
  }

  Stream<QuerySnapshot> getFeedPosts({int limit = 20}) {
    return postsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPosts(String userId) {
    return postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await postsCollection.doc(postId).update(data);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await postsCollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      await postsCollection.doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });

      DocumentSnapshot postDoc = await postsCollection.doc(postId).get();
      if (postDoc.exists) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        String postOwnerId = postData['userId'];

        DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          await createNotification({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'type': 'like',
            'fromUserId': userId,
            'fromUsername': userData['username'] ?? 'نەزانراو',
            'fromUserAvatar': userData['avatar'],
            'toUserId': postOwnerId,
            'postId': postId,
            'postImageUrl': postData['imageUrl'],
            'isRead': false,
            'createdAt': DateTime.now(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await postsCollection.doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  Future<String> addComment(Map<String, dynamic> commentData) async {
    try {
      DocumentReference docRef = await commentsCollection.add(commentData);

      await postsCollection.doc(commentData['postId']).update({
        'commentsCount': FieldValue.increment(1),
      });

      DocumentSnapshot postDoc = await postsCollection.doc(commentData['postId']).get();
      if (postDoc.exists) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        String postOwnerId = postData['userId'];

        await createNotification({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'comment',
          'fromUserId': commentData['userId'],
          'fromUsername': commentData['username'] ?? 'نەزانراو',
          'fromUserAvatar': commentData['userAvatar'],
          'toUserId': postOwnerId,
          'postId': commentData['postId'],
          'postImageUrl': postData['imageUrl'],
          'commentText': commentData['text'],
          'isRead': false,
          'createdAt': DateTime.now(),
        });
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Stream<QuerySnapshot> getPostComments(String postId) {
    return commentsCollection
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await commentsCollection.doc(commentId).delete();

      await postsCollection.doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await usersCollection.doc(currentUserId).update({
        'following': FieldValue.arrayUnion([targetUserId]),
        'followingCount': FieldValue.increment(1),
      });

      await usersCollection.doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      });

      DocumentSnapshot userDoc = await usersCollection.doc(currentUserId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        await createNotification({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'follow',
          'fromUserId': currentUserId,
          'fromUsername': userData['username'] ?? 'نەزانراو',
          'fromUserAvatar': userData['avatar'],
          'toUserId': targetUserId,
          'isRead': false,
          'createdAt': DateTime.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await usersCollection.doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      await usersCollection.doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(currentUserId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List following = data['following'] ?? [];
        return following.contains(targetUserId);
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check follow status: $e');
    }
  }

  Future<void> bookmarkPost(String userId, String postId) async {
    try {
      await usersCollection.doc(userId).update({
        'bookmarks': FieldValue.arrayUnion([postId]),
      });
    } catch (e) {
      throw Exception('Failed to bookmark post: $e');
    }
  }

  Future<void> removeBookmark(String userId, String postId) async {
    try {
      await usersCollection.doc(userId).update({
        'bookmarks': FieldValue.arrayRemove([postId]),
      });
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarkedPosts(String userId) async {
    try {
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
      if (!userDoc.exists) return [];

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List bookmarks = userData['bookmarks'] ?? [];

      if (bookmarks.isEmpty) return [];

      QuerySnapshot postsSnapshot = await postsCollection
          .where(FieldPath.documentId, whereIn: bookmarks)
          .get();

      return postsSnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookmarked posts: $e');
    }
  }

  CollectionReference get notificationsCollection => _db.collection('notifications');

  Future<String> createNotification(Map<String, dynamic> notificationData) async {
    try {
      if (notificationData['fromUserId'] == notificationData['toUserId']) {
        return '';
      }

      DocumentReference docRef = await notificationsCollection.add(notificationData);
      return docRef.id;
    } catch (e) {
      debugPrint('createNotification error: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return notificationsCollection
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await notificationsCollection
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Stream<int> getUnreadNotificationsCount(String userId) {
    return notificationsCollection
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }


  /// Count new followers gained within [since] (or all-time if null).
  /// Uses follow-type notifications sent to [userId].
  Future<int> getNewFollowersCount(String userId, {DateTime? since}) async {
    try {
      Query q = _db
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('type', isEqualTo: 'follow');
      if (since != null) {
        q = q.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }
      final snap = await q.get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }


  /// Delete a single story document by its Firestore doc ID.
  Future<void> deleteStory(String storyDocId) async {
    try {
      await storiesCollection.doc(storyDocId).delete();
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }
}

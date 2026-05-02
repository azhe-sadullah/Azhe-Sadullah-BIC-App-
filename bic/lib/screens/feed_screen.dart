import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_bar.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'comments_screen.dart';
import 'notifications_screen.dart';
import 'post_detail_screen.dart';
import 'chat_list_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String? _currentUserId;
  bool _hasConnectionError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _checkConnection();
  }

  @override
  void dispose() {
    _storiesSubscription?.cancel();
    _bookmarksNotifier.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserId() async {
    final userId = await _authService.getSavedUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
    if (userId != null) {
      _subscribeToStories(userId);
      _loadBookmarks(userId);
    }
  }

  Future<void> _loadBookmarks(String userId) async {
    try {
      final userDoc = await _firestoreService.usersCollection.doc(userId).get();
      if (!userDoc.exists) return;
      final data = userDoc.data() as Map<String, dynamic>;
      _bookmarksNotifier.value = Set<String>.from(data['bookmarks'] ?? []);
    } catch (_) {}
  }

  Future<void> _checkConnection() async {
    // Give the stream 8 seconds to connect, then show error if still loading
    await Future.delayed(const Duration(seconds: 8));
    if (mounted && _isLoading) {
      setState(() {
        _hasConnectionError = true;
        _isLoading = false;
      });
    }
  }

  List<StoryModel> _stories = [];
  String? _currentUserAvatar;
  final ValueNotifier<Set<String>> _bookmarksNotifier = ValueNotifier({});
  StreamSubscription? _storiesSubscription;

  /// Subscribe to active stories in real-time
  Future<void> _subscribeToStories(String userId) async {
    try {
      final userDoc = await _firestoreService.usersCollection.doc(userId).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data() as Map<String, dynamic>;
      final following = List<String>.from(userData['following'] ?? []);
      final allowedIds = <String>{...following, userId};
      if (mounted) {
        setState(() => _currentUserAvatar = userData['avatar'] as String?);
      }

      final now = Timestamp.now();
      _storiesSubscription = _firestoreService.storiesCollection
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt', descending: false)
          .snapshots()
          .listen((snap) => _processStoriesSnapshot(snap, allowedIds, userId));
    } catch (_) {}
  }

  void _processStoriesSnapshot(QuerySnapshot snap, Set<String> allowedIds, String userId) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      final storyUserId = data['userId'] as String? ?? '';
      if (!allowedIds.contains(storyUserId)) continue;
      grouped.putIfAbsent(storyUserId, () => []).add(data);
    }

    final List<StoryModel> models = [];
    for (final entry in grouped.entries) {
      final items = entry.value
        ..sort((a, b) {
          final ta = (a['createdAt'] as Timestamp?)?.seconds ?? 0;
          final tb = (b['createdAt'] as Timestamp?)?.seconds ?? 0;
          return ta.compareTo(tb);
        });
      final first = items.first;
      models.add(StoryModel(
        id: entry.key,
        userId: entry.key,
        username: first['username'] ?? '',
        userAvatar: first['userAvatar'] ?? '',
        hasUnseenStories: true,
        items: items.map((d) => StoryItem.fromFirestore(d)).toList(),
      ));
    }
    models.sort((a, b) {
      if (a.userId == userId) return -1;
      if (b.userId == userId) return 1;
      return 0;
    });
    if (mounted) setState(() => _stories = models);
  }

  Future<void> _handleLike(String postId, bool isLiked) async {
    if (_currentUserId == null) return;

    try {
      if (isLiked) {
        await _firestoreService.unlikePost(postId, _currentUserId!);
      } else {
        await _firestoreService.likePost(postId, _currentUserId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('هەڵە: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBookmark(String postId, bool isBookmarked) async {
    if (_currentUserId == null) return;

    // Optimistic UI update — only updates the notifier, no full screen rebuild
    final updated = Set<String>.from(_bookmarksNotifier.value);
    if (isBookmarked) {
      updated.remove(postId);
    } else {
      updated.add(postId);
    }
    _bookmarksNotifier.value = updated;

    try {
      if (isBookmarked) {
        await _firestoreService.removeBookmark(_currentUserId!, postId);
      } else {
        await _firestoreService.bookmarkPost(_currentUserId!, postId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBookmarked ? 'لابرا لە سەیڤکراوەکان' : 'زیادکرا بۆ سەیڤکراوەکان ✅'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('هەڵە: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'BIC',
          style: GoogleFonts.cinzel(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        actions: [
          // Notifications button with unread count badge
          StreamBuilder<int>(
            stream: _currentUserId != null
                ? _firestoreService.getUnreadNotificationsCount(_currentUserId!)
                : Stream.value(0),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Ionicons.heart_outline, size: 26),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Chat button with unread badge
          StreamBuilder<QuerySnapshot>(
            stream: _currentUserId != null
                ? FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: _currentUserId)
                    .snapshots()
                : Stream.value(null as dynamic),
            builder: (context, chatSnap) {
              int unread = 0;
              if (chatSnap.hasData && chatSnap.data != null) {
                for (final doc in chatSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final lastSender = data['lastSenderId'] ?? '';
                  final readBy = List<String>.from(data['readBy'] ?? []);
                  if (lastSender != _currentUserId &&
                      !readBy.contains(_currentUserId) &&
                      (data['lastMessage'] ?? '').toString().isNotEmpty) {
                    unread++;
                  }
                }
              }
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    ),
                    icon: const Icon(Ionicons.paper_plane_outline, size: 26),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // Stories section - hidden if empty for better performance
            if (_stories.isNotEmpty)
              SliverToBoxAdapter(
                child: StoriesBar(
                    stories: _stories,
                    currentUserId: _currentUserId,
                    currentUserAvatar: _currentUserAvatar,
                  ),
              ),

            // Divider
            if (_stories.isNotEmpty)
              SliverToBoxAdapter(
                child: Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
              ),

            // Posts from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getFeedPosts(limit: 10),
              builder: (context, snapshot) {
                // Update loading state when data arrives
                if (snapshot.hasData && _isLoading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _hasConnectionError = false;
                      });
                    }
                  });
                }

                if (snapshot.hasError || _hasConnectionError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Ionicons.cloud_offline_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'هەڵەی هێڵ',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _hasConnectionError
                                  ? 'ناتوانێ بگەیەنێت بە سێرڤەر.\nتکایە هێڵی ئینتەرنێتەکەت بپشکنە.'
                                  : 'هەڵە: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasConnectionError = false;
                                  _isLoading = true;
                                });
                                _checkConnection();
                              },
                              icon: const Icon(Ionicons.refresh),
                              label: const Text('دووبارە هەوڵ بدەرەوە'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Ionicons.images_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'هیچ پۆستێک نییە',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'یەکەم پۆستەکەت دروست بکە بۆ دەستپێکردن!',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final posts = snapshot.data!.docs;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final postData = posts[index].data() as Map<String, dynamic>;
                      final postId = posts[index].id;

                      // Check if current user liked this post
                      final likes = List<String>.from(postData['likes'] ?? []);
                      final isLiked = _currentUserId != null && likes.contains(_currentUserId);

                      // Convert Firestore data to PostModel
                      final userId = postData['userId'] ?? '';

                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: _bookmarksNotifier,
                        builder: (context, bookmarks, _) {
                          final isBookmarked = bookmarks.contains(postId);
                          final post = PostModel(
                            id: postId,
                            userId: userId,
                            username: postData['username'] ?? 'نەزانراو',
                            userAvatar: postData['userAvatar'] ?? '',
                            imageUrl: postData['imageUrl'],
                            caption: postData['caption'],
                            likesCount: postData['likesCount'] ?? 0,
                            commentsCount: postData['commentsCount'] ?? 0,
                            isLiked: isLiked,
                            isBookmarked: isBookmarked,
                            createdAt: postData['createdAt'] != null
                                ? (postData['createdAt'] as Timestamp).toDate()
                                : DateTime.now(),
                            images: List<String>.from(postData['images'] ?? []),
                          );

                          return RepaintBoundary(
                            child: PostCard(
                              post: post,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(
                                      postId: postId,
                                    ),
                                  ),
                                );
                              },
                              onLike: () => _handleLike(postId, isLiked),
                              onComment: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommentsScreen(
                                      postId: postId,
                                      postOwnerId: post.userId,
                                    ),
                                  ),
                                );
                              },
                              onShare: () {},
                              onBookmark: () => _handleBookmark(postId, isBookmarked),
                            ),
                          );
                        },
                      );
                    },
                    childCount: posts.length,
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

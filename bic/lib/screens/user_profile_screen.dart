import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../view_model/language/language_provider.dart';
import 'chat_screen.dart';
import 'post_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();

  UserModel? _user;
  String? _currentUserId;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final user = await _firestoreService.getUser(widget.userId);
      bool isFollowing = false;
      if (currentUserId != null && user != null) {
        isFollowing = await _firestoreService.isFollowing(currentUserId, widget.userId);
      }
      if (mounted) {
        setState(() {
          _currentUserId = currentUserId;
          _user = user;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _user == null) return;
    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await _firestoreService.unfollowUser(_currentUserId!, widget.userId);
      } else {
        await _firestoreService.followUser(_currentUserId!, widget.userId);
      }
      if (mounted) {
        setState(() { _isFollowing = !_isFollowing; _isFollowLoading = false; });
        _loadData();
      }
    } catch (_) {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(lang.isKurdish ? 'بەکارهێنەر نەدۆزرایەوە' : 'User not found')));

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 18),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF405DE6), Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFFCAF45)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: user.avatar?.isNotEmpty == true ? CachedNetworkImageProvider(user.avatar!) : null,
                          child: user.avatar?.isEmpty ?? true ? const Icon(Icons.person, size: 40) : null,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statCol(user.postsCount.toString(), lang.posts),
                            _statCol(_formatCount(user.followersCount), lang.followers),
                            _statCol(_formatCount(user.followingCount), lang.following),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (user.fullName?.isNotEmpty == true)
                    Text(user.fullName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (user.bio?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(user.bio!, style: const TextStyle(fontSize: 14)),
                  ],
                  const SizedBox(height: 16),
                  if (_currentUserId != widget.userId)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _isFollowLoading ? null : _toggleFollow,
                              child: _isFollowLoading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(_isFollowing ? lang.followingBtn : lang.follow),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatScreen(otherUserId: user.id, otherUsername: user.username, otherAvatar: user.avatar ?? ''),
                              )),
                              child: Text(lang.isKurdish ? 'پەیام' : 'Message'),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.play_circle_outline)),
                Tab(icon: Icon(Icons.person_pin_outlined)),
              ],
            )),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getUserPosts(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text(lang.loadError));
                final posts = snapshot.data?.docs ?? [];
                if (posts.isEmpty) return Center(child: Text(lang.noPosts));
                return GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                  itemCount: posts.length,
                  itemBuilder: (_, i) {
                    final post = posts[i].data() as Map<String, dynamic>;
                    final imageUrl = post['imageUrl'] ?? post['images']?[0] ?? '';
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: posts[i].id))),
                      child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[300]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey))),
                    );
                  },
                );
              },
            ),
            Center(child: Text(lang.noReels, style: const TextStyle(color: Colors.grey))),
            Center(child: Text(lang.noTagged, style: const TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  @override
  bool shouldRebuild(_TabDelegate old) => false;
}

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:bic/services/auth_service.dart';
import 'package:bic/services/firestore_service.dart';
import 'package:bic/models/user_model.dart';
import 'package:bic/landing/landing_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'settings_screen.dart';
import 'post_detail_screen.dart';
import 'business_card_screen.dart';
import 'analytics_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../view_model/language/language_provider.dart';
import '../models/highlight_model.dart';
import 'highlights_viewer_screen.dart';
import 'highlights_screen.dart';

class InstagramProfileScreen extends StatefulWidget {
  const InstagramProfileScreen({super.key});

  @override
  State<InstagramProfileScreen> createState() => _InstagramProfileScreenState();
}

class _InstagramProfileScreenState extends State<InstagramProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (mounted) setState(() { _currentUser = user; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    if (_currentUser == null) return Scaffold(body: Center(child: Text(lang.failedProfile)));

    final user = _currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 18),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showMenu(context),
            icon: const Icon(Icons.menu, size: 26),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + stats
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
                          radius: 43,
                          backgroundImage: user.avatar?.isNotEmpty == true ? NetworkImage(user.avatar!) : null,
                          child: user.avatar?.isEmpty ?? true ? const Icon(Icons.person, size: 40) : null,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statCol(user.postsCount.toString(), lang.posts),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowersScreen(userId: user.id, username: user.username))),
                              child: _statCol(_formatCount(user.followersCount), lang.followers),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowingScreen(userId: user.id, username: user.username))),
                              child: _statCol(_formatCount(user.followingCount), lang.following),
                            ),
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

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            if (result == true) _loadUser();
                          },
                          child: Text(lang.editProfile),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Share.share('${lang.shareProfileMsg}${user.username}'),
                          child: Text(lang.shareProfile),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Highlights
                  _buildHighlights(user),
                  const SizedBox(height: 12),

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
                Tab(icon: Icon(Ionicons.play_outline)),
                Tab(icon: Icon(Icons.person_pin_outlined)),
              ],
            )),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts grid
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
                      child: CachedNetworkImage(
                        imageUrl: imageUrl, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[300]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
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

  Widget _buildHighlights(UserModel user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('highlights')
          .where('userId', isEqualTo: user.id)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        final highlights = snapshot.data?.docs ?? [];
        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return _highlightItem(
                  child: const Icon(Icons.add),
                  label: 'New',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HighlightsScreen(userId: user.id))),
                );
              }
              final h = HighlightModel.fromFirestore(highlights[i - 1]);
              return _highlightItem(
                child: h.coverImageUrl != null
                    ? CachedNetworkImage(imageUrl: h.coverImageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.bookmark))
                    : const Icon(Icons.bookmark),
                label: h.title,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HighlightsViewerScreen(userId: user.id, highlightId: h.id, currentUserId: user.id))),
              );
            },
          ),
        );
      },
    );
  }

  Widget _highlightItem({required Widget child, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
              child: ClipOval(child: child),
            ),
            const SizedBox(height: 4),
            SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final lang = context.read<LanguageProvider>().strings;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Ionicons.bar_chart_outline),
              title: const Text('Analytics'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())); },
            ),
            ListTile(leading: const Icon(Ionicons.settings_outline), title: Text(lang.menuSettings),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
            ListTile(
              leading: const Icon(Ionicons.qr_code_outline), title: Text(lang.menuQR),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessCardScreen(
                  userId: _currentUser!.id, username: _currentUser!.username,
                  fullName: _currentUser!.fullName, avatar: _currentUser!.avatar, bio: _currentUser!.bio,
                )));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Ionicons.log_out_outline, color: Colors.red),
              title: Text(lang.menuLogout, style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().logout();
                if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Landing()), (_) => false);
              },
            ),
          ],
        ),
      ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  @override
  bool shouldRebuild(_TabDelegate old) => false;
}

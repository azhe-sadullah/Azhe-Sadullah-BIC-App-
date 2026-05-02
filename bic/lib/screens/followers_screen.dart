import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../view_model/language/language_provider.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String username;
  const FollowersScreen({super.key, required this.userId, required this.username});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  List<UserModel> _followers = [];
  String? _currentUserId;
  bool _isLoading = true;
  Map<String, bool> _followingStatus = {};

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    try {
      final currentUserId = await _authService.getSavedUserId();
      final user = await _firestoreService.getUser(widget.userId);
      if (user == null) return;

      final followers = <UserModel>[];
      final status = <String, bool>{};

      for (final id in user.followers) {
        final follower = await _firestoreService.getUser(id);
        if (follower != null) {
          followers.add(follower);
          if (currentUserId != null && currentUserId != id) {
            status[id] = await _firestoreService.isFollowing(currentUserId, id);
          }
        }
      }

      if (mounted) setState(() { _currentUserId = currentUserId; _followers = followers; _followingStatus = status; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(String userId) async {
    if (_currentUserId == null) return;
    final isFollowing = _followingStatus[userId] ?? false;
    try {
      if (isFollowing) {
        await _firestoreService.unfollowUser(_currentUserId!, userId);
      } else {
        await _firestoreService.followUser(_currentUserId!, userId);
      }
      if (mounted) setState(() => _followingStatus[userId] = !isFollowing);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.username} - ${lang.followers}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? Center(child: Text(lang.isKurdish ? 'هیچ شوێنکەوتووێک نییە' : 'No followers yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])))
              : ListView.builder(
                  itemCount: _followers.length,
                  itemBuilder: (_, i) {
                    final user = _followers[i];
                    final isMe = user.id == _currentUserId;
                    final isFollowing = _followingStatus[user.id] ?? false;
                    return ListTile(
                      onTap: isMe ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id))),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: user.avatar?.isNotEmpty == true ? CachedNetworkImageProvider(user.avatar!) : null,
                        child: user.avatar?.isEmpty ?? true ? const Icon(Icons.person) : null,
                      ),
                      title: Row(
                        children: [
                          Text(user.username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          if (user.isVerified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 14)),
                        ],
                      ),
                      subtitle: user.fullName?.isNotEmpty == true ? Text(user.fullName!, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
                      trailing: isMe ? null : SizedBox(
                        width: 100, height: 32,
                        child: ElevatedButton(
                          onPressed: () => _toggleFollow(user.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
                            foregroundColor: isFollowing ? Colors.black : Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(isFollowing ? lang.followingBtn : lang.follow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/post_model_firestore.dart';
import '../models/comment_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../view_model/language/language_provider.dart';
import 'user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isSubmitting = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) setState(() => _currentUserId = user?.id);
  }

  Future<void> _submitComment(String postOwnerId) async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) return;
      await _firestoreService.addComment({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'postId': widget.postId,
        'userId': user.id,
        'username': user.username,
        'userAvatar': user.avatar ?? '',
        'text': _commentController.text.trim(),
        'likesCount': 0,
        'likes': [],
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestoreService.deleteComment(commentId, widget.postId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleLike(PostModelFirestore post) async {
    if (_currentUserId == null) return;
    try {
      if (post.isLikedBy(_currentUserId!)) {
        await _firestoreService.unlikePost(widget.postId, _currentUserId!);
      } else {
        await _firestoreService.likePost(widget.postId, _currentUserId!);
      }
    } catch (_) {}
  }

  void _showOwnerMenu(PostModelFirestore post) {
    final lang = context.read<LanguageProvider>().strings;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: Text(lang.isKurdish ? 'دەستکاریکردنی کورتەکە' : 'Edit caption'),
              onTap: () { Navigator.pop(context); _showEditCaption(post); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(lang.isKurdish ? 'سڕینەوەی پۆست' : 'Delete post', style: const TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); _confirmDeletePost(post); },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCaption(PostModelFirestore post) {
    final lang = context.read<LanguageProvider>().strings;
    final ctrl = TextEditingController(text: post.caption ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.isKurdish ? 'دەستکاریکردنی کورتەکە' : 'Edit caption', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 200,
              autofocus: true,
              decoration: InputDecoration(
                hintText: lang.isKurdish ? 'کورتەکەت بنووسە...' : 'Write a caption...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _firestoreService.updatePost(widget.postId, {'caption': ctrl.text.trim(), 'updatedAt': DateTime.now()});
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                  }
                },
                child: Text(lang.done),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(PostModelFirestore post) {
    final lang = context.read<LanguageProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.isKurdish ? 'سڕینەوەی پۆست' : 'Delete post'),
        content: Text(lang.isKurdish ? 'دڵنیایت؟' : 'Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deletePost(widget.postId);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.deleteLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.isKurdish ? 'پۆست' : 'Post', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.postsCollection.doc(widget.postId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox();
              final data = snap.data!.data() as Map<String, dynamic>;
              if (data['userId'] != _currentUserId) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOwnerMenu(PostModelFirestore.fromJson(data)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.postsCollection.doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return Center(child: Text(lang.isKurdish ? 'پۆست نەدۆزرایەوە' : 'Post not found'));

          final post = PostModelFirestore.fromJson(snapshot.data!.data() as Map<String, dynamic>);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId))),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: post.userAvatar.isNotEmpty ? CachedNetworkImageProvider(post.userAvatar) : null,
                                child: post.userAvatar.isEmpty ? const Icon(Icons.person, size: 20) : null,
                              ),
                              const SizedBox(width: 12),
                              Text(post.username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      // Image
                      AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                      ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _toggleLike(post),
                              icon: Icon(
                                post.isLikedBy(_currentUserId ?? '') ? Ionicons.heart : Ionicons.heart_outline,
                                color: post.isLikedBy(_currentUserId ?? '') ? Colors.red : null,
                                size: 28,
                              ),
                            ),
                            IconButton(onPressed: null, icon: const Icon(Ionicons.chatbubble_outline, size: 28)),
                            IconButton(
                              onPressed: () => Share.share('${post.caption}\n\nBIC — Business Intermediation Center'),
                              icon: const Icon(Ionicons.paper_plane_outline, size: 28),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('${post.likesCount} ${lang.likes}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),

                      if (post.caption != null && post.caption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                              children: [
                                TextSpan(text: '${post.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: post.caption),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(timeago.format(post.createdAt, locale: 'en'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),

                      const Divider(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(lang.isKurdish ? 'کۆمێنتەکان' : 'Comments', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),

                      // Comments
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService.commentsCollection
                            .where('postId', isEqualTo: widget.postId)
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                          final comments = snap.data!.docs.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            d['id'] = doc.id;
                            return CommentModel.fromJson(d);
                          }).toList();
                          if (comments.isEmpty) return Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(child: Text(lang.isKurdish ? 'هیچ کۆمێنتێک نییە' : 'No comments yet', style: const TextStyle(color: Colors.grey))),
                          );
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (_, i) {
                              final c = comments[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: c.userId))),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: c.userAvatar.isNotEmpty ? CachedNetworkImageProvider(c.userAvatar) : null,
                                        child: c.userAvatar.isEmpty ? const Icon(Icons.person, size: 20) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(c.username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 8),
                                              Text(timeago.format(c.createdAt, locale: 'en'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(c.text, style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    if (c.userId == _currentUserId)
                                      IconButton(
                                        onPressed: () => _deleteComment(c.id),
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Comment input
              Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: lang.writeComment,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitComment(post.userId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSubmitting ? null : () => _submitComment(post.userId),
                          icon: Icon(Ionicons.send, color: _isSubmitting ? Colors.grey : Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

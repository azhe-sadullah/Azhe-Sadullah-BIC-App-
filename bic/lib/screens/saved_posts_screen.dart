import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:bic/services/auth_service.dart';
import 'package:bic/services/firestore_service.dart';
import '../view_model/language/language_provider.dart';
import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  List<Map<String, dynamic>> _savedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) return;
      final posts = await _firestoreService.getBookmarkedPosts(user.id);
      if (mounted) setState(() { _savedPosts = posts; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.read<LanguageProvider>().strings.errorLabel}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unsavePost(String postId) async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) return;
      await _firestoreService.removeBookmark(user.id, postId);
      setState(() => _savedPosts.removeWhere((p) => p['id'] == postId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<LanguageProvider>().strings.savedRemoved),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('Error removing save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(lang.savedTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.bookmark_border, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(lang.noSaved, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(lang.noSavedSub, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadSavedPosts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1,
                    ),
                    itemCount: _savedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _savedPosts[index];
                      final postId = post['id'] ?? '';
                      final imageUrl = post['imageUrl'] ?? post['images']?[0] ?? '';

                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))),
                        onLongPress: () => showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          builder: (_) => SafeArea(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 40, height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.bookmark_remove_outlined, color: Colors.red),
                                title: Text(lang.unsave, style: const TextStyle(color: Colors.red)),
                                onTap: () { Navigator.pop(context); _unsavePost(postId); },
                              ),
                              const SizedBox(height: 8),
                            ]),
                          ),
                        ),
                        child: Stack(fit: StackFit.expand, children: [
                          CachedNetworkImage(
                            imageUrl: imageUrl, fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (ctx, url, err) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: Icon(Icons.bookmark, color: Colors.white, size: 18,
                                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)]),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}

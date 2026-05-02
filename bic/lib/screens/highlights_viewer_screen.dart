import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/highlight_model.dart';
import '../widgets/send_to_friends_sheet.dart';
import '../view_model/language/language_provider.dart';
import 'story_viewer_screen.dart';
import '../models/story_model.dart';

class HighlightsViewerScreen extends StatefulWidget {
  final String userId;
  final String highlightId;
  final String? currentUserId;

  const HighlightsViewerScreen({
    super.key,
    required this.userId,
    required this.highlightId,
    this.currentUserId,
  });

  @override
  State<HighlightsViewerScreen> createState() => _HighlightsViewerScreenState();
}

class _HighlightsViewerScreenState extends State<HighlightsViewerScreen> {
  HighlightModel? _highlight;
  List<StoryModel> _stories = [];
  bool _loading = true;

  bool get _isOwner => widget.currentUserId == widget.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('highlights')
          .doc(widget.highlightId)
          .get();
      if (!doc.exists || !mounted) return;
      final highlight = HighlightModel.fromFirestore(doc);
      final stories = await _loadStoriesFromIds(highlight.storyIds);
      if (mounted) setState(() { _highlight = highlight; _stories = stories; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<StoryModel>> _loadStoriesFromIds(List<String> storyIds) async {
    final stories = <StoryModel>[];
    for (final storyId in storyIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('stories').doc(storyId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          stories.add(StoryModel(
            id: doc.id,
            userId: data['userId'] ?? '',
            username: data['username'] ?? '',
            userAvatar: data['userAvatar'] ?? '',
            items: [
              StoryItem(
                id: doc.id,
                imageUrl: data['imageUrl'],
                videoUrl: null,
                createdAt: data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                isSeen: true,
              ),
            ],
            hasUnseenStories: false,
          ));
        }
      } catch (_) {}
    }
    return stories;
  }

  void _showOptions() {
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            if (_isOwner)
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(isKurdish ? 'گۆڕینی کەڤەر' : 'Edit Cover'),
                onTap: () { Navigator.pop(ctx); _editCover(); },
              ),
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: Text(isKurdish ? 'ناردن بۆ فرێند' : 'Send to Friend'),
              onTap: () {
                Navigator.pop(ctx);
                final cover = _highlight?.coverImageUrl;
                if (cover != null && widget.currentUserId != null) {
                  showSendToFriendsSheet(context,
                    currentUserId: widget.currentUserId!,
                    mediaUrl: cover,
                    mediaLabel: _highlight?.title ?? (isKurdish ? 'هایلایت شەیرکرا' : 'Shared a highlight'),
                  );
                }
              },
            ),
            if (_isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(isKurdish ? 'سڕینەوەی هایلایت' : 'Delete Highlight',
                    style: const TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); _deleteHighlight(); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editCover() async {
    if (_stories.isEmpty) return;
    final isKurdish = context.read<LanguageProvider>().isKurdish;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(isKurdish ? 'کەڤەر هەڵبژێرە' : 'Select Cover',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _stories.length,
                itemBuilder: (ctx, i) {
                  final imageUrl = _stories[i].items.first.imageUrl;
                  final isSelected = _highlight?.coverImageUrl == imageUrl;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (imageUrl == null) return;
                      await FirebaseFirestore.instance
                          .collection('highlights')
                          .doc(widget.highlightId)
                          .update({'coverImageUrl': imageUrl});
                      if (mounted) {
                        setState(() {
                          _highlight = HighlightModel(
                            id: _highlight!.id,
                            userId: _highlight!.userId,
                            title: _highlight!.title,
                            coverImageUrl: imageUrl,
                            storyIds: _highlight!.storyIds,
                            createdAt: _highlight!.createdAt,
                            updatedAt: DateTime.now(),
                          );
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(ctx).primaryColor : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imageUrl != null
                            ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHighlight() async {
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isKurdish ? 'سڕینەوەی هایلایت' : 'Delete Highlight',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(isKurdish
            ? 'دڵنیایت لە سڕینەوەی ئەم هایلایتە؟'
            : 'Are you sure you want to delete this highlight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isKurdish ? 'پاشگەزبوونەوە' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isKurdish ? 'سڕینەوە' : 'Delete',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('highlights').doc(widget.highlightId).delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isKurdish ? 'هەڵە: $e' : 'Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKurdish = context.watch<LanguageProvider>().isKurdish;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _highlight?.title ?? (isKurdish ? 'هایلایت' : 'Highlight'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _loading ? null : _showOptions),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.photo_library, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(isKurdish ? 'هیچ ستۆرییەک نییە' : 'No stories',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ]),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3,
                  ),
                  itemCount: _stories.length,
                  itemBuilder: (ctx, i) {
                    final imageUrl = _stories[i].items.first.imageUrl;
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          stories: _stories,
                          initialStoryIndex: i,
                          currentUserId: widget.currentUserId,
                        ),
                      )),
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context2, url) => Container(color: Colors.grey[300]),
                              errorWidget: (context2, url, err) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                            )
                          : Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                    );
                  },
                ),
    );
  }
}

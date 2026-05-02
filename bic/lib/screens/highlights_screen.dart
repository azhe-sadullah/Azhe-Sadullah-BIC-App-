import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/highlight_model.dart';
import '../services/auth_service.dart';
import '../view_model/language/language_provider.dart';
import 'highlights_viewer_screen.dart';

class HighlightsScreen extends StatefulWidget {
  final String userId;

  const HighlightsScreen({super.key, required this.userId});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final AuthService _authService = AuthService();
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await _authService.getSavedUserId();
      if (mounted) setState(() { _currentUserId = userId; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createHighlight() async {
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    final titleController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKurdish ? 'دروستکردنی هایلایتی نوێ' : 'Create new highlight',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: isKurdish ? 'ناوی هایلایت' : 'Highlight name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKurdish ? 'پاشگەزبوونەوە' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isKurdish ? 'دروستکردن' : 'Create',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('highlights').add({
          'userId': widget.userId,
          'title': titleController.text,
          'coverImageUrl': null,
          'storyIds': [],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isKurdish ? 'هایلایت دروستکرا' : 'Highlight created'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isKurdish ? 'هەڵە: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = _currentUserId == widget.userId;
    final isKurdish = context.watch<LanguageProvider>().isKurdish;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(isKurdish ? 'هایلایتەکان' : 'Highlights',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: isOwnProfile
            ? [IconButton(icon: const Icon(Icons.add), onPressed: _createHighlight)]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('highlights')
                  .where('userId', isEqualTo: widget.userId)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(isKurdish ? 'هەڵە: ${snapshot.error}' : 'Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final highlights = snapshot.data?.docs ?? [];

                if (highlights.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 60, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          isOwnProfile
                              ? (isKurdish
                                  ? 'هیچ هایلایتێک نییە\nکرتە بکە لەسەر + بۆ دروستکردنی یەکێک'
                                  : 'No highlights yet\nTap + to create one')
                              : (isKurdish ? 'هیچ هایلایتێک نییە' : 'No highlights yet'),
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = HighlightModel.fromFirestore(highlights[index]);

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => HighlightsViewerScreen(
                          userId: widget.userId,
                          highlightId: highlight.id,
                          currentUserId: _currentUserId,
                        ),
                      )),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: ClipOval(
                              child: highlight.coverImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: highlight.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.bookmark, size: 30),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.bookmark, size: 30),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            highlight.title,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

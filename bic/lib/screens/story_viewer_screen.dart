import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/story_model.dart';
import '../services/firestore_service.dart';
import '../view_model/language/language_provider.dart';
import '../widgets/send_to_friends_sheet.dart';
import 'user_profile_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialStoryIndex;
  final String? currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialStoryIndex = 0,
    this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentStoryIndex;
  late int _currentItemIndex;
  late AnimationController _progressController;

  // Local like state for immediate UI feedback
  final Map<String, bool> _likedMap = {};

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex;
    _currentItemIndex = 0;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onStoryComplete();
      }
    });

    _startProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  StoryItem? get _currentItem {
    final story = widget.stories[_currentStoryIndex];
    if (_currentItemIndex < story.items.length) {
      return story.items[_currentItemIndex];
    }
    return null;
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _pauseProgress() {
    _progressController.stop();
  }

  void _resumeProgress() {
    _progressController.forward();
  }

  void _onStoryComplete() {
    final currentStory = widget.stories[_currentStoryIndex];

    if (_currentItemIndex < currentStory.items.length - 1) {
      setState(() {
        _currentItemIndex++;
      });
      _startProgress();
    } else {
      if (_currentStoryIndex < widget.stories.length - 1) {
        setState(() {
          _currentStoryIndex++;
          _currentItemIndex = 0;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startProgress();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _onPreviousStory() {
    if (_currentItemIndex > 0) {
      setState(() {
        _currentItemIndex--;
      });
      _startProgress();
    } else if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentItemIndex =
            widget.stories[_currentStoryIndex].items.length - 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    }
  }

  void _onNextStory() {
    _onStoryComplete();
  }

  void _showStoryOptions(StoryModel story) {
    _pauseProgress();
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
              title: Text(isKurdish ? 'زیادکردن بۆ هایلایت' : 'Add to Highlight',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _addToHighlight();
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_outlined, color: Colors.white),
              title: Text(isKurdish ? 'ناردن بۆ فرێند' : 'Send to Friend',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pauseProgress();
                final item = _currentItem;
                if (item?.imageUrl != null && widget.currentUserId != null) {
                  showSendToFriendsSheet(
                    context,
                    currentUserId: widget.currentUserId!,
                    mediaUrl: item!.imageUrl!,
                    mediaLabel: isKurdish ? 'ستۆری شەیرکرا' : 'Shared a story',
                  ).then((_) => _resumeProgress());
                } else {
                  _resumeProgress();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: Text(isKurdish ? 'شەیرکردن' : 'Share',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                final item = _currentItem;
                if (item?.imageUrl != null) {
                  Share.share(item!.imageUrl!);
                }
                _resumeProgress();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(isKurdish ? 'سڕینەوە' : 'Delete',
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteCurrentStory();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(_resumeProgress);
  }

  Future<void> _addToHighlight() async {
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    final item = _currentItem;
    if (item == null || widget.currentUserId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('highlights')
        .where('userId', isEqualTo: widget.currentUserId)
        .orderBy('createdAt', descending: false)
        .get();

    if (!mounted) return;
    _pauseProgress();

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                isKurdish ? 'زیادکردن بۆ هایلایت' : 'Add to Highlight',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              title: Text(isKurdish ? 'هایلایتی نوێ' : 'New Highlight',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _createNewHighlightWithStory(item);
              },
            ),
            ...snapshot.docs.map((doc) {
              final data = doc.data();
              final coverUrl = data['coverImageUrl'] as String?;
              final title = data['title'] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: coverUrl != null && coverUrl.isNotEmpty
                      ? NetworkImage(coverUrl) : null,
                  backgroundColor: Colors.grey[700],
                  child: coverUrl == null || coverUrl.isEmpty
                      ? const Icon(Icons.bookmark, color: Colors.white) : null,
                ),
                title: Text(title, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _saveStoryToHighlight(doc.id, item, coverUrl);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    _resumeProgress();
  }

  Future<void> _createNewHighlightWithStory(StoryItem item) async {
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    final titleController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isKurdish ? 'هایلایتی نوێ' : 'New Highlight',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isKurdish ? 'ناوی هایلایت' : 'Highlight name',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isKurdish ? 'پاشگەزبوونەوە' : 'Cancel',
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isKurdish ? 'دروستکردن' : 'Create',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || titleController.text.trim().isEmpty || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('highlights').add({
        'userId': widget.currentUserId,
        'title': titleController.text.trim(),
        'coverImageUrl': item.imageUrl,
        'storyIds': [item.id],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isKurdish ? 'زیادکرا بۆ هایلایت' : 'Added to highlight'),
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

  Future<void> _saveStoryToHighlight(String highlightId, StoryItem item, String? existingCover) async {
    final isKurdish = context.read<LanguageProvider>().isKurdish;
    try {
      final update = <String, dynamic>{
        'storyIds': FieldValue.arrayUnion([item.id]),
        'updatedAt': Timestamp.now(),
      };
      if (existingCover == null || existingCover.isEmpty) {
        update['coverImageUrl'] = item.imageUrl;
      }
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update(update);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isKurdish ? 'زیادکرا بۆ هایلایت' : 'Added to highlight'),
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

  Future<void> _deleteCurrentStory() async {
    final item = _currentItem;
    if (item == null) return;

    final isKurdish = context.read<LanguageProvider>().isKurdish;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isKurdish ? 'سڕینەوەی ستۆری' : 'Delete story',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isKurdish ? 'دڵنیایت لە سڕینەوەی ئەم ستۆریە؟' : 'Are you sure you want to delete this story?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isKurdish ? 'پاشگەزبوونەوە' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              isKurdish ? 'سڕینەوە' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _progressController.stop();

    try {
      await FirestoreService().deleteStory(item.id);
      if (!mounted) return;

      final story = widget.stories[_currentStoryIndex];
      if (story.items.length <= 1) {
        Navigator.pop(context);
      } else {
        _onStoryComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKurdish ? 'هەڵە: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _progressController.forward();
      }
    }
  }

  Future<void> _toggleLike() async {
    final item = _currentItem;
    if (item == null || widget.currentUserId == null) return;

    final userId = widget.currentUserId!;
    final isLiked = _likedMap[item.id] ?? item.likes.contains(userId);

    setState(() {
      _likedMap[item.id] = !isLiked;
    });

    try {
      // Use item.id (actual Firestore doc ID) not story.id (which is userId)
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(item.id)
          .update({
        'likes': isLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _likedMap[item.id] = isLiked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentStoryIndex = index;
            _currentItemIndex = 0;
          });
          _startProgress();
        },
        itemBuilder: (context, storyIndex) {
          final story = widget.stories[storyIndex];

          return GestureDetector(
            onTapDown: (_) => _pauseProgress(),
            onTapUp: (details) {
              _resumeProgress();
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.globalPosition.dx;

              if (tapPosition < screenWidth / 3) {
                _onPreviousStory();
              } else if (tapPosition > (screenWidth * 2 / 3)) {
                _onNextStory();
              }
            },
            onTapCancel: () => _resumeProgress(),
            onLongPress: () => _pauseProgress(),
            onLongPressEnd: (_) => _resumeProgress(),
            child: Stack(
              children: [
                // Story Content
                Center(
                  child: _currentStoryIndex == storyIndex
                      ? _buildStoryContent(story)
                      : Container(),
                ),

                // Overlay text
                if (_currentStoryIndex == storyIndex &&
                    _currentItem?.overlayText?.isNotEmpty == true)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentItem!.overlayText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Progress Bars
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: _buildProgressBars(story),
                  ),
                ),

                // Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: _buildHeader(story),
                  ),
                ),

                // Close + 3-dot menu
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (story.userId == widget.currentUserId)
                          IconButton(
                            onPressed: () => _showStoryOptions(story),
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white, size: 26),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),

                // Like button — only shown for active story AND not own story
                if (_currentStoryIndex == storyIndex &&
                    _currentItem != null &&
                    widget.stories[storyIndex].userId != widget.currentUserId)
                  Positioned(
                    right: 16,
                    bottom: 40,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: _buildLikeButton(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikeButton() {
    final item = _currentItem;
    if (item == null) return const SizedBox();

    final userId = widget.currentUserId;
    final isLiked =
        _likedMap[item.id] ?? (userId != null && item.likes.contains(userId));

    return Column(
      children: [
        Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.white,
          size: 32,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
        ),
        if (item.likes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.likes.length.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (_currentItemIndex >= story.items.length) {
      return const SizedBox();
    }

    final item = story.items[_currentItemIndex];

    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: item.imageUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white, size: 50),
          ),
        ),
      );
    }

    if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline,
                color: Colors.white, size: 80),
            const SizedBox(height: 16),
            Builder(builder: (ctx) {
              final isKu = ctx.watch<LanguageProvider>().isKurdish;
              return Text(
                isKu ? 'ڤیدیۆ پشتگیری ناکرێت لە ئێستادا' : 'Video not supported yet',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              );
            }),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildProgressBars(StoryModel story) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(
          story.items.length,
          (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 2.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    double progress = 0.0;
                    if (index < _currentItemIndex) {
                      progress = 1.0;
                    } else if (index == _currentItemIndex) {
                      progress = _progressController.value;
                    }
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(StoryModel story) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (story.userId != widget.currentUserId) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: story.userId),
                ));
              }
            },
            child: CircleAvatar(
              radius: 18,
              backgroundImage: story.userAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(story.userAvatar)
                  : null,
              child: story.userAvatar.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (story.userId != widget.currentUserId) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: story.userId),
                  ));
                }
              },
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.username,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (_currentItemIndex < story.items.length)
                  Text(
                    _timeAgo(
                      story.items[_currentItemIndex].createdAt,
                      isKurdish: context.watch<LanguageProvider>().isKurdish,
                    ),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date, {bool isKurdish = true}) {
    final diff = DateTime.now().difference(date);

    if (isKurdish) {
      if (diff.inDays > 0) return '${diff.inDays} ڕۆژ پێش ئێستا';
      if (diff.inHours > 0) return '${diff.inHours} کاتژمێر پێش ئێستا';
      if (diff.inMinutes > 0) return '${diff.inMinutes} خولەک پێش ئێستا';
      return 'ئێستا';
    } else {
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    }
  }
}

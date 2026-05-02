import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
import '../view_model/language/language_provider.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/create_story_screen.dart';

class StoriesBar extends StatelessWidget {
  final List<StoryModel> stories;
  final String? currentUserId;
  final String? currentUserAvatar;

  const StoriesBar({
    super.key,
    required this.stories,
    this.currentUserId,
    this.currentUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final bool myStoryInList =
        stories.isNotEmpty && stories.first.userId == currentUserId;

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        // If current user's story not first in list, add an extra slot at index 0
        itemCount: myStoryInList ? stories.length : stories.length + 1,
        itemBuilder: (context, index) {
          // Index 0 is always "my story" slot
          if (index == 0 && !myStoryInList) {
            return _buildMyStorySlot(context);
          }
          final storyIndex = myStoryInList ? index : index - 1;
          final story = stories[storyIndex];
          final isMyStory = story.userId == currentUserId;

          return _buildStoryItem(context, story, isMyStory, storyIndex);
        },
      ),
    );
  }

  Widget _buildMyStorySlot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: currentUserAvatar?.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: currentUserAvatar!,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.person, size: 30),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 30),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            SizedBox(
              width: 68,
              child: Text(
                context.watch<LanguageProvider>().isKurdish ? 'ستۆریت' : 'Your story',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(
      BuildContext context, StoryModel story, bool isMyStory, int storyIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          if (story.items.isEmpty) {
            // Own story slot with no stories yet → create story
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryViewerScreen(
                  stories: stories,
                  initialStoryIndex: storyIndex,
                  currentUserId: currentUserId,
                ),
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: story.hasUnseenStories
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFF006E),
                              Color(0xFFFFBE0B),
                              Color(0xFFFF006E),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : null,
                    border: !story.hasUnseenStories
                        ? Border.all(color: Colors.grey[400]!, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: story.userAvatar.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: story.userAvatar,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.person, size: 30),
                              memCacheHeight: 150,
                              memCacheWidth: 150,
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 30),
                            ),
                    ),
                  ),
                ),
                if (isMyStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            SizedBox(
              width: 68,
              child: Text(
                isMyStory
                    ? (context.watch<LanguageProvider>().isKurdish ? 'ستۆریت' : 'Your story')
                    : story.username,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

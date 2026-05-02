import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/story_model.dart';
import '../view_model/language/language_provider.dart';
import 'chat_screen.dart';
import 'story_viewer_screen.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _myId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _followingIds = [];

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _markAllChatsAsRead();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _markAllChatsAsRead() async {
    if (_myId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('chats').where('participants', arrayContains: _myId).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'readBy': FieldValue.arrayUnion([_myId])});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _loadFollowing() async {
    if (_myId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_myId).get();
      if (doc.exists && mounted) {
        setState(() => _followingIds = List<String>.from(doc.data()?['following'] ?? []));
      }
    } catch (_) {}
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 6) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(lang.isKurdish ? 'چات' : 'Chats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: lang.isKurdish ? 'گرووپ چات' : 'Group chat',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(myId: _myId))),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: lang.isKurdish ? 'گەڕان بۆ گفتوگۆ...' : 'Search chats...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                          onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          if (_followingIds.isNotEmpty) _StoriesBar(myId: _myId, followingIds: _followingIds),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: _myId)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${lang.errorLabel}: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!, width: 2)),
                        child: Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(lang.isKurdish ? 'هیچ گفتوگۆیەک نییە' : 'No conversations yet',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        lang.isKurdish ? 'بەسەر پرۆفایلی کەسێکدا بگات و پەیامی پێ بنێرە' : 'Visit someone\'s profile and send them a message',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    if (data['isGroup'] == true) {
                      return _GroupChatTile(data: data, myId: _myId, searchQuery: _searchQuery, timeAgo: _timeAgo);
                    }

                    final conv = ChatConversation.fromFirestore(docs[index]);
                    final otherId = conv.participants.firstWhere((id) => id != _myId, orElse: () => '');
                    if (otherId.isEmpty) return const SizedBox();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox(height: 72);
                        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final username = userData['username'] ?? (lang.isKurdish ? 'بەکارهێنەر' : 'User');

                        if (_searchQuery.isNotEmpty && !username.toLowerCase().contains(_searchQuery.toLowerCase())) {
                          return const SizedBox();
                        }

                        final avatar = userData['avatar'] ?? userData['photoUrl'] ?? '';
                        final isMe = conv.lastSenderId == _myId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(otherUserId: otherId, otherUsername: username, otherAvatar: avatar),
                          )),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                            child: avatar.isEmpty ? const Icon(Icons.person, size: 26) : null,
                          ),
                          title: Text(username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text(
                            isMe ? '${lang.isKurdish ? 'تۆ' : 'You'}: ${conv.lastMessage}' : conv.lastMessage,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                          trailing: Text(_timeAgo(conv.lastMessageTime), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesBar extends StatelessWidget {
  final String myId;
  final List<String> followingIds;
  const _StoriesBar({required this.myId, required this.followingIds});

  @override
  Widget build(BuildContext context) {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('userId', whereIn: followingIds.take(10).toList())
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();

        final stories = <StoryModel>[];
        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = (data['items'] as List? ?? []).where((item) {
            final exp = item['expiresAt'];
            return exp == null || (exp as Timestamp).compareTo(cutoff) > 0;
          }).toList();
          if (items.isEmpty) continue;
          stories.add(StoryModel(
            id: doc.id, userId: data['userId'] ?? '',
            username: data['username'] ?? '', userAvatar: data['userAvatar'] ?? '',
            items: items.map((i) => StoryItem.fromFirestore(i as Map<String, dynamic>)).toList(),
          ));
        }
        if (stories.isEmpty) return const SizedBox();

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StoryViewerScreen(stories: stories, initialStoryIndex: index, currentUserId: myId),
                )),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 56, height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFE1306C), Color(0xFFFCAF45)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: story.userAvatar.isNotEmpty ? CachedNetworkImageProvider(story.userAvatar) : null,
                          child: story.userAvatar.isEmpty ? const Icon(Icons.person, size: 24) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(story.username, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GroupChatTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String myId;
  final String searchQuery;
  final String Function(DateTime?) timeAgo;

  const _GroupChatTile({required this.data, required this.myId, required this.searchQuery, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    final groupName = data['groupName'] ?? (lang.isKurdish ? 'گرووپ' : 'Group');
    final groupAvatar = data['groupAvatar'] ?? '';
    final lastMessage = data['lastMessage'] ?? '';
    final lastSenderId = data['lastSenderId'] ?? '';
    final chatId = data['id'] ?? '';
    final participants = List<String>.from(data['participants'] ?? []);

    DateTime? lastTime;
    final lmt = data['lastMessageTime'];
    if (lmt is Timestamp) lastTime = lmt.toDate();

    if (searchQuery.isNotEmpty && !groupName.toLowerCase().contains(searchQuery.toLowerCase())) {
      return const SizedBox();
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => GroupChatScreen(myId: myId, existingChatId: chatId, groupName: groupName, groupAvatar: groupAvatar, participants: participants),
      )),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF833AB4),
        backgroundImage: groupAvatar.isNotEmpty ? CachedNetworkImageProvider(groupAvatar) : null,
        child: groupAvatar.isEmpty ? const Icon(Icons.group, color: Colors.white, size: 26) : null,
      ),
      title: Row(children: [
        Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(width: 6),
        Icon(Icons.group, size: 14, color: Colors.grey[500]),
      ]),
      subtitle: Text(
        lastSenderId == myId ? '${lang.isKurdish ? 'تۆ' : 'You'}: $lastMessage' : lastMessage,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
      trailing: Text(timeAgo(lastTime), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
    );
  }
}

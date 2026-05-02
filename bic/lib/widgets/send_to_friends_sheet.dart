import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../view_model/language/language_provider.dart';

/// Shows a bottom sheet to send a story/highlight to mutual friends via DM.
Future<void> showSendToFriendsSheet(
  BuildContext context, {
  required String currentUserId,
  required String mediaUrl,
  required String mediaLabel, // e.g. "Story" or highlight title
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SendToFriendsSheet(
      currentUserId: currentUserId,
      mediaUrl: mediaUrl,
      mediaLabel: mediaLabel,
    ),
  );
}

class _SendToFriendsSheet extends StatefulWidget {
  final String currentUserId;
  final String mediaUrl;
  final String mediaLabel;

  const _SendToFriendsSheet({
    required this.currentUserId,
    required this.mediaUrl,
    required this.mediaLabel,
  });

  @override
  State<_SendToFriendsSheet> createState() => _SendToFriendsSheetState();
}

class _SendToFriendsSheetState extends State<_SendToFriendsSheet> {
  List<Map<String, dynamic>> _friends = [];
  final Set<String> _sent = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMutualFriends();
  }

  Future<void> _loadMutualFriends() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();

      if (!doc.exists) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final followers = List<String>.from(data['followers'] ?? []);
      final following = List<String>.from(data['following'] ?? []);

      // Mutual = people I follow AND they follow me back
      final mutualIds =
          following.where((id) => followers.contains(id)).toList();

      if (mutualIds.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Load their user data (batch, max 50)
      final ids = mutualIds.take(50).toList();
      final friendDocs = await Future.wait(
        ids.map((id) =>
            FirebaseFirestore.instance.collection('users').doc(id).get()),
      );

      final friends = friendDocs
          .where((d) => d.exists)
          .map((d) {
            final fd = d.data() as Map<String, dynamic>;
            return {
              'id': d.id,
              'username': fd['username'] ?? '',
              'avatar': fd['avatar'] ?? '',
            };
          })
          .toList();

      if (mounted) {
        setState(() {
          _friends = friends;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendTo(String friendId) async {
    if (_sent.contains(friendId)) return;

    final chatId = chatIdFor(widget.currentUserId, friendId);
    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    try {
      await chatRef.set({
        'participants': [widget.currentUserId, friendId],
        'lastMessage': widget.mediaLabel,
        'lastSenderId': widget.currentUserId,
        'lastMessageTime': Timestamp.now(),
        'readBy': [widget.currentUserId],
      }, SetOptions(merge: true));

      await chatRef.collection('messages').add({
        'senderId': widget.currentUserId,
        'text': widget.mediaLabel,
        'type': 'media_share',
        'mediaUrl': widget.mediaUrl,
        'timestamp': Timestamp.now(),
        'seen': false,
      });

      if (mounted) setState(() => _sent.add(friendId));
    } catch (e) {
      // silently skip
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKurdish = context.watch<LanguageProvider>().isKurdish;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              isKurdish ? 'ناردن بۆ فرێند' : 'Send to Friend',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 60, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text(
                              isKurdish
                                  ? 'هیچ فرێندێک نییە'
                                  : 'No mutual friends',
                              style: TextStyle(color: Colors.grey[500], fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _friends.length,
                        itemBuilder: (ctx, i) {
                          final f = _friends[i];
                          final isSent = _sent.contains(f['id']);
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  (f['avatar'] as String).isNotEmpty
                                      ? NetworkImage(f['avatar'] as String)
                                      : null,
                              backgroundColor: Colors.grey[700],
                              child: (f['avatar'] as String).isEmpty
                                  ? Text(
                                      (f['username'] as String)
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(
                              '@${f['username']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            trailing: isSent
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () => _sendTo(f['id'] as String),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3897F0),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      isKurdish ? 'بنێرە' : 'Send',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

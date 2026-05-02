import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';
import '../view_model/language/language_provider.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;
  final String otherAvatar;

  const ChatScreen({super.key, required this.otherUserId, required this.otherUsername, required this.otherAvatar});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final String _chatId;
  late final String _myId;
  String _myUsername = '';
  String _myAvatar = '';
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _myId = FirebaseAuth.instance.currentUser!.uid;
    _chatId = chatIdFor(_myId, widget.otherUserId);
    _loadMyData();
    _markChatAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markChatAsRead() async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'readBy': FieldValue.arrayUnion([_myId]),
      });
    } catch (_) {}
  }

  Future<void> _loadMyData() async {
    final user = await _firestoreService.getUser(_myId);
    if (user != null && mounted) setState(() { _myUsername = user.username; _myAvatar = user.avatar ?? ''; });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      await chatRef.set({
        'participants': [_myId, widget.otherUserId],
        'lastMessage': text,
        'lastSenderId': _myId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readBy': [_myId],
      }, SetOptions(merge: true));

      await chatRef.collection('messages').add({
        'senderId': _myId, 'text': text,
        'timestamp': FieldValue.serverTimestamp(), 'seen': false,
      });

      _firestoreService.createNotification({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'message', 'fromUserId': _myId,
        'fromUsername': _myUsername, 'fromUserAvatar': _myAvatar,
        'toUserId': widget.otherUserId, 'commentText': text,
        'isRead': false, 'createdAt': DateTime.now(),
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${context.read<LanguageProvider>().strings.errorLabel}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: widget.otherAvatar.isNotEmpty ? CachedNetworkImageProvider(widget.otherAvatar) : null,
            child: widget.otherAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
          ),
          const SizedBox(width: 10),
          Text(widget.otherUsername, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 26), onPressed: () {}),
          IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 22), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats').doc(_chatId).collection('messages')
                  .orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('${lang.errorLabel}: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                    ]),
                  ));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(
                      radius: 44, backgroundColor: Colors.grey[900],
                      backgroundImage: widget.otherAvatar.isNotEmpty ? CachedNetworkImageProvider(widget.otherAvatar) : null,
                      child: widget.otherAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 44) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(widget.otherUsername, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(lang.isKurdish ? 'دەستبکە بە گفتوگۆ!' : 'Start the conversation!',
                        style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  ]));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = ChatMessage.fromFirestore(docs[index]);
                    final isMe = msg.senderId == _myId;
                    return _buildBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputBar(lang),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe) {
    if (msg.type == 'media_share' && msg.mediaUrl != null) {
      return _buildShareBubble(msg, isMe);
    }
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFFC00) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(msg.text, style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildShareBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFFC00) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            child: CachedNetworkImage(
              imageUrl: msg.mediaUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(height: 180, color: Colors.grey[800], child: const Center(child: CircularProgressIndicator())),
              errorWidget: (ctx, url, err) => Container(height: 180, color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54)),
            ),
          ),
          if (msg.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(msg.text, style: TextStyle(color: isMe ? Colors.black87 : Colors.white70, fontSize: 13)),
            ),
        ]),
      ),
    );
  }

  Widget _buildInputBar(dynamic lang) {
    return Container(
      color: const Color(0xFF111111),
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: lang.isKurdish ? 'پەیامێک بنێرە...' : 'Send a message...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(color: Color(0xFFFFFC00), shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
          ),
        ),
      ]),
    );
  }
}

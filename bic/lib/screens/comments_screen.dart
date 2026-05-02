import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../view_model/language/language_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'user_profile_screen.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  const CommentsScreen({super.key, required this.postId, required this.postOwnerId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isSubmitting = false;

  List<UserModel> _mentionSuggestions = [];
  String _mentionQuery = '';
  int _mentionStartIndex = -1;
  final Map<String, GestureRecognizer> _recognizerCache = {};

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _focusNode.dispose();
    for (final r in _recognizerCache.values) { r.dispose(); }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _commentController.text;
    final cursor = _commentController.selection.baseOffset;
    if (cursor < 0) return;

    final textBefore = text.substring(0, cursor);
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex == -1) { _clearMentions(); return; }

    final query = textBefore.substring(atIndex + 1);
    if (query.contains(' ') || query.contains('\n')) { _clearMentions(); return; }

    _mentionStartIndex = atIndex;
    _mentionQuery = query;
    if (query.isNotEmpty) _fetchMentions(query);
  }

  void _clearMentions() {
    if (_mentionSuggestions.isNotEmpty || _mentionQuery.isNotEmpty) {
      setState(() { _mentionSuggestions = []; _mentionQuery = ''; _mentionStartIndex = -1; });
    }
  }

  Future<void> _fetchMentions(String query) async {
    try {
      final results = await _firestoreService.searchUsers(query);
      if (mounted && _mentionQuery == query) setState(() => _mentionSuggestions = results);
    } catch (_) {}
  }

  void _insertMention(UserModel user) {
    final cursor = _commentController.selection.baseOffset;
    if (cursor < 0 || _mentionStartIndex < 0) return;
    final before = _commentController.text.substring(0, _mentionStartIndex);
    final after = _commentController.text.substring(cursor);
    final newText = '$before@${user.username} $after';
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _mentionStartIndex + user.username.length + 2),
    );
    setState(() { _mentionSuggestions = []; _mentionQuery = ''; _mentionStartIndex = -1; });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) return;
      final text = _commentController.text.trim();
      await _firestoreService.addComment({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'postId': widget.postId,
        'userId': user.id,
        'username': user.username,
        'userAvatar': user.avatar ?? '',
        'text': text,
        'likesCount': 0,
        'likes': [],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestoreService.deleteComment(commentId, widget.postId);
    } catch (_) {}
  }

  GestureRecognizer _tapRecognizer(String username) {
    return _recognizerCache.putIfAbsent(username, () =>
      TapGestureRecognizer()..onTap = () async {
        try {
          final results = await _firestoreService.searchUsers(username);
          final user = results.firstWhere((u) => u.username == username);
          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)));
        } catch (_) {}
      });
  }

  Widget _buildCommentText(String text) {
    final regex = RegExp(r'@(\w+)');
    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
        recognizer: _tapRecognizer(match.group(1)!),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) spans.add(TextSpan(text: text.substring(lastEnd)));
    if (spans.isEmpty) return Text(text, style: const TextStyle(fontSize: 14));
    return RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black87), children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(title: Text(lang.isKurdish ? 'کۆمێنتەکان' : 'Comments', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getPostComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('${lang.errorLabel}: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Ionicons.chatbubbles_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(lang.isKurdish ? 'هیچ کۆمێنتێک نییە' : 'No comments yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return FutureBuilder<String?>(
                  future: _authService.getSavedUserId(),
                  builder: (context, userSnap) {
                    final currentUserId = userSnap.data;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, i) {
                        final d = snapshot.data!.docs[i].data() as Map<String, dynamic>;
                        final commentId = snapshot.data!.docs[i].id;
                        final comment = CommentModel(
                          id: commentId,
                          postId: d['postId'] ?? '',
                          userId: d['userId'] ?? '',
                          username: d['username'] ?? 'Unknown',
                          userAvatar: d['userAvatar'] ?? '',
                          text: d['text'] ?? '',
                          likesCount: d['likesCount'] ?? 0,
                          likes: List<String>.from(d['likes'] ?? []),
                          createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
                        );
                        final isOwn = currentUserId == comment.userId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: comment.userId))),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: comment.userAvatar.isNotEmpty ? NetworkImage(comment.userAvatar) : null,
                                  child: comment.userAvatar.isEmpty ? Text(comment.username[0].toUpperCase()) : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(comment.username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        Text(timeago.format(comment.createdAt, locale: 'en_short'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    _buildCommentText(comment.text),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (isOwn) ...[
                                          GestureDetector(
                                            onTap: () => _deleteComment(comment.id),
                                            child: Text(lang.deleteLabel, style: const TextStyle(fontSize: 12, color: Colors.red)),
                                          ),
                                          const SizedBox(width: 16),
                                        ],
                                        GestureDetector(
                                          onTap: () {
                                            _commentController.text = '@${comment.username} ';
                                            _commentController.selection = TextSelection.fromPosition(TextPosition(offset: _commentController.text.length));
                                            _focusNode.requestFocus();
                                          },
                                          child: Text(lang.isKurdish ? 'وەڵام بدەرەوە' : 'Reply', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_mentionSuggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mentionSuggestions.length,
                  itemBuilder: (_, i) {
                    final user = _mentionSuggestions[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: user.avatar?.isNotEmpty == true ? NetworkImage(user.avatar!) : null,
                        child: user.avatar?.isEmpty ?? true ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 12)) : null,
                      ),
                      title: Text('@${user.username}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      onTap: () => _insertMention(user),
                    );
                  },
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: lang.isKurdish ? 'کۆمێنت بنووسە... (@username بۆ تاگکردن)' : 'Write a comment... (@username to tag)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        onPressed: _submitComment,
                        icon: Icon(Ionicons.send, color: _commentController.text.trim().isEmpty ? Colors.grey[400] : Colors.blue, size: 24),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

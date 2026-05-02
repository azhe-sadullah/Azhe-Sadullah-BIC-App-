import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// GroupChatScreen — Messenger-style
// ─────────────────────────────────────────────────────────────────────────────
class GroupChatScreen extends StatefulWidget {
  final String myId;
  final String? existingChatId;
  final String? groupName;
  final String? groupAvatar;
  final List<String>? participants;

  const GroupChatScreen({
    super.key,
    required this.myId,
    this.existingChatId,
    this.groupName,
    this.groupAvatar,
    this.participants,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _groupNameCtrl = TextEditingController();

  String? _chatId;
  String _groupName = '';
  String _groupAvatar = '';
  List<String> _participants = [];
  List<Map<String, dynamic>> _followingUsers = [];
  final List<String> _selectedIds = [];
  bool _isCreating = false;
  bool _isSending = false;

  Map<String, dynamic>? _replyTo;

  final Map<String, String> _nameCache = {};
  final Map<String, String> _avatarCache = {};

  bool get _isChat => _chatId != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingChatId != null) {
      _chatId = widget.existingChatId;
      _groupName = widget.groupName ?? 'گرووپ';
      _groupAvatar = widget.groupAvatar ?? '';
      _participants = widget.participants ?? [];
      _preloadMembers();
      _markChatAsRead();
    } else {
      _loadFollowing();
    }
  }

  Future<void> _markChatAsRead() async {
    if (_chatId == null) return;
    try {
      await _db.collection('chats').doc(_chatId).update({
        'readBy': FieldValue.arrayUnion([widget.myId]),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _preloadMembers() async {
    for (final uid in _participants) {
      if (_nameCache.containsKey(uid)) continue;
      try {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists) {
          _nameCache[uid] = doc.data()?['username'] ?? '?';
          _avatarCache[uid] = doc.data()?['avatar'] ?? '';
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadFollowing() async {
    try {
      final doc = await _db.collection('users').doc(widget.myId).get();
      if (!doc.exists || !mounted) return;
      final ids = List<String>.from(doc.data()?['following'] ?? []);
      if (ids.isEmpty) return;
      final snaps = await Future.wait(ids.map((id) => _db.collection('users').doc(id).get()));
      if (mounted) {
        setState(() {
          _followingUsers = snaps.where((d) => d.exists).map((d) => {'id': d.id, ...d.data()!}).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _createGroup() async {
    if (_groupNameCtrl.text.trim().isEmpty || _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_groupNameCtrl.text.trim().isEmpty ? 'ناوی گرووپ بنووسە' : 'لانیکەم یەک کەس هەڵبژێرە'),
        backgroundColor: const Color(0xFF0084FF),
      ));
      return;
    }
    setState(() => _isCreating = true);
    try {
      final participants = [widget.myId, ..._selectedIds];
      final docRef = _db.collection('chats').doc();
      await docRef.set({
        'id': docRef.id,
        'isGroup': true,
        'groupName': _groupNameCtrl.text.trim(),
        'groupAvatar': '',
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': widget.myId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.myId,
      });
      if (mounted) {
        setState(() {
          _chatId = docRef.id;
          _groupName = _groupNameCtrl.text.trim();
          _participants = participants;
          _isCreating = false;
        });
        _preloadMembers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('هەڵە: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _chatId == null) return;
    _msgCtrl.clear();
    final reply = _replyTo;
    if (mounted) setState(() => _replyTo = null);
    setState(() => _isSending = true);
    try {
      final msgRef = _db.collection('chats').doc(_chatId).collection('messages').doc();
      await msgRef.set({
        'id': msgRef.id,
        'senderId': widget.myId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'isDeleted': false,
        'isEdited': false,
        'reactions': {},
        if (reply != null) 'replyTo': reply,
      });
      await _db.collection('chats').doc(_chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': widget.myId,
        'readBy': [widget.myId],
      });
      _scrollToBottom();
    } catch (_) {}
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _editMessage(String msgId, String newText) async {
    if (_chatId == null || newText.trim().isEmpty) return;
    await _db.collection('chats').doc(_chatId).collection('messages').doc(msgId)
        .update({'text': newText.trim(), 'isEdited': true});
  }

  Future<void> _deleteMessage(String msgId) async {
    if (_chatId == null) return;
    await _db.collection('chats').doc(_chatId).collection('messages').doc(msgId)
        .update({'isDeleted': true, 'text': ''});
  }

  Future<void> _reactMessage(String msgId, String emoji) async {
    if (_chatId == null) return;
    final ref = _db.collection('chats').doc(_chatId).collection('messages').doc(msgId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final reactions = Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);
    if (users.contains(widget.myId)) { users.remove(widget.myId); } else { users.add(widget.myId); }
    if (users.isEmpty) { reactions.remove(emoji); } else { reactions[emoji] = users; }
    await ref.update({'reactions': reactions});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  String _memberName(String uid) => uid == widget.myId ? 'تۆ' : (_nameCache[uid] ?? uid.substring(0, 6));
  String _memberAvatar(String uid) => _avatarCache[uid] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _isChat ? _buildChatAppBar() : _buildCreationAppBar(),
      body: _isChat ? _buildChatBody() : _buildCreationBody(),
    );
  }

  // ── App bars ───────────────────────────────────────────────────
  AppBar _buildChatAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _GroupAvatar(avatar: _groupAvatar, name: _groupName, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_groupName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${_participants.length} ئەندام',
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF0084FF), size: 24),
          onPressed: _showGroupInfo,
        ),
      ],
    );
  }

  AppBar _buildCreationAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: const Text('گرووپی نوێ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : _createGroup,
          child: const Text('دروستکردن',
              style: TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  // ── Group creation UI ─────────────────────────────────────────
  Widget _buildCreationBody() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0084FF), Color(0xFF833AB4)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _groupNameCtrl,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'ناوی گرووپ...',
                    hintStyle: TextStyle(color: Colors.black45, fontSize: 16),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('ئەوانەی فۆڵۆوت کردوون',
                  style: TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF0084FF), borderRadius: BorderRadius.circular(12)),
                  child: Text('${_selectedIds.length} هەڵبژێردرا',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _followingUsers.isEmpty
              ? const Center(child: Text('هیچ کەسێک فۆڵۆو نەکردووە', style: TextStyle(color: Colors.black45)))
              : ListView.builder(
                  itemCount: _followingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _followingUsers[index];
                    final uid = user['id'] as String;
                    final username = user['username'] ?? 'بەکارهێنەر';
                    final avatar = user['avatar'] ?? '';
                    final selected = _selectedIds.contains(uid);
                    return ListTile(
                      onTap: () {
                        setState(() { selected ? _selectedIds.remove(uid) : _selectedIds.add(uid); });
                        HapticFeedback.selectionClick();
                      },
                      leading: _UserAvatar(avatar: avatar, name: username, size: 44),
                      title: Text(username,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      trailing: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? const Color(0xFF0084FF) : Colors.transparent,
                          border: Border.all(
                            color: selected ? const Color(0xFF0084FF) : Colors.black45, width: 2),
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  },
                ),
        ),
        if (_isCreating)
          const LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0084FF))),
      ],
    );
  }

  // ── Chat body ─────────────────────────────────────────────────
  Widget _buildChatBody() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('chats').doc(_chatId).collection('messages')
                .orderBy('timestamp', descending: true).limit(100).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)));
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _GroupAvatar(avatar: _groupAvatar, name: _groupName, size: 80),
                    const SizedBox(height: 16),
                    Text(_groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 8),
                    const Text('پەیامی یەکەم بنێرە! 👋', style: TextStyle(color: Colors.black45)),
                  ]),
                );
              }
              return ListView.builder(
                controller: _scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final msgId = docs[i].id;
                  final isFirstInGroup = i == 0 ||
                      (docs[i - 1].data() as Map<String, dynamic>)['senderId'] != data['senderId'];
                  final isLastInGroup = i == docs.length - 1 ||
                      (docs[i + 1].data() as Map<String, dynamic>)['senderId'] != data['senderId'];
                  return _MessageBubble(
                    key: ValueKey(msgId),
                    data: data, msgId: msgId, myId: widget.myId,
                    isFirstInGroup: isFirstInGroup, isLastInGroup: isLastInGroup,
                    memberName: _memberName(data['senderId'] ?? ''),
                    memberAvatar: _memberAvatar(data['senderId'] ?? ''),
                    onReply: (d) => setState(() => _replyTo = d),
                    onEdit: (id, text) => _showEditDialog(id, text),
                    onDelete: (id) => _confirmDelete(id),
                    onReact: (id, emoji) => _reactMessage(id, emoji),
                  );
                },
              );
            },
          ),
        ),
        if (_replyTo != null)
          _ReplyPreview(
            data: _replyTo!,
            memberName: _memberName(_replyTo!['senderId'] ?? ''),
            onClose: () => setState(() => _replyTo = null),
          ),
        _InputBar(controller: _msgCtrl, isSending: _isSending, onSend: _sendMessage),
      ],
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────
  void _showEditDialog(String msgId, String currentText) {
    final ctrl = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('دەستکاریکردنی پەیام',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.black87),
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('پاشگەزبوون', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () { _editMessage(msgId, ctrl.text); Navigator.pop(context); },
            child: const Text('پاشەکەوتکردن',
                style: TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String msgId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('سڕینەوەی پەیام',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: const Text('دڵنیایت دەتەوێت ئەم پەیامە بسڕیتەوە؟',
            style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('نەخێر', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () { _deleteMessage(msgId); Navigator.pop(context); },
            child: const Text('سڕینەوە', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _GroupAvatar(avatar: _groupAvatar, name: _groupName, size: 72),
            const SizedBox(height: 12),
            Text(_groupName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            Text('${_participants.length} ئەندام',
                style: const TextStyle(color: Colors.black45, fontSize: 14)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: _participants.map((uid) {
                final name = _memberName(uid);
                final avatar = _memberAvatar(uid);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UserAvatar(avatar: avatar, name: name, size: 46),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final String msgId;
  final String myId;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String memberName;
  final String memberAvatar;
  final void Function(Map<String, dynamic>) onReply;
  final void Function(String, String) onEdit;
  final void Function(String) onDelete;
  final void Function(String, String) onReact;

  const _MessageBubble({
    super.key,
    required this.data,
    required this.msgId,
    required this.myId,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.memberName,
    required this.memberAvatar,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
  });

  static const _emojis = ['👍', '❤️', '😆', '😮', '😢', '😡'];
  static const _messengerBlue = Color(0xFF0084FF);

  bool get isMe => data['senderId'] == myId;
  bool get isDeleted => data['isDeleted'] == true;
  bool get isEdited => data['isEdited'] == true;

  String _timeStr(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    return timeago.format(dt, locale: 'en_short');
  }

  Map<String, List<String>> get _reactions {
    final raw = data['reactions'];
    if (raw == null) return {};
    return (raw as Map).map((k, v) => MapEntry(k.toString(), List<String>.from(v as List)));
  }

  @override
  Widget build(BuildContext context) {
    final replyTo = data['replyTo'] as Map<String, dynamic>?;
    final reactions = _reactions;
    final hasReactions = reactions.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(top: isLastInGroup ? 6 : 1, bottom: isFirstInGroup ? 6 : 1),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: isFirstInGroup
                  ? _UserAvatar(avatar: memberAvatar, name: memberName, size: 32)
                  : const SizedBox(width: 32),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageMenu(context),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && isLastInGroup)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Text(memberName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0084FF))),
                    ),
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      color: isDeleted
                          ? Colors.transparent
                          : isMe ? _messengerBlue : const Color(0xFFE4E6EB),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : (isFirstInGroup ? 4 : 18)),
                        bottomRight: Radius.circular(isMe ? (isFirstInGroup ? 4 : 18) : 18),
                      ),
                      border: isDeleted ? Border.all(color: Colors.black26, width: 1) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (replyTo != null && !isDeleted) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFF0084FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(
                                  color: isMe ? Colors.white : const Color(0xFF0084FF), width: 3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(replyTo['senderName'] ?? '',
                                      style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.bold,
                                          color: isMe ? Colors.white : const Color(0xFF0084FF))),
                                  Text(replyTo['text'] ?? '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isMe ? Colors.white70 : Colors.black45),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          isDeleted
                              ? const Text('🚫  پەیام سڕایەوە',
                                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black38))
                              : Text(data['text'] ?? '',
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      color: isMe ? Colors.white : Colors.black87)),
                          if (!isDeleted)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEdited)
                                    Text('دەستکاریکرا · ',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: isMe ? Colors.white60 : Colors.black38)),
                                  Text(_timeStr(data['timestamp']),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white60 : Colors.black38)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (hasReactions)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(
                        spacing: 4,
                        children: reactions.entries.map((e) {
                          final count = e.value.length;
                          final mine = e.value.contains(myId);
                          return GestureDetector(
                            onTap: () => onReact(msgId, e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: mine
                                    ? _messengerBlue.withValues(alpha: 0.15)
                                    : const Color(0xFFE4E6EB),
                                borderRadius: BorderRadius.circular(12),
                                border: mine ? Border.all(color: _messengerBlue, width: 1) : null,
                              ),
                              child: Text(count > 1 ? '${e.key} $count' : e.key,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageMenuSheet(
        isMe: isMe,
        isDeleted: isDeleted,
        emojis: _emojis,
        onReact: (e) { Navigator.pop(context); onReact(msgId, e); },
        onReply: () {
          Navigator.pop(context);
          onReply({'senderId': data['senderId'], 'senderName': memberName, 'text': data['text'] ?? ''});
        },
        onEdit: isMe && !isDeleted ? () { Navigator.pop(context); onEdit(msgId, data['text'] ?? ''); } : null,
        onDelete: isMe && !isDeleted ? () { Navigator.pop(context); onDelete(msgId); } : null,
        onCopy: !isDeleted ? () { Clipboard.setData(ClipboardData(text: data['text'] ?? '')); Navigator.pop(context); } : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message context menu sheet
// ─────────────────────────────────────────────────────────────────────────────
class _MessageMenuSheet extends StatelessWidget {
  final bool isMe;
  final bool isDeleted;
  final List<String> emojis;
  final void Function(String) onReact;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const _MessageMenuSheet({
    required this.isMe,
    required this.isDeleted,
    required this.emojis,
    required this.onReact,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDeleted)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: emojis.map((e) => GestureDetector(
                onTap: () => onReact(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(e, style: const TextStyle(fontSize: 26)),
                ),
              )).toList(),
            ),
          ),
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              _menuItem(Icons.reply_rounded, 'وەڵامدانەوە', Colors.black87, onReply, const Color(0xFF0084FF)),
              if (onCopy != null)
                _menuItem(Icons.copy_rounded, 'کۆپیکردن', Colors.black87, onCopy!, Colors.grey),
              if (onEdit != null)
                _menuItem(Icons.edit_rounded, 'دەستکاریکردن', Colors.black87, onEdit!, Colors.orange),
              if (onDelete != null)
                _menuItem(Icons.delete_outline_rounded, 'سڕینەوە', Colors.red, onDelete!, Colors.red),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, Color textColor, VoidCallback onTap, Color iconColor) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.12)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reply preview bar
// ─────────────────────────────────────────────────────────────────────────────
class _ReplyPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  final String memberName;
  final VoidCallback onClose;

  const _ReplyPreview({required this.data, required this.memberName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
          left: BorderSide(color: Color(0xFF0084FF), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(memberName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0084FF))),
                Text(data['text'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black45, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.isSending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                      maxLines: 5, minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'پەیامێک بنووسە...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0084FF), Color(0xFF0063CC)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: isSending
                  ? const Padding(padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared avatar widgets
// ─────────────────────────────────────────────────────────────────────────────
class _GroupAvatar extends StatelessWidget {
  final String avatar;
  final String name;
  final double size;

  const _GroupAvatar({required this.avatar, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    if (avatar.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: CachedNetworkImageProvider(avatar));
    }
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0084FF), Color(0xFF833AB4)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.36),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String avatar;
  final String name;
  final double size;

  const _UserAvatar({required this.avatar, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    if (avatar.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: CachedNetworkImageProvider(avatar));
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF0084FF).withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: const Color(0xFF0084FF), fontWeight: FontWeight.bold, fontSize: size * 0.36),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../view_model/language/language_provider.dart';
import 'user_profile_screen.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getSavedUserId();
    if (mounted) {
      setState(() => _currentUserId = userId);
      if (userId != null) _firestoreService.markAllNotificationsAsRead(userId);
    }
  }

  void _onNotificationTap(NotificationModel n) {
    if (!n.isRead) _firestoreService.markNotificationAsRead(n.id);
    if (n.type == 'follow') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: n.fromUserId)));
    } else if (n.postId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: n.postId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;

    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.isKurdish ? 'ئاگادارکردنەوەکان' : 'Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.isKurdish ? 'ئاگادارکردنەوەکان' : 'Notifications', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('${lang.errorLabel}: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Ionicons.notifications_off_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(lang.noNotifications, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    lang.isKurdish ? 'لایک و کۆمێنتەکانت لێرە دەردەکەون' : 'Your likes and comments will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, i) {
              final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
              final n = NotificationModel.fromJson(data);
              return ListTile(
                onTap: () => _onNotificationTap(n),
                tileColor: n.isRead ? null : Colors.blue[50],
                leading: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: n.fromUserId))),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: n.fromUserAvatar?.isNotEmpty == true ? CachedNetworkImageProvider(n.fromUserAvatar!) : null,
                    child: n.fromUserAvatar?.isEmpty ?? true ? const Icon(Icons.person, size: 24) : null,
                  ),
                ),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(text: n.fromUsername, style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' ${n.getMessage()}'),
                      if (n.commentText?.isNotEmpty == true)
                        TextSpan(text: ': "${n.commentText}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                subtitle: Text(timeago.format(n.createdAt, locale: 'en_short'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                trailing: n.postImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: n.postImageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey[300]),
                          errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20)),
                        ),
                      )
                    : n.type == 'follow'
                        ? const Icon(Ionicons.person_add, color: Colors.blue, size: 24)
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}

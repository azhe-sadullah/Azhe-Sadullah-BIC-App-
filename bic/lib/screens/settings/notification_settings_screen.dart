import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _likesNotifications = true;
  bool _commentsNotifications = true;
  bool _followNotifications = true;
  bool _mentionsNotifications = true;
  bool _messagesNotifications = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showComingSoonDialog());
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ئاگادارکردنەوەکان',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ئەم فیچەرانە لە ڤێرژنی داهاتوودا بەردەست دەبێن',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('باشە', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ئاگادارکردنەوەکان',
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'ئاگادارکردنەوەی کردارەکان',
            children: [
              _buildSwitchTile(
                title: 'لایکەکان',
                subtitle: 'ئاگادارکردنەوە کاتێک کەسێک پۆستەکەت لایک دەکات',
                value: _likesNotifications,
                onChanged: (value) {
                  setState(() {
                    _likesNotifications = value;
                  });
                },
                icon: Icons.favorite_outline,
              ),
              _buildSwitchTile(
                title: 'کۆمێنتەکان',
                subtitle: 'ئاگادارکردنەوە بۆ کۆمێنتی نوێ',
                value: _commentsNotifications,
                onChanged: (value) {
                  setState(() {
                    _commentsNotifications = value;
                  });
                },
                icon: Icons.comment_outlined,
              ),
              _buildSwitchTile(
                title: 'فۆڵۆوەرە نوێیەکان',
                subtitle: 'ئاگادارکردنەوە کاتێک کەسێک فۆڵۆوت دەکات',
                value: _followNotifications,
                onChanged: (value) {
                  setState(() {
                    _followNotifications = value;
                  });
                },
                icon: Icons.person_add_outlined,
              ),
              _buildSwitchTile(
                title: 'Mentions',
                subtitle: 'ئاگادارکردنەوە کاتێک mention ت دەکەن',
                value: _mentionsNotifications,
                onChanged: (value) {
                  setState(() {
                    _mentionsNotifications = value;
                  });
                },
                icon: Icons.alternate_email,
              ),
            ],
          ),
          _buildSection(
            title: 'نامەکان',
            children: [
              _buildSwitchTile(
                title: 'نامەی نوێ',
                subtitle: 'ئاگادارکردنەوە بۆ نامەی نوێ',
                value: _messagesNotifications,
                onChanged: (value) {
                  setState(() {
                    _messagesNotifications = value;
                  });
                },
                icon: Icons.message_outlined,
              ),
            ],
          ),
          _buildSection(
            title: 'شێوازی ئاگادارکردنەوە',
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'وەرگرتنی ئاگادارکردنەوە لە مۆبایل',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
                icon: Icons.notifications_active_outlined,
              ),
              _buildSwitchTile(
                title: 'ئاگادارکردنەوە بە ئیمەیڵ',
                subtitle: 'وەرگرتنی ئاگادارکردنەوە بە ئیمەیڵ',
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                },
                icon: Icons.email_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ئەم ڕێکخستنانە لە ڤێرژنی داهاتوودا بە تەواوی کار دەکەن',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3897F0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3897F0),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.tajawal(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF3897F0).withValues(alpha: 0.5),
        activeThumbColor: const Color(0xFF3897F0),
      ),
    );
  }
}

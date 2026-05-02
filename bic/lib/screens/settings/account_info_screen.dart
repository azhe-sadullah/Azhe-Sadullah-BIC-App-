import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'زانیاریەکانی هەژمار',
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? Center(
                  child: Text(
                    'زانیاری هەژمار بارنەبوو',
                    style: GoogleFonts.tajawal(fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoCard(
                      'ناوی بەکارهێنەر',
                      '@${_currentUser!.username}',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'ناوی تەواو',
                      _currentUser!.fullName ?? 'نەزانراو',
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'ئیمەیڵ',
                      _currentUser!.email ?? 'نەزانراو',
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'ژمارەی پۆستەکان',
                      '${_currentUser!.postsCount}',
                      Icons.grid_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'فۆڵۆوەرەکان',
                      '${_currentUser!.followersCount}',
                      Icons.people_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'فۆڵۆو',
                      '${_currentUser!.followingCount}',
                      Icons.person_add_outlined,
                    ),
                    if (_currentUser!.isVerified) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'دۆخی هەژمار',
                        'Verified ✓',
                        Icons.verified_outlined,
                        valueColor: Colors.blue,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildInfoSection(
                      'دەربارەی',
                      (_currentUser!.bio == null || _currentUser!.bio!.isEmpty)
                          ? 'هیچ بایۆیەک نییە'
                          : _currentUser!.bio!,
                    ),
                    const SizedBox(height: 24),
                    _buildInfoSection(
                      'دروستکراوە لە',
                      _formatDate(_currentUser!.createdAt ?? DateTime.now()),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3897F0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3897F0),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'کانوونی دووەم',
      'شوبات',
      'ئازار',
      'نیسان',
      'ئایار',
      'حوزەیران',
      'تەمووز',
      'ئاب',
      'ئەیلوول',
      'تشرینی یەکەم',
      'تشرینی دووەم',
      'کانوونی یەکەم'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

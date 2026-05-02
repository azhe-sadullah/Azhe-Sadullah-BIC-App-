import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../view_model/language/language_provider.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'create_post_screen.dart';
import 'create_story_screen.dart';
import 'reels_screen.dart';
import 'instagram_profile_screen.dart';
import 'qr_scanner_screen.dart';

class TabScreen extends StatefulWidget {
  const TabScreen({super.key});

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const SizedBox(),
    const ReelsScreen(),
    const InstagramProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      HapticFeedback.lightImpact();
      _showCreateSheet();
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _showCreateSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // IndexedStack and NavBar as static child — not rebuilt every animation frame
    final staticChild = PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex == 2 ? 0 : _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _CustomNavBar(
          isDark: isDark,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _gradientController,
      child: staticChild,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0A0A0A),
                      const Color(0xFF1A1A1A),
                      const Color(0xFF0F0F0F),
                    ]
                  : [
                      const Color(0xFFF5F5F5),
                      const Color(0xFFEEEEEE),
                      const Color(0xFFE0E0E0),
                    ],
              stops: [
                0.0,
                0.5 + (_gradientController.value * 0.2),
                1.0,
              ],
            ),
          ),
          child: child,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Nav Bar
// ─────────────────────────────────────────────────────────────────────────────
class _CustomNavBar extends StatelessWidget {
  final bool isDark;
  final int currentIndex;
  final void Function(int) onTap;

  const _CustomNavBar({
    required this.isDark,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = [
    Ionicons.home,
    Icons.travel_explore,
    Icons.add_rounded,
    Ionicons.play_circle_outline,
    Icons.person_rounded,
  ];

  static const _colors = [
    [Color(0xFF3897F0), Color(0xFF00C6FF)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFFCAF45)],
    [Color(0xFF6C63FF), Color(0xFF3897F0)],
    [Color(0xFFE1306C), Color(0xFF833AB4)],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) {
          final labels = [
            lang.strings.navHome,
            lang.strings.navSearch,
            lang.strings.navCreate,
            lang.strings.navReels,
            lang.strings.navProfile,
          ];

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (i) {
              final selected = currentIndex == i;
              final isCreate = i == 2;
              final colors = _colors[i];

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: isCreate ? 50 : (selected ? 46 : 40),
                        height: isCreate ? 34 : (selected ? 46 : 40),
                        decoration: BoxDecoration(
                          gradient: selected || isCreate
                              ? LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: selected || isCreate
                              ? null
                              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0)),
                          shape: isCreate ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: isCreate ? BorderRadius.circular(14) : null,
                          boxShadow: selected || isCreate
                              ? [
                                  BoxShadow(
                                    color: colors.last.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _icons[i],
                          size: isCreate ? 22 : (selected ? 22 : 20),
                          color: selected || isCreate ? Colors.white : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.cairo(
                          fontSize: selected ? 11 : 10,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? colors.first
                              : (isDark ? Colors.grey[600]! : Colors.grey[500]!),
                        ),
                        child: Text(labels[i]),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CreateSheet extends StatelessWidget {
  final bool isDark;
  const _CreateSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            'چی دروست دەکەی؟',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          // Cards row
          Row(
            children: [
              Expanded(
                child: _CreateCard(
                  isDark: isDark,
                  gradientColors: const [Color(0xFF3897F0), Color(0xFF833AB4)],
                  icon: Ionicons.images_outline,
                  label: 'پۆست',
                  subtitle: 'وێنە یان ڤیدیۆ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const CreatePostScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _CreateCard(
                  isDark: isDark,
                  gradientColors: const [Color(0xFFF56040), Color(0xFFFCAF45)],
                  icon: Ionicons.add_circle_outline,
                  label: 'ستۆری',
                  subtitle: '٢٤ کاتژمێر',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const CreateStoryScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _CreateCard(
                  isDark: isDark,
                  gradientColors: const [Color(0xFF6C63FF), Color(0xFF3897F0)],
                  icon: Ionicons.play_circle_outline,
                  label: 'ڕیل',
                  subtitle: 'بەزووی',
                  comingSoon: true,
                  onTap: null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // QR Scanner row
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF1DE9B6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Ionicons.qr_code_outline, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QR سکانەر',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          )),
                      Text('پرۆفایلی بەکارهێنەر بخوێنەوە',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          )),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single create card
// ─────────────────────────────────────────────────────────────────────────────
class _CreateCard extends StatelessWidget {
  final bool isDark;
  final List<Color> gradientColors;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool comingSoon;
  final VoidCallback? onTap;

  const _CreateCard({
    required this.isDark,
    required this.gradientColors,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.comingSoon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: comingSoon ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient icon circle
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),

              const SizedBox(height: 8),

              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 3),

              comingSoon
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'بەزووی',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

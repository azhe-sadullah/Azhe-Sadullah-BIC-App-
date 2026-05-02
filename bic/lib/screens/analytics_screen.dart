import 'package:bic/models/post_model_firestore.dart';
import 'package:bic/services/firestore_service.dart';
import 'package:bic/utils/app_strings.dart';
import 'package:bic/view_model/language/language_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _Period { week, month, all }

class _AnalyticsData {
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int followersCount;
  final int newFollowers;
  final List<PostModelFirestore> posts;
  final List<PostModelFirestore> topPosts;

  const _AnalyticsData({
    required this.totalViews, required this.totalLikes, required this.totalComments,
    required this.followersCount, required this.newFollowers,
    required this.posts, required this.topPosts,
  });

  int get totalEngagement => totalLikes + totalComments;
  double get engagementRate => followersCount == 0
      ? 0 : (totalEngagement / (followersCount * posts.length.clamp(1, 9999))) * 100;
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _svc = FirestoreService();
  String? _uid;
  _Period _period = _Period.week;
  _AnalyticsData? _data;
  bool _loading = true;
  String? _username;
  String? _avatar;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) {
      _load();
    } else {
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (mounted) {
          _uid = user?.uid;
          _uid != null ? _load() : setState(() => _loading = false);
        }
      });
    }
  }

  DateTime? get _since {
    final now = DateTime.now();
    if (_period == _Period.week) return now.subtract(const Duration(days: 7));
    if (_period == _Period.month) return now.subtract(const Duration(days: 30));
    return null;
  }

  Future<void> _load() async {
    if (_uid == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid!).get();
      final ud = userDoc.data() ?? {};
      _username = ud['username'] ?? '';
      _avatar = ud['avatar'];
      final followersCount = (ud['followersCount'] as num?)?.toInt() ?? 0;

      final results = await Future.wait([
        _svc.getUserPostsForAnalytics(_uid!, since: _since),
        _svc.getNewFollowersCount(_uid!, since: _since),
      ]);

      final rawPosts = results[0] as List<Map<String, dynamic>>;
      final newFollowers = results[1] as int;
      final posts = rawPosts.map((d) => PostModelFirestore.fromJson(d)).toList();

      int views = 0, likes = 0, comments = 0;
      for (final p in posts) {
        views += (rawPosts.firstWhere((r) => r['id'] == p.id)['viewsCount'] as num? ?? 0).toInt();
        likes += p.likesCount;
        comments += p.commentsCount;
      }

      final sorted = [...posts]..sort((a, b) => (b.likesCount + b.commentsCount).compareTo(a.likesCount + a.commentsCount));

      setState(() {
        _data = _AnalyticsData(
          totalViews: views, totalLikes: likes, totalComments: comments,
          followersCount: followersCount, newFollowers: newFollowers,
          posts: posts, topPosts: sorted.take(3).toList(),
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = const _AnalyticsData(totalViews: 0, totalLikes: 0, totalComments: 0,
              followersCount: 0, newFollowers: 0, posts: [], topPosts: []);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (ctx, lp, _) {
      final lang = lp.strings;
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(slivers: [
          _GradientAppBar(lang: lang, username: _username ?? '', avatar: _avatar),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_data == null)
            SliverFillRemaining(child: _EmptyState(lang: lang))
          else
            SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _PeriodTabs(selected: _period, lang: lang, onChanged: (p) { _period = p; _load(); }),
              const SizedBox(height: 20),
              _StatsGrid(data: _data!, lang: lang),
              const SizedBox(height: 14),
              _NewFollowersBanner(data: _data!, lang: lang),
              const SizedBox(height: 24),
              if (_data!.posts.isNotEmpty) _EngagementChart(data: _data!, lang: lang),
              if (_data!.posts.isNotEmpty) const SizedBox(height: 24),
              if (_data!.topPosts.isNotEmpty) _TopPosts(data: _data!, lang: lang),
              if (_data!.topPosts.isNotEmpty) const SizedBox(height: 24),
              const SizedBox(height: 32),
            ])),
        ]),
      );
    });
  }
}

class _GradientAppBar extends StatelessWidget {
  final AppStrings lang;
  final String username;
  final String? avatar;

  const _GradientAppBar({required this.lang, required this.username, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar!) : null,
                  backgroundColor: Colors.white24,
                  child: avatar == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(lang.analyticsSub, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('Pro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ]),
                ),
              ]),
            ]),
          )),
        ),
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
      title: Text(lang.analyticsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: const Color(0xFF1a1a2e),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final _Period selected;
  final AppStrings lang;
  final void Function(_Period) onChanged;

  const _PeriodTabs({required this.selected, required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final periods = [(_Period.week, lang.period7d), (_Period.month, lang.period30d), (_Period.all, lang.periodAll)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: periods.map((item) {
          final active = item.$1 == selected;
          return Expanded(child: GestureDetector(
            onTap: () => onChanged(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF0f3460) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(item.$2, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey)),
            ),
          ));
        }).toList()),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _AnalyticsData data;
  final AppStrings lang;

  const _StatsGrid({required this.data, required this.lang});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.visibility_rounded, const Color(0xFF6C63FF), lang.totalViews, _fmt(data.totalViews)),
      (Icons.favorite_rounded, const Color(0xFFFF6584), lang.totalLikes, _fmt(data.totalLikes)),
      (Icons.comment_rounded, const Color(0xFF43C6AC), lang.totalComments, _fmt(data.totalComments)),
      (Icons.people_rounded, const Color(0xFFFF9F43), lang.totalFollowers, _fmt(data.followersCount)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14,
        childAspectRatio: 1.55, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: cards.map((c) => _StatCard(icon: c.$1, color: c.$2, label: c.$3, value: c.$4)).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ]),
      ]),
    );
  }
}

class _NewFollowersBanner extends StatelessWidget {
  final _AnalyticsData data;
  final AppStrings lang;

  const _NewFollowersBanner({required this.data, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF11998e).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang.newFollowers, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(data.newFollowers.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Icon(Icons.people_rounded, color: Colors.white54, size: 36),
            const SizedBox(height: 2),
            Text('/ ${data.followersCount} ${lang.totalFollowers}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ]),
        ]),
      ),
    );
  }
}

class _EngagementChart extends StatelessWidget {
  final _AnalyticsData data;
  final AppStrings lang;

  const _EngagementChart({required this.data, required this.lang});

  @override
  Widget build(BuildContext context) {
    final chartPosts = data.posts.reversed.take(8).toList();
    if (chartPosts.isEmpty) return const SizedBox.shrink();

    final maxY = chartPosts
        .map((p) => (p.likesCount + p.commentsCount).toDouble())
        .reduce((a, b) => a > b ? a : b)
        .clamp(4.0, double.infinity) * 1.25;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lang.engagementChart, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(lang.engagementChartSub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              maxY: maxY, minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0f3460).withValues(alpha: 0.9),
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    rod.toY.toInt().toString(),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i >= chartPosts.length) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 4),
                        child: Text('P${i + 1}', style: TextStyle(fontSize: 10, color: Colors.grey[500])));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == maxY) {
                      return Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey[400]));
                    }
                    return const SizedBox.shrink();
                  },
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.12), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(chartPosts.length, (i) {
                final p = chartPosts[i];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: (p.likesCount + p.commentsCount).toDouble(),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: LinearGradient(
                      colors: [const Color(0xFF6C63FF).withValues(alpha: 0.7), const Color(0xFF0f3460)],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    ),
                  ),
                ]);
              }),
            )),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(const Color(0xFF6C63FF), lang.totalLikes),
            const SizedBox(width: 16),
            _legend(const Color(0xFF0f3460), lang.totalComments),
          ]),
        ]),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}

class _TopPosts extends StatelessWidget {
  final _AnalyticsData data;
  final AppStrings lang;

  const _TopPosts({required this.data, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(lang.topPosts, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(lang.topPostsSub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 16),
          ...List.generate(data.topPosts.length, (i) {
            final post = data.topPosts[i];
            final engagement = post.likesCount + post.commentsCount;
            final medals = ['🥇', '🥈', '🥉'];
            final imgUrl = post.imageUrl ?? (post.images.isNotEmpty ? post.images[0] : null);
            return Column(children: [
              if (i > 0) const Divider(height: 20),
              Row(children: [
                Text(medals[i], style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imgUrl != null
                      ? CachedNetworkImage(imageUrl: imgUrl, width: 54, height: 54, fit: BoxFit.cover,
                          errorWidget: (ctx, err, st) => _placeholder())
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.caption?.isNotEmpty == true ? post.caption! : '—',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    _chip(Icons.favorite_rounded, '${post.likesCount}', const Color(0xFFFF6584)),
                    const SizedBox(width: 8),
                    _chip(Icons.comment_rounded, '${post.commentsCount}', const Color(0xFF43C6AC)),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0f3460).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text('$engagement', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0f3460))),
                ),
              ]),
            ]);
          }),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(width: 54, height: 54, color: Colors.grey[200], child: const Icon(Icons.image_rounded, color: Colors.grey));

  Widget _chip(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final AppStrings lang;

  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF0f3460).withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.bar_chart_rounded, size: 56, color: Color(0xFF0f3460)),
      ),
      const SizedBox(height: 16),
      Text(lang.analyticsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(lang.analyticsEmpty, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
    ]));
  }
}

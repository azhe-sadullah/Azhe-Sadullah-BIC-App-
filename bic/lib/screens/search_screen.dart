import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../view_model/language/language_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';
import 'instagram_profile_screen.dart';
import 'post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _mapController = MapController();
  final _firestoreService = FirestoreService();

  LatLng _currentLocation = const LatLng(36.1911, 44.0093);
  bool _isLoadingGPS = false;
  bool _isSearching = false;
  bool _isLoading = false;
  List<UserModel> _searchResults = [];
  String? _currentUserId;
  List<Marker> _postMarkers = [];
  List<Marker> _userMarkers = [];
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  StreamSubscription<QuerySnapshot>? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _usersSubscription?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _currentUserId = await AuthService().getSavedUserId();
    _postsSubscription = _firestoreService.postsCollection
        .where('latitude', isNull: false)
        .limit(100)
        .snapshots()
        .listen(_buildPostMarkers, onError: (_) {});
    _usersSubscription = _firestoreService.usersCollection
        .where('latitude', isNull: false)
        .limit(50)
        .snapshots()
        .listen(_buildUserMarkers, onError: (_) {});
    if (!kIsWeb) _fetchGPS();
  }

  void _buildPostMarkers(QuerySnapshot snap) {
    final markers = snap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d['latitude'] != null && d['longitude'] != null;
    }).map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return Marker(
        point: LatLng((d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()),
        width: 40, height: 40,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: doc.id))),
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue, border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.photo, color: Colors.white, size: 20),
          ),
        ),
      );
    }).toList();
    if (mounted) setState(() => _postMarkers = markers);
  }

  void _buildUserMarkers(QuerySnapshot snap) {
    final markers = snap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d['latitude'] != null && d['longitude'] != null && d['id'] != _currentUserId;
    }).map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final avatarUrl = d['avatar'] as String?;
      return Marker(
        point: LatLng((d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()),
        width: 44, height: 44,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: doc.id))),
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 3), color: Colors.white),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => const Icon(Icons.person, color: Colors.green))
                  : const Icon(Icons.person, color: Colors.green),
            ),
          ),
        ),
      );
    }).toList();
    if (mounted) setState(() => _userMarkers = markers);
  }

  Future<void> _fetchGPS() async {
    setState(() => _isLoadingGPS = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_currentLocation, 13);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() { _isLoading = true; _isSearching = true; });
    try {
      final q = query.trim().toLowerCase();
      final snap = await FirebaseFirestore.instance.collection('users').limit(50).get();
      final results = snap.docs.where((doc) {
        final d = doc.data()..['id'] = doc.id;
        final user = UserModel.fromJson(d);
        return user.username.toLowerCase().contains(q) || (user.fullName ?? '').toLowerCase().contains(q);
      }).map((doc) {
        final d = doc.data()..['id'] = doc.id;
        return UserModel.fromJson(d);
      }).toList();
      if (mounted) setState(() { _searchResults = results; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _flyToUser(UserModel user) {
    if (user.latitude != null && user.longitude != null) {
      _mapController.move(LatLng(user.latitude!, user.longitude!), 15);
    }
    _searchFocus.unfocus();
    setState(() { _isSearching = false; _searchController.clear(); _searchResults = []; });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 12,
              onTap: (_, __) { if (_isSearching) setState(() => _isSearching = false); },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.bic'),
              MarkerLayer(markers: _userMarkers),
              MarkerLayer(markers: _postMarkers),
              MarkerLayer(markers: [
                Marker(
                  point: _currentLocation, width: 20, height: 20,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue, border: Border.all(color: Colors.white, width: 3)),
                  ),
                ),
              ]),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12, right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _performSearch,
                    decoration: InputDecoration(
                      hintText: lang.searchHint,
                      prefixIcon: const Icon(Ionicons.search, size: 20),
                      suffixIcon: _isSearching
                          ? IconButton(
                              onPressed: () { _searchController.clear(); _searchFocus.unfocus(); setState(() { _isSearching = false; _searchResults = []; }); },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(height: 6),
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _isLoading
                          ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                          : _searchResults.isEmpty
                              ? Padding(padding: const EdgeInsets.all(24), child: Text(lang.noResults, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (_, i) {
                                    final user = _searchResults[i];
                                    final hasLocation = user.latitude != null && user.longitude != null;
                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        backgroundImage: user.avatar?.isNotEmpty == true ? CachedNetworkImageProvider(user.avatar!) : null,
                                        child: user.avatar?.isEmpty ?? true ? const Icon(Icons.person) : null,
                                      ),
                                      title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: hasLocation ? const Text('Has location', style: TextStyle(color: Colors.blue, fontSize: 12)) : null,
                                      trailing: hasLocation ? const Icon(Icons.navigation, color: Colors.blue) : null,
                                      onTap: () {
                                        if (hasLocation) {
                                          _flyToUser(user);
                                        } else {
                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => user.id == _currentUserId ? const InstagramProfileScreen() : UserProfileScreen(userId: user.id),
                                          ));
                                        }
                                      },
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            bottom: 100, right: 16,
            child: FloatingActionButton.small(
              heroTag: 'gps',
              onPressed: _isLoadingGPS ? null : _fetchGPS,
              backgroundColor: Colors.white,
              child: _isLoadingGPS
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  LatLng _currentLocation = const LatLng(36.1911, 44.0093); // Erbil default
  bool _isLoadingGPS = false;
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
    super.dispose();
  }

  Future<void> _init() async {
    _currentUserId = await _authService.getSavedUserId();
    _subscribeToStreams();
    if (!kIsWeb) _fetchGPS();
  }

  void _subscribeToStreams() {
    _postsSubscription = _firestoreService.postsCollection
        .limit(100)
        .snapshots()
        .listen(_onPostsUpdated, onError: (_) {});

    _usersSubscription = _firestoreService.usersCollection
        .limit(50)
        .snapshots()
        .listen(_onUsersUpdated, onError: (_) {});
  }

  void _onPostsUpdated(QuerySnapshot snap) {
    final markers = <Marker>[];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final postId = doc.id;
      final imageUrl = data['imageUrl'] as String?;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: postId),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3897F0), width: 3),
                color: Colors.white,
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) => const Icon(
                          Icons.photo,
                          color: Color(0xFF3897F0),
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.photo,
                        color: Color(0xFF3897F0),
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      );
    }
    if (mounted) setState(() => _postMarkers = markers);
  }

  void _onUsersUpdated(QuerySnapshot snap) {
    final markers = <Marker>[];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      if (data['id'] == _currentUserId) continue;

      final userId = doc.id;
      final avatar = data['avatar'] as String?;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: userId),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
                color: Colors.white,
              ),
              child: ClipOval(
                child: avatar != null && avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) =>
                            const Icon(Icons.person, color: Colors.green, size: 24),
                      )
                    : const Icon(Icons.person, color: Colors.green, size: 24),
              ),
            ),
          ),
        ),
      );
    }
    if (mounted) setState(() => _userMarkers = markers);
  }

  Future<void> _fetchGPS() async {
    if (!mounted) return;
    setState(() => _isLoadingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingGPS = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingGPS = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingGPS = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _isLoadingGPS = false;
      });
      _mapController.move(_currentLocation, 13);
    } catch (e) {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bic',
              ),
              // User pins (green)
              MarkerLayer(markers: _userMarkers),
              // Post pins (blue)
              MarkerLayer(markers: _postMarkers),
              // My location (blue dot)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3897F0),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3897F0).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Legend
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(const Color(0xFF3897F0)),
                  const SizedBox(width: 4),
                  const Text('پۆستەکان', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 10),
                  _legendDot(Colors.green),
                  const SizedBox(width: 4),
                  const Text('بەکارهێنەران', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 10),
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3897F0)),
                  ),
                  const SizedBox(width: 4),
                  const Text('تۆ', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),

          // GPS button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'map_gps',
              onPressed: _isLoadingGPS ? null : _fetchGPS,
              backgroundColor: Colors.white,
              child: _isLoadingGPS
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location,
                      color: Color(0xFF3897F0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

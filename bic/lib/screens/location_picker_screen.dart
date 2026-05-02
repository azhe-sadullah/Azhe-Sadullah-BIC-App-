import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String locationName;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedPoint = const LatLng(36.1911, 44.0093); // Erbil default
  String _locationName = 'هەولێر، کوردستان';
  bool _isLoadingAddress = false;
  bool _isLoadingGPS = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) return; // GPS not reliable on web
    setState(() => _isLoadingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingGPS = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingGPS = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingGPS = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
        _isLoadingGPS = false;
      });
      _mapController.move(point, 14);
      _reverseGeocode(point);
    } catch (e) {
      setState(() => _isLoadingGPS = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isLoadingAddress = true);
    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
        },
        options: Options(
          headers: {'User-Agent': 'BIC-App/1.0'},
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['display_name'] as String? ?? '';
        // Shorten to city level
        final parts = address.split(',');
        final short = parts.take(3).join(',').trim();
        setState(() => _locationName = short.isNotEmpty ? short : address);
      }
    } catch (e) {
      // Keep previous name
    }
    setState(() => _isLoadingAddress = false);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
    _reverseGeocode(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شوێن هەڵبژێرە',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, LocationResult(
              latitude: _selectedPoint.latitude,
              longitude: _selectedPoint.longitude,
              locationName: _locationName,
            )),
            child: const Text('دڵنیابوونەوە',
                style: TextStyle(color: Color(0xFF3897F0), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 12,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bic',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFE53935),
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF3897F0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoadingAddress
                            ? const LinearProgressIndicator()
                            : Text(
                                _locationName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('کلیک لەسەر نەخشەکە بکە بۆ گۆڕینی شوێنەکە',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),

          // GPS button
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _isLoadingGPS ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              child: _isLoadingGPS
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF3897F0)),
            ),
          ),
        ],
      ),
    );
  }
}

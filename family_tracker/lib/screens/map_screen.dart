import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';

class MapScreen extends StatefulWidget {
  final String groupId;
  const MapScreen({super.key, required this.groupId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  bool _firstLocationUpdate = true;

  void _updateCamera(List<UserModel> members) {
    if (_controller == null || members.isEmpty) return;

    List<LatLng> points = members
        .where((m) => m.latitude != null)
        .map((m) => LatLng(m.latitude!, m.longitude!))
        .toList();

    if (points.isEmpty) return;

    if (_firstLocationUpdate) {
      _firstLocationUpdate = false;
      if (points.length == 1) {
        _controller!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      } else {
        LatLngBounds bounds = _getBounds(points);
        _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa da Família'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: dbService.getFamilyMembersStream(widget.groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final members = snapshot.data!;
          _updateCamera(members);

          Set<Marker> markers = members.where((u) => u.latitude != null).map((u) {
            return Marker(
              markerId: MarkerId(u.uid),
              position: LatLng(u.latitude!, u.longitude!),
              infoWindow: InfoWindow(
                title: u.displayName,
                snippet: u.lastSeen != null ? 'Visto por último: ${u.lastSeen!.hour}:${u.lastSeen!.minute}' : null,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 2),
            markers: markers,
            onMapCreated: (controller) => _controller = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}

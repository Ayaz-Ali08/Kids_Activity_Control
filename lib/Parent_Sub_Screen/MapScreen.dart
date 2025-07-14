import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A screen that displays a list of historical user locations on a Google Map.
/// Each location is shown as a marker with a timestamp.
class MapScreen extends StatelessWidget {
  /// A list of location history maps containing latitude, longitude, and timestamp.
  final List<Map<String, dynamic>> locationHistory;

  const MapScreen({super.key, required this.locationHistory});

  @override
  Widget build(BuildContext context) {
    // Convert location history into a set of Google Map markers
    Set<Marker> markers = locationHistory.map((location) {
      // Use timestamp as a unique marker ID
      String markerId = location['timestamp'].toString();
      return Marker(
        markerId: MarkerId(markerId),
        position: LatLng(location['latitude'], location['longitude']),
        infoWindow: InfoWindow(title: 'Recorded at $markerId'),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        centerTitle: true,
      ),
      body: GoogleMap(
        // Set initial camera position to the first recorded location, or a default fallback
        initialCameraPosition: CameraPosition(
          target: locationHistory.isNotEmpty
              ? LatLng(locationHistory[0]['latitude'], locationHistory[0]['longitude'])
              : const LatLng(0, 0), // Default fallback
          zoom: 14.0,
        ),
        markers: markers,
        myLocationEnabled: true,         // Show user's current location
        myLocationButtonEnabled: true,   // Enable the location button
      ),
    );
  }
}

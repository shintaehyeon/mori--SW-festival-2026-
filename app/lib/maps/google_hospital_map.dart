import '../localization.dart';
import '../hospital_name.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'loader_stub.dart' if (dart.library.js_interop) 'loader_web.dart';

const googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

class GoogleHospitalMap extends StatefulWidget {
  final List<Map<String, dynamic>> hospitals;
  final gm.LatLng center;
  final gm.LatLng? location;
  final bool ko;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onExternal;
  const GoogleHospitalMap({
    super.key,
    required this.hospitals,
    required this.center,
    required this.location,
    required this.ko,
    required this.selected,
    required this.onSelect,
    required this.onExternal,
  });
  @override
  State<GoogleHospitalMap> createState() => _GoogleHospitalMapState();
}

class _GoogleHospitalMapState extends State<GoogleHospitalMap> {
  late final Future<void> ready = googleMapsKey.isEmpty
      ? Future.value()
      : loadGoogleMaps(googleMapsKey);
  Widget fallback() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 36),
          Text(
            tr(
              'Open Google Maps for now. The in-app map connection is being prepared.',
              'Google 지도는 외부 앱에서 이용할 수 있어요. 앱 안 지도는 연결 준비 중입니다.',
            ),
          ),
          TextButton.icon(
            onPressed: widget.onExternal,
            icon: const Icon(Icons.open_in_new),
            label: Text(tr('Open Google Maps', 'Google 지도 열기')),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (googleMapsKey.isEmpty) return fallback();
    return FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) return fallback();
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return SizedBox(
          height: 300,
          child: gm.GoogleMap(
            initialCameraPosition: gm.CameraPosition(
              target: widget.center,
              zoom: widget.location == null ? 11 : 13,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            markers: {
              if (widget.location != null)
                gm.Marker(
                  markerId: const gm.MarkerId('my-location'),
                  position: widget.location!,
                  icon: gm.BitmapDescriptor.defaultMarkerWithHue(
                    gm.BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: gm.InfoWindow(title: tr('My location', '내 위치')),
                ),
              for (final h in widget.hospitals)
                gm.Marker(
                  markerId: gm.MarkerId(h['id'] as String),
                  position: gm.LatLng(
                    double.parse('${h['latitude']}'),
                    double.parse('${h['longitude']}'),
                  ),
                  icon: gm.BitmapDescriptor.defaultMarkerWithHue(
                    widget.selected == h['id']
                        ? gm.BitmapDescriptor.hueOrange
                        : gm.BitmapDescriptor.hueRed,
                  ),
                  infoWindow: gm.InfoWindow(
                    title: h['name'] as String,
                    snippet:
                        '${romanizedHospitalName(h['name'] as String)} · ${h['address']}',
                  ),
                  onTap: () => widget.onSelect(h['id'] as String),
                ),
            },
          ),
        );
      },
    );
  }
}

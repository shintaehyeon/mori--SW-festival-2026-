import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:carebridge/hospitals.dart';

void main() {
  test('distance ordering and invalid coordinates', () {
    const origin = LatLng(36, 129);
    final near = {
      'id': 'near',
      'name': 'N',
      'latitude': '36.001',
      'longitude': '129',
    };
    final far = {
      'id': 'far',
      'name': 'F',
      'latitude': '37',
      'longitude': '129',
    };
    final missing = {
      'id': 'missing',
      'name': 'M',
      'latitude': null,
      'longitude': null,
    };
    expect(hospitalDistance(origin, near), closeTo(111, 3));
    expect(nearbyHospitals([missing, far, near], origin).map((h) => h['id']), [
      'near',
      'far',
      'missing',
    ]);
    expect(hospitalPoint({'latitude': 'NaN', 'longitude': '129'}), isNull);
    expect(nearbyHospitals([far, near], null).first['id'], 'far');
  });
}

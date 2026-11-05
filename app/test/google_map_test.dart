import 'package:carebridge/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:carebridge/maps/google_hospital_map.dart';

void main() {
  setUp(() => MoriLanguage.current.value = 'ko');
  tearDown(() => MoriLanguage.current.value = 'en');
  testWidgets(
    'missing key keeps Google Maps link usable without creating a native map',
    (tester) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleHospitalMap(
              hospitals: const [],
              center: const gm.LatLng(36.019, 129.343),
              location: null,
              ko: true,
              selected: null,
              onSelect: (_) {},
              onExternal: () => opened = true,
            ),
          ),
        ),
      );
      expect(find.byType(gm.GoogleMap), findsNothing);
      await tester.tap(find.text('Google 지도 열기'));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

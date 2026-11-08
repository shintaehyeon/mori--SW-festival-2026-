import 'dart:convert';
import 'dart:io';
import 'package:carebridge/api.dart';
import 'package:carebridge/hospitals.dart';
import 'package:carebridge/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class DeniedLocation extends GeolocatorPlatform {
  int positionReads = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionReads++;
    throw StateError('Must not read after denial');
  }
}

class DirectoryApi extends Api {
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final source = jsonDecode(
      File('../server/resources/hospitals.json').readAsStringSync(),
    );
    source['hospitals'] = (source['hospitals'] as List)
        .where((h) => h['name'] == '강이비인후과의원')
        .toList();
    return source;
  }
}

void main() {
  testWidgets('location denial preserves search without reading coordinates', (
    tester,
  ) async {
    final previous = GeolocatorPlatform.instance;
    final denied = DeniedLocation();
    GeolocatorPlatform.instance = denied;
    addTearDown(() => GeolocatorPlatform.instance = previous);
    MoriLanguage.current.value = 'en';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Hospitals(api: DirectoryApi(), ko: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '강이비인후과');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final location = find.text('Use / refresh my location');
    await tester.ensureVisible(location);
    await tester.tap(location);
    await tester.pumpAndSettle();
    expect(find.textContaining('Location unavailable.'), findsOneWidget);
    expect(find.textContaining('강이비인후과의원'), findsWidgets);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '강이비인후과',
    );
    expect(denied.positionReads, 0);
    expect(tester.takeException(), isNull);
  });
}

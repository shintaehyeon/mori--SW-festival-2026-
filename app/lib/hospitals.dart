import 'clinic_reviews.dart';
import 'localization.dart';
import 'hospital_name.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'body_categories.dart';
import 'facility_categories.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'maps/google_hospital_map.dart';
import 'package:latlong2/latlong.dart';

LatLng? hospitalPoint(Map h) {
  final lat = double.tryParse('${h['latitude']}');
  final lon = double.tryParse('${h['longitude']}');
  if (lat == null ||
      lon == null ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 90 ||
      lon.abs() > 180 ||
      (lat == 0 && lon == 0)) {
    return null;
  }
  return LatLng(lat, lon);
}

double hospitalDistance(LatLng origin, Map h) {
  final point = hospitalPoint(h);
  return point == null
      ? double.infinity
      : const Distance().as(LengthUnit.Meter, origin, point);
}

List<Map<String, dynamic>> nearbyHospitals(List hospitals, LatLng? origin) {
  final result = hospitals
      .map((h) => Map<String, dynamic>.from(h as Map))
      .toList();
  if (origin != null) {
    result.sort((a, b) {
      final distance = hospitalDistance(
        origin,
        a,
      ).compareTo(hospitalDistance(origin, b));
      return distance == 0
          ? '${a['name']}'.compareTo('${b['name']}')
          : distance;
    });
  }
  return result;
}

class Hospitals extends StatefulWidget {
  final Api api;
  final bool ko;
  final bool canReadExperiences;
  final VoidCallback? onSignIn;
  final ValueChanged<Map<String, dynamic>>? onPrepare;
  const Hospitals({
    super.key,
    required this.api,
    required this.ko,
    this.onPrepare,
    this.canReadExperiences = true,
    this.onSignIn,
  });
  @override
  State<Hospitals> createState() => _HospitalsState();
}

class _HospitalsState extends State<Hospitals> {
  final query = TextEditingController();
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  BodyCategory? bodyCategory;
  String facilityCategory = 'medical';
  final resultsKey = GlobalKey();
  LatLng? location;
  double? accuracy;
  DateTime? locatedAt;
  bool locating = false, showMap = false;
  int locationRequest = 0;
  String? locationMessage;
  String? selectedHospital;

  List<Map<String, dynamic>> get sorted => nearbyHospitals(
    (data?['hospitals'] as List? ?? [])
        .where(
          (h) =>
              facilityMatches(h as Map, facilityCategory) &&
              matchesBodyCategory(h, bodyCategory) &&
              hospitalMatchesQuery(h, query.text),
        )
        .toList(),
    location,
  );
  String distanceLabel(Map h) {
    if (location == null) return '';
    final meters = hospitalDistance(location!, h);
    if (!meters.isFinite) return t('Distance unavailable', '거리 정보 없음');
    return meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String departmentSummary(Map h) {
    if (isPharmacy(h)) {
      return t(
        'Pharmacy type: unverified in the source data',
        '공식 원본에 양약국·한약국 구분 항목이 없습니다.',
      );
    }
    final departments = (h['departments'] as List)
        .where(
          (d) =>
              bodyCategory == null ||
              bodyCategory!.departments.contains(d['name']),
        )
        .toList();
    if (departments.isEmpty) {
      return t('Department data unavailable', '진료과 정보 없음');
    }
    return '${t('Registered care', '신고 진료과')}: ${departments.take(3).map((d) => '${bilingualSpecialty(d['name'])} (${d['specialists']} ${t('specialists', '전문의')})').join(' / ')}';
  }

  String specialistSummary(Map h) {
    if (isPharmacy(h)) return '';
    final specialists = (h['departments'] as List)
        .where((d) => (d['specialists'] as num? ?? 0) > 0)
        .toList();
    if (specialists.isEmpty) {
      return t(
        'Specialists: none reported in this snapshot',
        '전문의: 이 자료에 신고된 전문의 없음',
      );
    }
    return '${t('Reported specialists', '신고 전문의')}: ${specialists.take(3).map((d) => '${bilingualSpecialty(d['name'])} ${d['specialists']}').join(' / ')}${specialists.length > 3 ? t(' · expand for more', ' · 펼쳐서 더 보기') : ''}';
  }

  Future<void> locate() async {
    final request = ++locationRequest;
    setState(() {
      locating = true;
      locationMessage = null;
      location = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('service');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('permission');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted || request != locationRequest) return;
      setState(() {
        location = LatLng(position.latitude, position.longitude);
        accuracy = position.accuracy;
        locatedAt = DateTime.now();
        locationMessage = t(
          'Sorted by straight-line distance. Pohang institutions only.',
          '직선거리 가까운 순입니다. 현재 데이터는 포항 의료기관만 포함합니다.',
        );
      });
    } catch (_) {
      if (mounted && request == locationRequest) {
        setState(() {
          locationMessage = t(
            'Location unavailable. Check permission and location services, or continue searching without it.',
            '위치를 가져오지 못했어요. 위치 권한과 위치 서비스를 확인하거나 위치 없이 검색하세요.',
          );
        });
      }
    } finally {
      if (mounted && request == locationRequest) {
        setState(() => locating = false);
      }
    }
  }

  Widget hospitalMap() {
    final points = sorted
        .where((h) => hospitalPoint(h) != null)
        .take(50)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleHospitalMap(
          key: ValueKey(
            '${location?.latitude}:${location?.longitude}:${query.text}:${bodyCategory?.id}:$facilityCategory',
          ),
          hospitals: points,
          center: gm.LatLng(
            (location ??
                    (points.isEmpty
                        ? const LatLng(36.019, 129.343)
                        : hospitalPoint(points.first)!))
                .latitude,
            (location ??
                    (points.isEmpty
                        ? const LatLng(36.019, 129.343)
                        : hospitalPoint(points.first)!))
                .longitude,
          ),
          location: location == null
              ? null
              : gm.LatLng(location!.latitude, location!.longitude),
          ko: widget.ko,
          selected: selectedHospital,
          onSelect: (id) => setState(() => selectedHospital = id),
          onExternal: () => open(
            Uri.https('www.google.com', '/maps/search/', {
              'api': '1',
              'query':
                  '포항 ${query.text.trim().isEmpty ? '병원' : query.text.trim()}',
            }),
          ),
        ),
        Text(
          t(
            'Map: up to 50 matching institutions. Zoom out if hospitals are outside the view.',
            '지도에는 검색 결과 중 최대 50곳을 표시합니다. 병원이 안 보이면 지도를 축소하세요.',
          ),
        ),
        if (selectedHospital != null) ...[
          for (final h in points.where((h) => h['id'] == selectedHospital))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h['name']} · ${distanceLabel(h)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(h['address']),
                    if (widget.onPrepare != null && !isPharmacy(h))
                      FilledButton.icon(
                        onPressed: () => widget.onPrepare!(h),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(
                          t('Prepare for this visit', '이 병원 방문 준비하기'),
                        ),
                      ),
                    TextButton(
                      onPressed: () => open(
                        Uri.https('www.google.com', '/maps/dir/', {
                          'api': '1',
                          'destination':
                              '${hospitalPoint(h)!.latitude},${hospitalPoint(h)!.longitude}',
                        }),
                      ),
                      child: Text(t('Directions in Maps', '지도 앱에서 길찾기')),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  String t(String en, String ko) => tr(en, ko);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    locationRequest++;
    query.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final r = await widget.api.request(
        '/api/hospitals?limit=all&kind=${facilityCategory.endsWith('Pharmacy') ? 'pharmacy' : 'hospital'}',
      );
      if (mounted) {
        setState(() {
          data = Map<String, dynamic>.from(r);
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> showResults() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || resultsKey.currentContext == null) return;
    await Scrollable.ensureVisible(
      resultsKey.currentContext!,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      alignment: 0.05,
    );
  }

  Future<void> searchAndShowResults() async {
    await load();
    if (!mounted || error != null) return;
    await showResults();
  }

  Future<void> open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Unable to open on this device.', '이 기기에서 열 수 없어요.')),
        ),
      );
    }
  }

  Widget experienceExample() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F5ED),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('FORMAT EXAMPLE · Not an actual review', '작성 형식 예시 · 실제 후기가 아닙니다'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(
          t(
            'Reception: What did you need to bring?\nCommunication: How did you explain your symptoms?\nNext student: What would you prepare differently?',
            '접수: 무엇을 준비해 갔나요?\n의사소통: 증상을 어떻게 설명했나요?\n다음 유학생에게: 미리 알았으면 좋았을 점은?',
          ),
        ),
      ],
    ),
  );

  Future<void> reviews(String hospital) async {
    if (!widget.canReadExperiences) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t('Visit experiences', '병원 방문 경험')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(
                    'Sign in to read and share community experiences. Prepare your visit as a guest without signing in.',
                    '방문 경험 열람·작성은 로그인 후 이용합니다. 방문 준비표는 게스트로도 만들 수 있어요.',
                  ),
                ),
                const SizedBox(height: 16),
                experienceExample(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Close', '닫기')),
            ),
            if (widget.onSignIn != null)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  widget.onSignIn!();
                },
                child: Text(t('Sign in', '로그인')),
              ),
          ],
        ),
      );
      return;
    }
    try {
      final results = await widget.api.request(
        '/api/posts?q=${Uri.encodeComponent(hospital)}',
      );
      final posts = (results as List)
          .where((p) => p['place'] == hospital)
          .toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('Mori community experiences', '모리 이용자 방문 경험')),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HospitalName(hospital),
                  Text(
                    t(
                      'Self-reported experiences, not verified visits or nationality. Match uses the exact institution name. Write an experience in Community using this name.',
                      '자가 작성 경험이며 방문·국적을 인증하지 않았습니다. 병원명이 정확히 일치하는 글만 표시합니다. 커뮤니티에서 이 병원명으로 경험을 남길 수 있어요.',
                    ),
                  ),
                  if (posts.isEmpty)
                    Text(
                      t(
                        'No experiences yet. Share your experience after visiting.',
                        '아직 등록된 경험이 없어요. 진료를 다녀온 뒤 경험을 남겨주세요.',
                      ),
                    ),
                  if (posts.isEmpty) experienceExample(),
                  for (final p in posts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${tr(p['language'])} · ${p['visitDate']}'),
                          Text(p['body']),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Close', '닫기')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        t('Find care in Pohang', '포항 의료기관 찾기'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        t(
          'Official HIRA snapshot · 2026-09-30. Not live availability. Confirm by phone before visiting.',
          '심평원 공식자료 · 2026-09-30 기준. 실시간 진료 가능 정보가 아니에요. 방문 전 전화로 확인하세요.',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: query,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => searchAndShowResults(),
        decoration: InputDecoration(
          labelText: t('Hospital / department / area', '병원명 · 진료과 · 동네 검색'),
          hintText: '양덕이비인후과 / 양덕 / dentist',
          suffixIcon: IconButton(
            onPressed: busy ? null : searchAndShowResults,
            tooltip: t('Search', '검색'),
            icon: const Icon(Icons.search),
          ),
        ),
      ),
      if (busy) const LinearProgressIndicator(),
      if (error != null) ...[
        Text(error!, style: const TextStyle(color: Colors.red)),
        OutlinedButton.icon(
          onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh),
          label: Text(tr('Retry')),
        ),
      ],
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: busy || data == null || error != null ? null : showResults,
        icon: const Icon(Icons.format_list_bulleted),
        label: Text(t('View clinic list', '병원 목록 보기')),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final category in [
            ['medical', t('Medical / dental', '일반 병원·의원')],
            ['traditional', t('Korean medicine', '한의원·한방병원')],
            ['westernPharmacy', t('Western pharmacy', '양약국')],
            ['herbalPharmacy', t('Herbal pharmacy', '한약국')],
            ['unknownPharmacy', t('Pharmacy · unverified', '약국·유형 미확인')],
          ])
            ChoiceChip(
              label: Text(category[1]),
              selected: facilityCategory == category[0],
              onSelected: busy
                  ? null
                  : (_) {
                      setState(() {
                        facilityCategory = category[0];
                        bodyCategory = null;
                        selectedHospital = null;
                        data = null;
                        query.clear();
                      });
                      load();
                    },
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (facilityCategory == 'traditional')
        Text(
          t(
            'Traditional Korean medicine · shown separately from medical and dental care.',
            '한국 전통의학 의료기관입니다. 일반 병원·의원과 별도로 표시합니다.',
          ),
        ),
      if (facilityCategory.endsWith('Pharmacy'))
        Text(
          t(
            'The source lists pharmacies without a Western/herbal distinction. Unverified records are kept in the separate unverified category; names are not used to guess.',
            '원본은 약국을 양약국·한약국으로 구분하지 않습니다. 확인 전에는 유형 미확인 탭에 표시하며 상호로 추정하지 않습니다.',
          ),
        ),
      if (facilityCategory == 'medical')
        BodyCategoryPicker(
          selected: bodyCategory?.id,
          ko: widget.ko,
          onSelect: (category) async {
            setState(() {
              bodyCategory = category;
              selectedHospital = null;
              query.clear();
            });
            if (data == null) await load();
            if (!mounted || category == null) return;
            await showResults();
          },
        ),
      if (bodyCategory != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            bodyCategory!.departments.map(bilingualSpecialty).join(' / '),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      const SizedBox(height: 16),
      Text(
        t('Find nearby care', '내 주변 병원 찾기'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        t(
          'One-time location, kept on this device. No MORI server or AI sharing.',
          '위치는 한 번만 읽고 기기 안에서 사용합니다. 서버·AI 전송 없음.',
        ),
      ),
      Wrap(
        spacing: 8,
        children: [
          FilledButton.icon(
            onPressed: locating ? null : locate,
            icon: const Icon(Icons.my_location),
            label: Text(
              locating
                  ? t('Finding location…', '위치 확인 중…')
                  : t('Use / refresh my location', '현재 위치로 가까운 순 보기'),
            ),
          ),
          if (location != null || locating)
            TextButton(
              onPressed: () => setState(() {
                locationRequest++;
                locating = false;
                location = null;
                accuracy = null;
                locatedAt = null;
                locationMessage = null;
                showMap = false;
              }),
              child: Text(t('Clear location', '위치 사용 중단')),
            ),
        ],
      ),
      if (locationMessage != null) Text(locationMessage!),
      if (location != null)
        Text(
          '${t('Location accuracy', '위치 정확도')} ±${accuracy?.round()} m · ${t('Checked', '확인 시각')} ${locatedAt?.toLocal().toString().substring(0, 16)}',
        ),
      Text(
        t(
          'Straight-line distance · confirm opening hours before visiting.',
          '직선거리 기준 · 방문 전 진료 여부를 확인하세요.',
        ),
      ),
      Text(
        t(
          'Map: Google Maps. Opening shares the displayed area and IP with Google.',
          '지도: Google Maps · 열면 표시 지역·IP가 Google에 전달됩니다.',
        ),
      ),
      FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFDBEAFE),
          foregroundColor: const Color(0xFF173B65),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: () => setState(() => showMap = !showMap),
        icon: const Icon(Icons.map_outlined),
        label: Text(
          showMap ? t('Hide map', '지도 닫기') : t('Show hospital map', '병원 지도 보기'),
        ),
      ),
      if (showMap && data != null) hospitalMap(),
      const SizedBox(height: 12),
      if (facilityCategory == 'medical') ...[
        Text(
          t('Choose a department to explore', '찾아볼 진료과 선택'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          t(
            'Department names are a navigation aid, not a diagnosis or an assessment of urgency. Ask the clinic if you are unsure.',
            '진료과 이름을 이해하고 검색하는 안내입니다. 진단·응급도 판정이 아니며, 확실하지 않으면 의료기관에 문의하세요.',
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final department in departmentGuide)
              ActionChip(
                label: Text(bilingualSpecialty(department['ko']!)),
                onPressed: busy
                    ? null
                    : () async {
                        setState(() {
                          query.clear();
                          bodyCategory = department['ko'] == '치과'
                              ? bodyCategories.firstWhere(
                                  (c) => c.id == 'teeth',
                                )
                              : BodyCategory(
                                  'department',
                                  department['en']!,
                                  department['ko']!,
                                  [department['ko']!],
                                );
                        });
                        if (data == null) await load();
                        if (mounted) await showResults();
                      },
              ),
          ],
        ),
        Text(
          t(
            'Change the app language using the menu at the top.',
            '상단 언어 메뉴에서 앱 언어를 바꿀 수 있어요.',
          ),
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
      ],
      if (data != null) ...[
        Container(
          key: resultsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bodyCategory != null)
                Text(
                  '${tr(bodyCategory!.en, bodyCategory!.ko)} · ${bodyCategory!.departments.map(bilingualSpecialty).join(' / ')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (bodyCategory != null)
                Text(
                  tr(
                    'Only institutions with registered specialists in the selected departments are shown. Confirm availability before visiting.',
                  ),
                ),
              if (bodyCategory != null)
                TextButton(
                  onPressed: () {
                    setState(() => bodyCategory = null);
                  },
                  child: Text(t('Show all departments', '전체 진료과 보기')),
                ),
              Text(
                '${sorted.length} ${t('results · nearest first when location is set', '곳 · 위치 설정 시 가까운 순')}',
              ),
            ],
          ),
        ),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              facilityCategory.endsWith('Pharmacy') &&
                      facilityCategory != 'unknownPharmacy'
                  ? t(
                      'No verified classifications available yet. See Pharmacy · unverified for source records.',
                      '이 유형으로 확인된 자료가 아직 없습니다. 약국·유형 미확인 탭에서 원본 약국 목록을 볼 수 있습니다.',
                    )
                  : t('No matching institutions.', '검색 결과가 없습니다.'),
            ),
          ),
        for (final h in sorted)
          Card(
            margin: const EdgeInsets.only(bottom: 18),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFDCE6DF)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(facilityLabel(h, widget.ko)),
                        backgroundColor: const Color(0xFFEDF3EC),
                        side: BorderSide.none,
                      ),
                      if (location != null)
                        Chip(
                          label: Text(distanceLabel(h)),
                          backgroundColor: const Color(0xFFEDF3EC),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  HospitalName(h['name']),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                        color: Color(0xFF68796D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t('Address', '주소')} · ${h['address']}',
                          style: const TextStyle(
                            height: 1.6,
                            color: Color(0xFF526158),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isPharmacy(h)) ...[
                    const SizedBox(height: 12),
                    Text(
                      specialistSummary(h),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('Registered doctors', '등록 의사 수')} · ${h['doctors']} ${t('people', '명')}',
                      style: const TextStyle(
                        color: Color(0xFF68796D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (!isPharmacy(h) && widget.onPrepare != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () => widget.onPrepare!(h),
                      icon: const Icon(Icons.description_outlined),
                      label: Text(t('Prepare for this visit', '이 병원 방문 준비하기')),
                    ),
                  if (isDemoClinic(h))
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClinicReviewsPage(
                            api: widget.api,
                            hospital: Map<String, dynamic>.from(h),
                            canReview: widget.canReadExperiences,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(
                        tr('Visit experiences · demo examples included'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => open(
                          Uri.https('www.google.com', '/maps/dir/', {
                            'api': '1',
                            'destination': '${h['name']} ${h['address']}',
                          }),
                        ),
                        icon: const Icon(Icons.directions_outlined, size: 18),
                        label: Text(t('Google directions', 'Google 길찾기')),
                      ),
                      if ((h['phone'] as String).isNotEmpty)
                        TextButton.icon(
                          onPressed: () =>
                              open(Uri(scheme: 'tel', path: h['phone'])),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: Text(h['phone']),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      t('Clinic details', '진료과·기관 상세'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isPharmacy(h))
                        for (final d in h['departments'] as List)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              '${bilingualSpecialty(d['name'])} · ${t('Reported specialists', '신고 전문의')} ${d['specialists']}',
                            ),
                          ),
                      const SizedBox(height: 10),
                      Text(
                        t(
                          'A listed department does not guarantee a specialist. Language support and opening hours must be checked with the clinic.',
                          '진료과목 표기가 전문의 보유를 뜻하지 않습니다. 외국어 지원과 진료 시간은 병원에 확인하세요.',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68796D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Text('${data!['source']} · ${data!['license']}'),
      ],
    ],
  );
}

// Department-name translations only. No symptom-based triage or diagnosis.
const departmentGuide = [
  {
    'ko': '내과',
    'en': 'Internal medicine',
    'ja': '内科',
    'zh': '内科',
    'ru': 'Терапия',
  },
  {
    'ko': '가정의학과',
    'en': 'Family medicine',
    'ja': '家庭医学科',
    'zh': '家庭医学科',
    'ru': 'Семейная медицина',
  },
  {
    'ko': '치과',
    'en': 'Dentistry · teeth',
    'ja': '歯科',
    'zh': '牙科',
    'ru': 'Стоматология',
  },
  {
    'ko': '피부과',
    'en': 'Dermatology · skin',
    'ja': '皮膚科',
    'zh': '皮肤科',
    'ru': 'Дерматология',
  },
  {
    'ko': '안과',
    'en': 'Ophthalmology · eyes',
    'ja': '眼科',
    'zh': '眼科',
    'ru': 'Офтальмология',
  },
  {
    'ko': '이비인후과',
    'en': 'ENT · ears, nose, throat',
    'ja': '耳鼻咽喉科',
    'zh': '耳鼻喉科',
    'ru': 'Отоларингология',
  },
  {
    'ko': '정형외과',
    'en': 'Orthopedics · bones, joints',
    'ja': '整形外科',
    'zh': '骨科',
    'ru': 'Ортопедия',
  },
  {
    'ko': '산부인과',
    'en': 'Obstetrics / gynecology',
    'ja': '産婦人科',
    'zh': '妇产科',
    'ru': 'Акушерство и гинекология',
  },
];

bool hospitalMatchesQuery(Map h, String query) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '');
  final q = normalize(query);
  if (q.isEmpty) return true;
  for (final entry in specialtyEnglish.entries) {
    final labels = <String>[
      entry.key,
      entry.value,
      ...(MoriLanguage.catalog[entry.value] as Map? ?? {}).values
          .cast<String>(),
      ...departmentGuide
          .where((d) => d['ko'] == entry.key)
          .expand((d) => d.values),
    ];
    if (labels.any((label) => normalize(label) == q)) {
      final category = entry.key == '치과'
          ? bodyCategories.firstWhere((c) => c.id == 'teeth')
          : BodyCategory('query', entry.value, entry.key, [entry.key]);
      return matchesBodyCategory(h, category);
    }
  }
  final departmentNames = (h['departments'] as List? ?? []).map(
    (d) => '${d['name']}',
  );
  final candidates = <String>[
    '${h['name']}',
    ...hospitalSearchReadings('${h['name']}'),
    '${h['address']}',
    '${h['type']}',
  ];
  for (final name in departmentNames) {
    candidates.add(name);
    final en = specialtyEnglish[name];
    if (en != null) {
      candidates.add(en);
      candidates.addAll(
        (MoriLanguage.catalog[en] as Map? ?? {}).values.cast<String>(),
      );
    }
  }
  return candidates.any((value) => normalize(value).contains(q));
}

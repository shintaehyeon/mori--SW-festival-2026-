import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/facility_categories.dart';

void main() {
  test('conventional care excludes Korean medicine and pharmacies', () {
    expect(facilityMatches({'type': '의원'}, 'medical'), isTrue);
    expect(facilityMatches({'type': '한의원'}, 'medical'), isFalse);
    expect(facilityMatches({'type': '한방병원'}, 'traditional'), isTrue);
    expect(
      facilityMatches({
        'type': '약국',
        'pharmacyClassification': 'unknown',
      }, 'medical'),
      isFalse,
    );
  });
  test('names never decide pharmacy type; evidence is required', () {
    for (final name in ['편한약국', '행복한약국', '양약국', '한약국']) {
      final h = {
        'name': name,
        'type': '약국',
        'pharmacyClassification': 'unknown',
        'classificationEvidence': null,
      };
      expect(facilityMatches(h, 'unknownPharmacy'), isTrue);
      expect(facilityMatches(h, 'westernPharmacy'), isFalse);
      expect(facilityMatches(h, 'herbalPharmacy'), isFalse);
    }
    expect(
      facilityMatches({
        'pharmacyClassification': 'herbal',
        'classificationEvidence': null,
      }, 'herbalPharmacy'),
      isFalse,
    );
    expect(
      facilityMatches({
        'pharmacyClassification': 'herbal',
        'classificationEvidence': 'test-source',
      }, 'herbalPharmacy'),
      isTrue,
    );
  });
}

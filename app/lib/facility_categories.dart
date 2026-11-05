import 'localization.dart';

// Classification relies on source fields and explicit evidence, never names.
const traditionalFacilityTypes = {'한의원', '한방병원'};
bool isPharmacy(Map h) => h.containsKey('pharmacyClassification');
bool facilityMatches(Map h, String category) {
  if (category == 'medical') {
    return !isPharmacy(h) && !traditionalFacilityTypes.contains(h['type']);
  }
  if (category == 'traditional') {
    return !isPharmacy(h) && traditionalFacilityTypes.contains(h['type']);
  }
  if (!isPharmacy(h)) return false;
  final verified = h['classificationEvidence'] != null;
  if (category == 'westernPharmacy') {
    return verified && h['pharmacyClassification'] == 'western';
  }
  if (category == 'herbalPharmacy') {
    return verified && h['pharmacyClassification'] == 'herbal';
  }
  return category == 'unknownPharmacy' &&
      (!verified ||
          !['western', 'herbal'].contains(h['pharmacyClassification']));
}

String facilityLabel(Map h, bool ko) {
  if (isPharmacy(h)) {
    if (facilityMatches(h, 'westernPharmacy')) {
      return tr('Pharmacy · Western medicines', '양약국');
    }
    if (facilityMatches(h, 'herbalPharmacy')) {
      return tr('Herbal pharmacy · Korean medicines', '한약국');
    }
    return tr(
      'Pharmacy · Western/herbal type unverified',
      '약국 · 양약국/한약국 유형 미확인',
    );
  }
  if (h['type'] == '한의원') {
    return tr('Korean medicine clinic · Traditional medicine', '한의원 · 한국 전통의학');
  }
  if (h['type'] == '한방병원') {
    return tr(
      'Korean medicine hospital · Traditional medicine',
      '한방병원 · 한국 전통의학',
    );
  }
  return tr(
    const {
          '의원': 'Clinic',
          '병원': 'Hospital',
          '종합병원': 'General hospital',
          '치과의원': 'Dental clinic',
          '치과병원': 'Dental hospital',
          '보건소': 'Public health center',
          '보건지소': 'Public health branch',
          '보건진료소': 'Public health post',
          '요양병원': 'Long-term care hospital',
        }[h['type']] ??
        '${h['type']}',
    '${h['type']}',
  );
}

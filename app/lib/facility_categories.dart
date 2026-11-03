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
      return ko ? '양약국' : 'Pharmacy · Western medicines';
    }
    if (facilityMatches(h, 'herbalPharmacy')) {
      return ko ? '한약국' : 'Herbal pharmacy · Korean medicines';
    }
    return ko
        ? '약국 · 양약국/한약국 유형 미확인'
        : 'Pharmacy · Western/herbal type unverified';
  }
  if (h['type'] == '한의원') {
    return ko
        ? '한의원 · 한국 전통의학'
        : 'Korean medicine clinic · Traditional medicine';
  }
  if (h['type'] == '한방병원') {
    return ko
        ? '한방병원 · 한국 전통의학'
        : 'Korean medicine hospital · Traditional medicine';
  }
  return '${h['type']}';
}

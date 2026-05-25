class MedicalClinic {
  final String id;
  final String name;
  final String cityName;
  final double successScore;
  final int patientCount;
  final bool isMinistryAccredited;
  final bool isJciAccredited;
  final List<String> specializations;
  final List<String> languages;
  final double commissionRate;

  MedicalClinic({
    required this.id,
    required this.name,
    required this.cityName,
    required this.successScore,
    required this.patientCount,
    required this.isMinistryAccredited,
    required this.isJciAccredited,
    required this.specializations,
    required this.languages,
    required this.commissionRate,
  });

  factory MedicalClinic.fromJson(Map<String, dynamic> json) {
    return MedicalClinic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cityName: json['city_name'] ?? '',
      successScore: (json['success_score'] ?? 0).toDouble(),
      patientCount: json['patient_count'] ?? 0,
      isMinistryAccredited: json['is_ministry_accredited'] ?? false,
      isJciAccredited: json['is_jci_accredited'] ?? false,
      specializations: List<String>.from(json['specializations'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      commissionRate: (json['commission_rate'] ?? 0.22).toDouble(),
    );
  }
}

class MedicalPackage {
  final String id;
  final String clinicId;
  final String treatmentType;
  final String treatmentName;
  final String treatmentNameTr;
  final String description;
  final int durationTreatmentDays;
  final int durationRestDays;
  final double priceTL;
  final double? priceEur;
  final List<String> includes;
  final double successRate;
  final double commissionRate;
  final MedicalClinic? clinic;

  MedicalPackage({
    required this.id,
    required this.clinicId,
    required this.treatmentType,
    required this.treatmentName,
    required this.treatmentNameTr,
    required this.description,
    required this.durationTreatmentDays,
    required this.durationRestDays,
    required this.priceTL,
    this.priceEur,
    required this.includes,
    required this.successRate,
    required this.commissionRate,
    this.clinic,
  });

  int get totalDays => durationTreatmentDays + durationRestDays;

  String get treatmentTypeLabel {
    const labels = {
      'hair_transplant': 'Saç Ekimi',
      'dental': 'Diş Estetiği',
      'eye_laser': 'Göz Lazer',
      'obesity': 'Obezite Cerrahisi',
      'aesthetic': 'Estetik Cerrahi',
    };
    return labels[treatmentType] ?? treatmentType;
  }

  String get treatmentTypeEmoji {
    const emojis = {
      'hair_transplant': '💆',
      'dental': '🦷',
      'eye_laser': '👁️',
      'obesity': '🏥',
      'aesthetic': '✨',
    };
    return emojis[treatmentType] ?? '🏥';
  }

  factory MedicalPackage.fromJson(Map<String, dynamic> json) {
    return MedicalPackage(
      id: json['id'] ?? '',
      clinicId: json['clinic_id'] ?? '',
      treatmentType: json['treatment_type'] ?? '',
      treatmentName: json['treatment_name'] ?? '',
      treatmentNameTr: json['treatment_name_tr'] ?? '',
      description: json['description'] ?? '',
      durationTreatmentDays: json['duration_treatment_days'] ?? 1,
      durationRestDays: json['duration_rest_days'] ?? 1,
      priceTL: (json['price_tl'] ?? 0).toDouble(),
      priceEur: json['price_eur']?.toDouble(),
      includes: List<String>.from(json['includes'] ?? []),
      successRate: (json['success_rate'] ?? 0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0.22).toDouble(),
      clinic: json['medical_clinics'] != null
          ? MedicalClinic.fromJson(json['medical_clinics'])
          : null,
    );
  }
}

class MedicalBudgetResult {
  final int totalCost;
  final int flightCost;
  final int treatmentCost;
  final int hotelCost;
  final int transferCost;
  final int remaining;
  final int totalDays;
  final int commissionTL;
  final int commissionRate;
  final bool isAffordable;

  MedicalBudgetResult({
    required this.totalCost,
    required this.flightCost,
    required this.treatmentCost,
    required this.hotelCost,
    required this.transferCost,
    required this.remaining,
    required this.totalDays,
    required this.commissionTL,
    required this.commissionRate,
    required this.isAffordable,
  });

  factory MedicalBudgetResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] ?? {};
    return MedicalBudgetResult(
      totalCost: (json['totalCost'] ?? 0).toInt(),
      flightCost: (breakdown['flight'] ?? 0).toInt(),
      treatmentCost: (breakdown['treatment'] ?? 0).toInt(),
      hotelCost: (breakdown['hotel'] ?? 0).toInt(),
      transferCost: (breakdown['transfer'] ?? 0).toInt(),
      remaining: (json['remaining'] ?? 0).toInt(),
      totalDays: (json['totalDays'] ?? 0).toInt(),
      commissionTL: (json['commissionTL'] ?? 0).toInt(),
      commissionRate: (json['commissionRate'] ?? 22).toInt(),
      isAffordable: json['isAffordable'] ?? false,
    );
  }
}
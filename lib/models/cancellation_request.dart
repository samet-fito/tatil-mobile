enum CancellationRequestStatus {
  pending,
  processing,
  approved,
  rejected,
}

class CancellationRequest {
  const CancellationRequest({
    required this.id,
    required this.reservationId,
    required this.cityName,
    required this.reason,
    required this.createdAt,
    this.status = CancellationRequestStatus.pending,
    this.note = '',
  });

  final String id;
  final String reservationId;
  final String cityName;
  final String reason;
  final DateTime createdAt;
  final CancellationRequestStatus status;
  final String note;

  String get statusLabel {
    switch (status) {
      case CancellationRequestStatus.pending:
        return 'Beklemede';
      case CancellationRequestStatus.processing:
        return 'İşleniyor';
      case CancellationRequestStatus.approved:
        return 'Onaylandı';
      case CancellationRequestStatus.rejected:
        return 'Reddedildi';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reservationId': reservationId,
        'cityName': cityName,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'note': note,
      };

  factory CancellationRequest.fromJson(Map<String, dynamic> json) {
    return CancellationRequest(
      id: json['id']?.toString() ?? '',
      reservationId: json['reservationId']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: CancellationRequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CancellationRequestStatus.pending,
      ),
      note: json['note']?.toString() ?? '',
    );
  }
}

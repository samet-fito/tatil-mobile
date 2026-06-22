import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/cancellation_request.dart';
import '../models/stored_booking_model.dart';
import '../services/cancellation_request_store.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

/// Rezervasyon detayında online iptal / değişiklik talebi.
class OnlineCancellationSection extends StatefulWidget {
  const OnlineCancellationSection({super.key, required this.booking});

  final StoredBooking booking;

  @override
  State<OnlineCancellationSection> createState() =>
      _OnlineCancellationSectionState();
}

class _OnlineCancellationSectionState extends State<OnlineCancellationSection> {
  CancellationRequest? _existing;
  bool _loading = true;
  bool _submitting = false;

  static const _reasons = [
    'Planlarım değişti',
    'Sağlık nedeni',
    'Vize / pasaport sorunu',
    'Daha uygun fiyat buldum',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final req = await CancellationRequestStore.forReservation(
      widget.booking.reservationId,
    );
    if (mounted) {
      setState(() {
        _existing = req;
        _loading = false;
      });
    }
  }

  Future<void> _openRequestSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showModalBottomSheet<_CancellationSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CancellationRequestSheet(
        booking: widget.booking,
        reasons: _reasons,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _submitting = true);
    final req = await CancellationRequestStore.submit(
      reservationId: widget.booking.reservationId,
      cityName: widget.booking.cityName,
      reason: result.reason,
      note: result.note,
    );
    if (!mounted) return;
    setState(() {
      _existing = req;
      _submitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'İptal talebiniz alındı. 24 saat içinde e-posta ile bilgilendirileceksiniz.',
        ),
        backgroundColor: AppTheme.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CupertinoActivityIndicator(radius: 10)),
      );
    }

    if (_existing != null) {
      final req = _existing!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.doc_text,
                  size: 18,
                  color: AppTheme.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'İptal talebi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    req.statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Neden: ${req.reason}',
              style: TatilTheme.hint.copyWith(fontSize: 12),
            ),
            if (req.note.isNotEmpty)
              Text(
                req.note,
                style: TatilTheme.hint.copyWith(fontSize: 12),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _submitting ? null : _openRequestSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.orangeSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(radius: 8),
                    )
                  : const Icon(
                      CupertinoIcons.xmark_circle,
                      color: AppTheme.orange,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İptal veya değişiklik talebi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Self-servis talep oluşturun — 7/24',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CancellationSheetResult {
  const _CancellationSheetResult({required this.reason, required this.note});

  final String reason;
  final String note;
}

class _CancellationRequestSheet extends StatefulWidget {
  const _CancellationRequestSheet({
    required this.booking,
    required this.reasons,
  });

  final StoredBooking booking;
  final List<String> reasons;

  @override
  State<_CancellationRequestSheet> createState() =>
      _CancellationRequestSheetState();
}

class _CancellationRequestSheetState extends State<_CancellationRequestSheet> {
  late String _reason;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _reason = widget.reasons.first;
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(
      context,
      _CancellationSheetResult(
        reason: _reason,
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'İptal talebi oluştur',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _close,
                  icon: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            Text(
              '${widget.booking.cityName} · ${widget.booking.reservationId}',
              style: TatilTheme.hint.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'İptal nedeni',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.reasons.map((r) {
              final selected = _reason == r;
              return GestureDetector(
                onTap: () => setState(() => _reason = r),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.orange.withValues(alpha: 0.1)
                        : AppTheme.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.orange : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        size: 18,
                        color:
                            selected ? AppTheme.orange : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ek not (isteğe bağlı)',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Talebi gönder',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

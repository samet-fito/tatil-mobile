import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/search_category.dart';
import '../services/coupon_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

/// Ödeme özetinde kupon kodu — indirim tetikleyici.
class CheckoutCouponSection extends StatefulWidget {
  const CheckoutCouponSection({
    super.key,
    required this.checkoutCategory,
    required this.subtotalTL,
    required this.onApplied,
    this.initialCode,
  });

  final SearchCategory? checkoutCategory;
  final int subtotalTL;
  final void Function(CouponResult? result) onApplied;
  final String? initialCode;

  @override
  State<CheckoutCouponSection> createState() => _CheckoutCouponSectionState();
}

class _CheckoutCouponSectionState extends State<CheckoutCouponSection> {
  late final TextEditingController _ctrl;
  CouponResult? _applied;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _apply();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _apply() {
    final result = CouponService.validate(
      rawCode: _ctrl.text,
      checkoutCategory: widget.checkoutCategory,
      subtotalTL: widget.subtotalTL,
    );
    if (!mounted) return;
    setState(() {
      if (result == null) {
        _applied = null;
        _error = CouponService.errorMessage(_ctrl.text);
      } else {
        _applied = result;
        _error = null;
      }
    });
    widget.onApplied(_applied);
  }

  void _clear() {
    _ctrl.clear();
    if (!mounted) return;
    setState(() {
      _applied = null;
      _error = null;
    });
    widget.onApplied(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _applied != null
              ? AppTheme.teal.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.tag_fill, color: AppTheme.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'İndirim kodu',
                style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Örn. VIZE100',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 8),
              if (_applied != null)
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  color: AppTheme.textMuted,
                )
              else
                TextButton(
                  onPressed: _apply,
                  child: const Text('Uygula'),
                ),
            ],
          ),
          if (_applied != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_applied!.message} (−${_applied!.discountTL} TL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

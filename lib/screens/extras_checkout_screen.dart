import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../utils/trip_locale.dart';

/// Uçuş + otel sonrası sigorta ve rent a car ödemesi.
class ExtrasCheckoutScreen extends StatefulWidget {
  const ExtrasCheckoutScreen({
    super.key,
    required this.route,
    required this.adults,
    required this.children,
    required this.reservationId,
  });

  final RouteResultModel route;
  final int adults;
  final int children;
  final String reservationId;

  @override
  State<ExtrasCheckoutScreen> createState() => _ExtrasCheckoutScreenState();
}

class _ExtrasCheckoutScreenState extends State<ExtrasCheckoutScreen> {
  bool _healthInsurance = true;
  bool _processing = false;

  int get _people => widget.adults + widget.children;

  bool get _showInsurance =>
      TripLocale.isInternational(country: widget.route.country);

  int get _insuranceTotal => AppConstants.insurancePrice * _people;

  int get _total => _showInsurance && _healthInsurance ? _insuranceTotal : 0;

  String _fmt(int v) =>
      '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';

  Future<void> _pay() async {
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir ek hizmet seçin')),
      );
      return;
    }
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ek ödemeler alındı: ${_fmt(_total)}'),
        backgroundColor: AppTheme.orange,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Ek Hizmetler'),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ek ödeme tutarı', style: TextStyle(color: AppTheme.textMuted)),
                Text(
                  _fmt(_total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _processing || _total <= 0 ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Ödemeyi Tamamla',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
            ),
            child: Text(
              _showInsurance
                  ? 'Uçuş ve otel ödemeniz alındı (No: ${widget.reservationId}). '
                      'İsteğe bağlı sigorta için devam edin.'
                  : 'Uçuş ve otel ödemeniz alındı (No: ${widget.reservationId}).',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
            ),
          ),
          if (_showInsurance) ...[
            const SizedBox(height: 16),
            _toggleTile(
              icon: CupertinoIcons.heart_fill,
              title: 'Seyahat Sağlık Sigortası',
              subtitle: 'Kişi başı ${AppConstants.insurancePrice} TL · acil tedavi & iptal',
              price: _insuranceTotal,
              value: _healthInsurance,
              onChanged: (v) => setState(() => _healthInsurance = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int price,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? AppTheme.orange : AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text('+${_fmt(price)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.orange)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppTheme.orange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

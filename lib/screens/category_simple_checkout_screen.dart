import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/search_category.dart';
import '../config/app_experience.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/category_checkout_route.dart';
import '../utils/price_format.dart';
import '../widgets/preview_mode_banner.dart';
import '../services/travel_booking_service.dart';
import 'activity_booking_success_screen.dart';
import 'booking_success_screen.dart';
import 'category_booking_success_screen.dart';

/// Otobüs, transfer ve araç kiralama için tek ürün checkout.
class CategorySimpleCheckoutScreen extends StatefulWidget {
  const CategorySimpleCheckoutScreen({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.priceTL,
    required this.destinationCity,
    this.destinationIata = '',
    this.passengers = 1,
    this.activity,
    this.activityCategory = 'tours',
    this.eventDate,
    this.departureDate,
    this.returnDate,
  });

  final SearchCategory category;
  final String title;
  final String subtitle;
  final int priceTL;
  final String destinationCity;
  final String destinationIata;
  final int passengers;
  final Map<String, dynamic>? activity;
  final String activityCategory;
  final DateTime? eventDate;
  final DateTime? departureDate;
  final DateTime? returnDate;

  @override
  State<CategorySimpleCheckoutScreen> createState() =>
      _CategorySimpleCheckoutScreenState();
}

class _CategorySimpleCheckoutScreenState
    extends State<CategorySimpleCheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad ve telefon zorunludur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _processing = false);

    final reservationId =
        'VG-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    if (widget.category == SearchCategory.activities &&
        widget.activity != null) {
      final eventDate =
          widget.eventDate ?? DateTime.now().add(const Duration(days: 7));
      await TravelBookingService.saveCategoryBooking(
        category: SearchCategory.activities,
        reservationId: reservationId,
        title: widget.title,
        destinationCity: widget.destinationCity,
        destinationIata: widget.destinationIata,
        totalPriceTL: widget.priceTL,
        passengerName: _nameCtrl.text.trim(),
        passengerEmail: _emailCtrl.text.trim(),
        departureDate: eventDate,
        returnDate: eventDate,
        passengers: widget.passengers,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityBookingSuccessScreen(
            activity: widget.activity!,
            cityName: widget.destinationCity,
            destinationIata: widget.destinationIata.isNotEmpty
                ? widget.destinationIata
                : widget.destinationCity.length >= 3
                    ? widget.destinationCity.substring(0, 3).toUpperCase()
                    : 'ACT',
            reservationId: reservationId,
            passengerName: _nameCtrl.text.trim(),
            passengerEmail: _emailCtrl.text.trim(),
            totalPrice: widget.priceTL,
            eventDate: widget.eventDate ?? DateTime.now().add(const Duration(days: 7)),
            activityCategory: widget.activityCategory,
            passengers: widget.passengers,
          ),
        ),
      );
      return;
    }

    if (widget.category == SearchCategory.bus ||
        widget.category == SearchCategory.transfer ||
        widget.category == SearchCategory.carRental) {
      await TravelBookingService.saveCategoryBooking(
        category: widget.category,
        reservationId: reservationId,
        title: widget.title,
        destinationCity: widget.destinationCity,
        destinationIata: widget.destinationIata,
        totalPriceTL: widget.priceTL,
        passengerName: _nameCtrl.text.trim(),
        passengerEmail: _emailCtrl.text.trim(),
        departureDate: widget.departureDate ?? widget.eventDate,
        returnDate: widget.returnDate,
        passengers: widget.passengers,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryBookingSuccessScreen(
            category: widget.category,
            title: widget.title,
            subtitle: widget.subtitle,
            reservationId: reservationId,
            totalPriceTL: widget.priceTL,
            passengerName: _nameCtrl.text.trim(),
            eventDate: widget.eventDate,
          ),
        ),
      );
      return;
    }

    final route = CategoryCheckoutRoute.build(
      destinationIata: widget.destinationCity.length >= 3
          ? widget.destinationCity.substring(0, 3).toUpperCase()
          : 'TR',
      cityName: widget.destinationCity,
      nights: 1,
      passengers: widget.passengers,
      transferTL: widget.category == SearchCategory.transfer ||
              widget.category == SearchCategory.bus
          ? widget.priceTL
          : 0,
      hotelTL: widget.category == SearchCategory.carRental ||
              widget.category == SearchCategory.activities
          ? widget.priceTL
          : 0,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          route: route,
          departureDate: DateTime.now(),
          returnDate: DateTime.now().add(const Duration(days: 1)),
          adults: widget.passengers,
          children: 0,
          totalPrice: widget.priceTL,
          passengerName: _nameCtrl.text.trim(),
          passengerEmail: _emailCtrl.text.trim(),
          reservationId: reservationId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(widget.category.icon, size: 18, color: AppTheme.orange),
            const SizedBox(width: 8),
            Text(
              '${widget.category.label} Rezervasyonu',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 16),
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
                const Text('Toplam', style: TextStyle(color: AppTheme.textMuted)),
                Text(
                  PriceFormat.format(widget.priceTL),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _processing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppExperience.paymentsEnabled
                            ? 'Ödemeyi Tamamla'
                            : AppExperience.confirmReservationLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PreviewModeBanner(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: TatilTheme.hint.copyWith(height: 1.4),
                ),
                if (widget.passengers > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${widget.passengers} yolcu',
                    style: TatilTheme.hint.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'İletişim bilgileri',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: _fieldDecoration('Ad Soyad'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCtrl,
            decoration: _fieldDecoration('E-posta (opsiyonel)'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            decoration: _fieldDecoration('Telefon'),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

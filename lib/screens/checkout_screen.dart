import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../models/route_result_model.dart';

class CheckoutScreen extends StatefulWidget {
  final RouteResultModel route;
  final List<Map<String, dynamic>> flights;
  final List<Map<String, dynamic>> hotels;
  final DateTime departureDate;
  final DateTime returnDate;
  final int children;
  final int adults;

  const CheckoutScreen({
    super.key,
    required this.route,
    required this.flights,
    required this.hotels,
    required this.departureDate,
    required this.returnDate,
    required this.children,
    required this.adults,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0; // 0: Ucus Sec, 1: Otel Sec, 2: Ozet, 3: Yolcu, 4: Odeme
  int _selectedFlightIndex = 0;
  int _selectedHotelIndex = 0;
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  List<Map<String, TextEditingController>> _passengerControllers = [];

@override
void initState() {
    super.initState();
    _passengerControllers = List.generate(
      widget.adults + widget.children,
      (_) => {
        'name': TextEditingController(),
        'surname': TextEditingController(),
        'email': TextEditingController(),
        'phone': TextEditingController(),
        'age': TextEditingController(),
      },
    );
  }
  bool _isProcessing = false;
  String _countryCode = '+90';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkiye'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'ABD'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'Ingiltere'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Almanya'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'Fransa'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italya'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Ispanya'},
    {'code': '+31', 'flag': '🇳🇱', 'name': 'Hollanda'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Rusya'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'BAE'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Suudi Arabistan'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japonya'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'Cin'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'Hindistan'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Avustralya'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brezilya'},
    {'code': '+30', 'flag': '🇬🇷', 'name': 'Yunanistan'},
    {'code': '+36', 'flag': '🇭🇺', 'name': 'Macaristan'},
  ];

  Map<String, dynamic>? get _selectedFlight =>
      widget.flights.isNotEmpty ? widget.flights[_selectedFlightIndex] : null;

  Map<String, dynamic>? get _selectedHotel =>
      widget.hotels.isNotEmpty ? widget.hotels[_selectedHotelIndex] : null;

  int get _flightPriceTL =>
      (_selectedFlight?['totalAmountTL'] as num?)?.toInt() ?? 0;

  int get _hotelPriceTL {
    final priceEur = (_selectedHotel?['pricePerNight'] as num?)?.toDouble() ?? 0;
    return (priceEur * 36 * widget.route.nights).toInt();
  }

  int get _totalPrice => _flightPriceTL + _hotelPriceTL;

  String _fmt(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
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
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          ['Ucus Sec', 'Otel Sec', 'Rezervasyon Ozeti', 'Yolcu Bilgileri', 'Odeme'][_step],
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: [
                _buildFlightSelection(),
                _buildHotelSelection(),
                _buildSummary(),
                _buildPassengerForm(),
                _buildPaymentForm(),
              ][_step],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Ucus', 'Otel', 'Ozet', 'Yolcu', 'Odeme'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.bgSecondary,
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final isActive = _step >= i;
          final isCurrent = _step == i;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.accent : AppTheme.bgTertiary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isCurrent ? AppTheme.accent : Colors.transparent),
                        ),
                        child: Center(
                          child: isActive && !isCurrent
                              ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 12)
                              : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppTheme.textMuted)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(label, style: TextStyle(fontSize: 9, color: isActive ? AppTheme.accent : AppTheme.textMuted)),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(width: 16, height: 1, color: _step > i ? AppTheme.accent : AppTheme.border),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // ADIM 1: UCUS SEC
  // ============================================================
  Widget _buildFlightSelection() {
    if (widget.flights.isEmpty) {
      return const Center(
        child: Text('Ucus bulunamadi.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(CupertinoIcons.airplane, color: AppTheme.teal, size: 16),
            const SizedBox(width: 8),
            Text(
              '${widget.route.cityName} · ${_formatDate(widget.departureDate)} - ${_formatDate(widget.returnDate)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.teal, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ...widget.flights.asMap().entries.map((e) {
          final i = e.key;
          final flight = e.value;
          final isSelected = _selectedFlightIndex == i;
          final priceTL = (flight['totalAmountTL'] as num?)?.toInt() ?? 0;
          final priceEur = flight['totalAmount'] ?? 0;
          return GestureDetector(
            onTap: () => setState(() => _selectedFlightIndex = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.teal.withOpacity(0.08) : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.teal : AppTheme.border, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.airplane, color: AppTheme.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(flight['airline'] ?? '--',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        Text(
                          '${flight['stops'] == 0 ? "Direkt" : "${flight['stops']} aktarma"} · ${flight['duration'] ?? "--"} · Gidis-Donus',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$priceTL TL', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.teal)),
                      Text('€$priceEur', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.teal, size: 20),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // ADIM 2: OTEL SEC
  // ============================================================
  Widget _buildHotelSelection() {
    if (widget.hotels.isEmpty) {
      return const Center(
        child: Text('Otel bulunamadi.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(CupertinoIcons.house, color: AppTheme.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              '${widget.route.nights} gece · ${_formatDate(widget.departureDate)} - ${_formatDate(widget.returnDate)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ...widget.hotels.asMap().entries.map((e) {
          final i = e.key;
          final hotel = e.value;
          final isSelected = _selectedHotelIndex == i;
          final priceEur = (hotel['pricePerNight'] as num?)?.toDouble() ?? 0;
          final priceTL = (priceEur * 36).toInt();
          final totalTL = priceTL * widget.route.nights;
          return GestureDetector(
            onTap: () => setState(() => _selectedHotelIndex = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent.withOpacity(0.08) : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.house, color: AppTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotel['name'] ?? '--',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        Row(children: [
                          const Icon(CupertinoIcons.star_fill, color: Color(0xFFF59E0B), size: 11),
                          const SizedBox(width: 3),
                          Text('${hotel['reviewScore'] ?? 0}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          const SizedBox(width: 6),
                          Text('${hotel['stars'] ?? 0}★', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${_fmt(priceTL)}/gece', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                      Text('Toplam: ${_fmt(totalTL)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.accent, size: 20),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // ADIM 3: OZET
  // ============================================================
  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.accent.withOpacity(0.15), AppTheme.teal.withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(CupertinoIcons.map_pin, color: AppTheme.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.route.cityName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text('${widget.route.country} · ${widget.route.nights} gece',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                Text('${_formatDate(widget.departureDate)} → ${_formatDate(widget.returnDate)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        if (_selectedFlight != null) ...[
          const Text('Secilen Ucus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          _summaryCard(
            icon: CupertinoIcons.airplane, color: AppTheme.teal,
            title: _selectedFlight!['airline'] ?? '--',
            subtitle: '${_selectedFlight!['stops'] == 0 ? "Direkt" : "Aktarmali"} · Gidis-Donus',
            price: _fmt(_flightPriceTL),
          ),
          const SizedBox(height: 12),
        ],

        if (_selectedHotel != null) ...[
          const Text('Secilen Otel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          _summaryCard(
            icon: CupertinoIcons.house, color: AppTheme.accent,
            title: _selectedHotel!['name'] ?? '--',
            subtitle: '${widget.route.nights} gece · ${_selectedHotel!['stars'] ?? 0}★',
            price: _fmt(_hotelPriceTL),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: [
            _priceRow('Ucus (Gidis-Donus)', _fmt(_flightPriceTL)),
            _priceRow('Otel (${widget.route.nights} gece)', _fmt(_hotelPriceTL)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Toplam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(_fmt(_totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.accent)),
              ],
            ),
          ]),
        ),
      ],
    );
  }

  Widget _summaryCard({required IconData icon, required Color color, required String title, required String subtitle, required String price}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.accent)),
      ]),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ]),
    );
  }

  // ============================================================
  // ADIM 4: YOLCU
  // ============================================================
  Widget _buildPassengerForm() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...List.generate(widget.adults, (i) {
        final ctrl = _passengerControllers[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yetiskin ${i + 1}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(ctrl['name']!, 'Ad', 'Adiniz')),
              const SizedBox(width: 12),
              Expanded(child: _field(ctrl['surname']!, 'Soyad', 'Soyadiniz')),
            ]),
            const SizedBox(height: 12),
            _field(ctrl['email']!, 'E-posta', 'email@example.com', isEmail: true),
            const SizedBox(height: 12),
            _buildPhoneField(),
            const SizedBox(height: 20),
          ],
        );
      }),
      if (widget.children > 0)
        ...List.generate(widget.children, (i) {
          final ctrl = _passengerControllers[widget.adults + i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Cocuk ${i + 1}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                  child: const Text('%50 Indirimli', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.teal)),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(ctrl['name']!, 'Ad', 'Adiniz')),
                const SizedBox(width: 12),
                Expanded(child: _field(ctrl['surname']!, 'Soyad', 'Soyadiniz')),
              ]),
              const SizedBox(height: 12),
              _field(ctrl['age']!, 'Yas', '2-11', isPhone: true),
              const SizedBox(height: 20),
            ],
          );
        }),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.teal.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(CupertinoIcons.info_circle, color: AppTheme.teal, size: 16),
          const SizedBox(width: 8),
          const Expanded(child: Text(
            'Bilet isim degisikligi ucret gerektirebilir. Pasaportunuzdaki ismi kullanin.',
            style: TextStyle(fontSize: 12, color: AppTheme.teal),
          )),
        ]),
      ),
    ],
  );
}

  // ============================================================
  // ADIM 5: ODEME
  // ============================================================
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kart Bilgileri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _field(_cardCtrl, 'Kart Numarasi', '0000 0000 0000 0000', isCard: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_expiryCtrl, 'Son Kullanma', 'AA/YY')),
              const SizedBox(width: 12),
              Expanded(child: _field(_cvvCtrl, 'CVV', '***')),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
          child: Column(children: [
            _priceRow('Ucus', _fmt(_flightPriceTL)),
            _priceRow('Otel', _fmt(_hotelPriceTL)),
            const Divider(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Toplam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(_fmt(_totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.accent)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(CupertinoIcons.lock_shield, color: AppTheme.teal, size: 16),
          const SizedBox(width: 8),
          const Text('256-bit SSL ile guvenli odeme', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ]),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Telefon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Row(children: [
          GestureDetector(
            onTap: _showCountryCodePicker,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppTheme.bgTertiary, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Row(children: [
                Text(_countryCodes.firstWhere((c) => c['code'] == _countryCode, orElse: () => _countryCodes[0])['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(_countryCode, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_down, size: 12, color: AppTheme.textMuted),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '5xx xxx xx xx',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgTertiary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Ulke Kodu Sec', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _countryCodes.length,
              itemBuilder: (ctx, i) {
                final country = _countryCodes[i];
                final isSelected = country['code'] == _countryCode;
                return GestureDetector(
                  onTap: () { setState(() => _countryCode = country['code']!); Navigator.pop(ctx); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: isSelected ? AppTheme.accent.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(country['name']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
                      Text(country['code']!, style: TextStyle(color: isSelected ? AppTheme.accent : AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {bool isEmail = false, bool isPhone = false, bool isCard = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : isCard ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgTertiary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final labels = ['Ucusa Devam Et →', 'Ozete Gec →', 'Yolcu Bilgileri →', 'Odemeye Gec →', 'Odemeyi Tamamla ${_fmt(_totalPrice)}'];
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: AppTheme.bgSecondary, border: Border(top: BorderSide(color: AppTheme.border))),
      child: GestureDetector(
        onTap: _isProcessing ? null : () async {
          if (_step < 4) {
            setState(() => _step++);
          } else {
            setState(() => _isProcessing = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) { setState(() => _isProcessing = false); _showSuccess(); }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFFFF3B41)]), borderRadius: BorderRadius.circular(14)),
          child: Center(
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(labels[_step], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(36)), child: const Icon(CupertinoIcons.checkmark_circle, color: AppTheme.teal, size: 40)),
            const SizedBox(height: 20),
            const Text('Rezervasyon Tamamlandi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('${widget.route.cityName} seyahatiniz basariyla rezerve edildi.', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () { Navigator.pop(ctx); Navigator.popUntil(context, (route) => route.isFirst); },
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppTheme.teal, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Ana Sayfaya Don', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)))),
            ),
          ]),
        ),
      ),
    );
  }
}
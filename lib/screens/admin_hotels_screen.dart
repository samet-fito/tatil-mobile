import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminHotelsScreen extends StatefulWidget {
  const AdminHotelsScreen({super.key});

  @override
  State<AdminHotelsScreen> createState() => _AdminHotelsScreenState();
}

class _AdminHotelsScreenState extends State<AdminHotelsScreen> {
  List<Map<String, dynamic>> _hotels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() => _isLoading = true);
    final hotels = await AdminService.getHotels();
    if (mounted) {
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    }
  }

  void _showHotelForm({Map<String, dynamic>? hotel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HotelFormSheet(
        hotel: hotel,
        onSave: (data) async {
          bool success;
          if (hotel != null) {
            success = await AdminService.updateHotel(hotel['id'], data);
          } else {
            success = await AdminService.addHotel(data);
          }
          if (success && mounted) {
            Navigator.pop(ctx);
            _loadHotels();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(hotel != null
                    ? '✅ Otel güncellendi!'
                    : '✅ Otel eklendi!'),
                backgroundColor: AppTheme.accent,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteHotel(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oteli Kaldır'),
        content: Text('$name oteli pasif yapılacak. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaldır',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AdminService.deleteHotel(id);
      _loadHotels();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🏨 Otel Yönetimi',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHotels,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHotelForm(),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Otel Ekle',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _hotels.isEmpty
              ? const Center(
                  child: Text('Henüz otel yok.',
                      style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _hotels.length,
                  itemBuilder: (ctx, i) => _buildHotelCard(_hotels[i]),
                ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final isActive = hotel['is_active'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.black.withOpacity(0.06)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel['name'] ?? '--',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${hotel['city_name']} · ${hotel['destination_iata']} · ${hotel['hotel_type']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('Pasif',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip('💰',
                    '${hotel['price_per_night']?.toInt() ?? 0} TL/gece'),
                const SizedBox(width: 8),
                _infoChip(
                    '⭐', '${hotel['review_score'] ?? 0}/10'),
                const SizedBox(width: 8),
                _infoChip('🏆',
                    '${hotel['star_rating']?.toInt() ?? 0} yıldız'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showHotelForm(hotel: hotel),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Düzenle'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _deleteHotel(hotel['id'], hotel['name']),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Kaldır'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String emoji, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ============================================================
// OTEL FORM BOTTOM SHEET
// ============================================================
class HotelFormSheet extends StatefulWidget {
  final Map<String, dynamic>? hotel;
  final Function(Map<String, dynamic>) onSave;

  const HotelFormSheet({super.key, this.hotel, required this.onSave});

  @override
  State<HotelFormSheet> createState() => _HotelFormSheetState();
}

class _HotelFormSheetState extends State<HotelFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _iataCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _ratingCtrl;
  late TextEditingController _phoneCtrl;
  String _hotelType = 'hotel';
  double _starRating = 3.0;
  bool _isSponsored = false;
  double _bonusScore = 5.0;

  final List<String> _hotelTypes = [
    'hotel', 'boutique', 'pension', 'apart', 'hostel'
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.hotel;
    _nameCtrl = TextEditingController(text: h?['name'] ?? '');
    _cityCtrl = TextEditingController(text: h?['city_name'] ?? '');
    _iataCtrl = TextEditingController(
        text: h?['destination_iata'] ?? '');
    _priceCtrl = TextEditingController(
        text: h?['price_per_night']?.toString() ?? '');
    _ratingCtrl = TextEditingController(
        text: h?['review_score']?.toString() ?? '');
    _phoneCtrl =
        TextEditingController(text: h?['contact_phone'] ?? '');
    _hotelType = h?['hotel_type'] ?? 'hotel';
    _starRating = (h?['star_rating'] ?? 3.0).toDouble();
  _isSponsored = h?['is_sponsored'] ?? false;
_bonusScore = (h?['bonus_score'] ?? 5.0).toDouble().clamp(1.0, 10.0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _iataCtrl.dispose();
    _priceCtrl.dispose();
    _ratingCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'name': _nameCtrl.text,
      'city_name': _cityCtrl.text,
      'destination_iata': _iataCtrl.text.toUpperCase(),
      'price_per_night': double.parse(_priceCtrl.text),
      'review_score': double.parse(_ratingCtrl.text),
      'contact_phone': _phoneCtrl.text,
      'hotel_type': _hotelType,
      'star_rating': _starRating,
     'is_active': true,
'is_partner': true,
'commission_rate': 0.12,
'is_sponsored': _isSponsored,
'bonus_score': _isSponsored ? _bonusScore : 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.hotel != null ? '✏️ Oteli Düzenle' : '➕ Yeni Otel Ekle',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Otel Adı', 'Örn: Kaleiçi Butik'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(_cityCtrl, 'Şehir', 'Örn: Antalya')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(_iataCtrl, 'IATA Kodu', 'AYT',
                          maxLength: 3)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(_priceCtrl, 'Gecelik Fiyat (TL)',
                          '850',
                          isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(
                          _ratingCtrl, 'Puan (0-10)', '8.5',
                          isNumber: true)),
                ],
              ),
              const SizedBox(height: 10),
              _field(_phoneCtrl, 'Telefon', '+90 242 xxx xx xx'),
              const SizedBox(height: 10),
              // Otel tipi
              const Text('Otel Tipi',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _hotelTypes.map((type) {
                  final isSelected = _hotelType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _hotelType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accent
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Yıldız sayısı
              const Text('Yıldız Sayısı',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
              Slider(
                value: _starRating,
                min: 1,
                max: 5,
                divisions: 4,
                label: '${_starRating.toInt()} yıldız',
                activeColor: AppTheme.accent,
                onChanged: (v) => setState(() => _starRating = v),
              ),
              const SizedBox(height: 10),
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sponsorlu Listeleme',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Text(
            '+5 bonus puan, En İyi Seçim rozeti',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    ),
    Switch(
      value: _isSponsored,
      onChanged: (v) => setState(() => _isSponsored = v),
      activeColor: const Color(0xFFFFD700),
    ),
  ],
),
if (_isSponsored) ...[
  const SizedBox(height: 8),
  Row(
    children: [
      const Text('Bonus Puan:', style: TextStyle(fontSize: 12)),
      Expanded(
        child: Slider(
          value: _bonusScore,
          min: 1,
          max: 10,
          divisions: 9,
          label: '+${_bonusScore.toInt()} puan',
          activeColor: const Color(0xFFFFD700),
          onChanged: (v) => setState(() => _bonusScore = v),
        ),
      ),
      Text(
        '+${_bonusScore.toInt()}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFD700),
        ),
      ),
    ],
  ),
],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.hotel != null ? 'Güncelle' : 'Ekle',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumber = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          validator: (v) => v!.isEmpty ? '$label zorunlu' : null,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.accent),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
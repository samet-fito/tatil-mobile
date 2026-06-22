import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

/// İptal koşulları — checkout öncesi özet veya ödeme sonrası tam politika metni.
class CheckoutCancellationCard extends StatefulWidget {
  const CheckoutCancellationCard({
    super.key,
    required this.departureDate,
    required this.returnDate,
    required this.nights,
    this.showFlight = true,
    this.showHotel = true,
    this.postBooking = false,
    this.airline,
    this.hotelName,
    this.flightPriceTL = 0,
    this.hotelPriceTL = 0,
  });

  final DateTime departureDate;
  final DateTime returnDate;
  final int nights;
  final bool showFlight;
  final bool showHotel;
  final bool postBooking;
  final String? airline;
  final String? hotelName;
  final int flightPriceTL;
  final int hotelPriceTL;

  @override
  State<CheckoutCancellationCard> createState() => _CheckoutCancellationCardState();
}

class _CheckoutCancellationCardState extends State<CheckoutCancellationCard> {
  static const _months = [
    '',
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  DateTime get _flightFreeUntil =>
      widget.departureDate.subtract(const Duration(hours: 24));

  DateTime get _hotelFreeUntil {
    final cutoff = widget.departureDate.subtract(const Duration(days: 3));
    final now = DateTime.now();
    return cutoff.isBefore(now) ? now : cutoff;
  }

  String _fmtPrice(int tl) => tl > 0 ? PriceFormat.format(tl) : '—';

  @override
  Widget build(BuildContext context) {
    final items = <_CancelLine>[];
    if (widget.showFlight) {
      final free = DateTime.now().isBefore(_flightFreeUntil);
      items.add(
        _CancelLine(
          icon: CupertinoIcons.airplane,
          label: 'Uçuş iptali',
          value: free
              ? '${_fmt(_flightFreeUntil)} tarihine kadar ücretsiz iptal (havayolu koşulları geçerli)'
              : 'Kalkışa 24 saatten az kaldı — iptal koşulu havayoluna bağlı',
          tone: free ? _Tone.positive : _Tone.warning,
        ),
      );
    }
    if (widget.showHotel) {
      final free = DateTime.now().isBefore(_hotelFreeUntil);
      items.add(
        _CancelLine(
          icon: CupertinoIcons.house_fill,
          label: 'Otel iptali',
          value: free
              ? '${_fmt(_hotelFreeUntil)} tarihine kadar ücretsiz iptal (otel koşulları geçerli)'
              : 'Check-in\'e 3 günden az kaldı — iptal koşulu otele bağlı',
          tone: free ? _Tone.positive : _Tone.warning,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 16,
                color: AppTheme.teal.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'İptal koşulları',
                style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(_line),
          if (!widget.postBooking) ...[
            const SizedBox(height: 8),
            Text(
              'Kesin iptal tarihi ve kesinti tutarı ödeme onayından önce tekrar gösterilir.',
              style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.35),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'Rezervasyonunuz onaylandı. Aşağıdaki politikaları okuyabilir; iptal talebinde bu koşullar geçerlidir.',
              style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 8),
            if (widget.showFlight)
              _policyExpansion(
                title: 'Uçuş iptal politikası',
                icon: CupertinoIcons.airplane,
                paragraphs: _flightPolicyParagraphs(),
              ),
            if (widget.showHotel)
              _policyExpansion(
                title: 'Otel iptal politikası',
                icon: CupertinoIcons.house_fill,
                paragraphs: _hotelPolicyParagraphs(),
              ),
            _policyExpansion(
              title: 'Genel iade ve iptal koşulları',
              icon: CupertinoIcons.info_circle,
              paragraphs: _generalPolicyParagraphs(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _flightPolicyParagraphs() {
    final airline = widget.airline?.trim();
    final carrier = (airline != null && airline.isNotEmpty) ? airline : 'Havayolu';
    final free = DateTime.now().isBefore(_flightFreeUntil);
    final paid = _fmtPrice(widget.flightPriceTL);

    return [
      'Biletiniz $carrier tarifesiyle düzenlenmiştir.'
          '${paid != '—' ? ' Ödenen uçuş tutarı: $paid.' : ''}',
      if (free)
        '${_fmt(_flightFreeUntil)} tarihine kadar (kalkıştan en az 24 saat önce) iptal talebinde '
            'tam iade için başvurabilirsiniz. İade, bankanıza 5–14 iş günü içinde yansır.'
      else
        'Ücretsiz iptal süresi sona ermiştir. İptal veya tarih değişikliği bilet sınıfına bağlıdır; '
            'promosyon veya iptal edilemez tarifelerde iade yapılmayabilir.',
      'İade edilebilir tarifelerde havayolu idari kesintisi ve vergi farkı düşülebilir. '
          'Kesinti tutarı bilet sınıfına göre değişir; destek ekibimiz talebinizde net tutarı bildirir.',
      'İptal talebi: Profil → Rezervasyonlarım → bu seyahat kartı. '
          'Talep onayından sonra iade süreci başlatılır.',
    ];
  }

  List<String> _hotelPolicyParagraphs() {
    final hotel = widget.hotelName?.trim();
    final name = (hotel != null && hotel.isNotEmpty) ? hotel : 'Konaklama tesisiniz';
    final free = DateTime.now().isBefore(_hotelFreeUntil);
    final paid = _fmtPrice(widget.hotelPriceTL);
    final perNight = widget.hotelPriceTL > 0 && widget.nights > 0
        ? PriceFormat.format((widget.hotelPriceTL / widget.nights).round())
        : null;

    return [
      '$name için check-in: ${_fmt(widget.departureDate)}, check-out: ${_fmt(widget.returnDate)} '
          '(${widget.nights} gece).'
          '${paid != '—' ? ' Ödenen konaklama tutarı: $paid.' : ''}',
      if (free)
        '${_fmt(_hotelFreeUntil)} tarihine kadar (check-in\'den en az 3 gün önce) ücretsiz iptal '
            'talep edebilirsiniz.'
      else
        'Ücretsiz iptal süresi sona ermiştir. Geç iptallerde tesis politikasına göre ilk gece veya '
            'toplam konaklama bedelinin tamamı tahsil edilebilir.',
      if (perNight != null)
        'Geç iptal durumunda tahmini kesinti: en az bir gece ($perNight) veya tesisin no-show politikası.',
      'Otel iptalleri tesis onayına tabidir. Onay sonrası iade 5–14 iş günü içinde kartınıza yansır.',
    ];
  }

  List<String> _generalPolicyParagraphs() {
    return const [
      'Paket rezervasyonlarda uçuş ve otel iptalleri ayrı işlenir; toplam iade her iki sağlayıcının '
          'koşullarına göre hesaplanır.',
      'Kısmi iptal (yalnızca uçuş veya yalnızca otel) her zaman mümkün olmayabilir; destek ekibimiz '
          'rezervasyon numaranızla durumu kontrol eder.',
      'Seyahat sağlık sigortası aldıysanız iptal güvencesi poliçe şartlarına tabidir; poliçe metni '
          'ödeme sırasında onayladığınız koşullarda yer alır.',
      'İptal ve iade taleplerinde haksız kullanım veya sahte bilgi tespitinde işlem reddedilebilir.',
    ];
  }

  Widget _policyExpansion({
    required String title,
    required IconData icon,
    required List<String> paragraphs,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        iconColor: AppTheme.teal,
        collapsedIconColor: AppTheme.textMuted,
        leading: Icon(icon, size: 18, color: AppTheme.teal),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        children: paragraphs
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  p,
                  style: TatilTheme.hint.copyWith(
                    fontSize: 12,
                    height: 1.45,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _line(_CancelLine item) {
    final color = switch (item.tone) {
      _Tone.positive => AppTheme.teal,
      _Tone.warning => AppTheme.orange,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tone { positive, warning }

class _CancelLine {
  const _CancelLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final _Tone tone;
}

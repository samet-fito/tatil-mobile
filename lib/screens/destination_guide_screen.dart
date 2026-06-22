import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/personalized_guide_model.dart';
import '../models/smart_travel_advisor_model.dart';
import '../services/api_service.dart';
import '../services/smart_travel_advisor_service.dart';
import '../services/travel_guide_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/traveler_group_profile.dart';
import '../widgets/advisor_insights_sections.dart';
import '../widgets/destination_hero_image.dart';
import '../widgets/hero_page_scroll.dart';
import '../widgets/holiday_type_match_hint.dart';
import 'commission_activities_screen.dart';

/// Post-booking seyahat rehberi — hava, kurallar, hayati uyarılar, ipuçları.
class DestinationGuideScreen extends StatefulWidget {
  const DestinationGuideScreen({
    super.key,
    required this.cityName,
    required this.country,
    required this.destinationIata,
    required this.departureDate,
    required this.returnDate,
    required this.nights,
    required this.adults,
    required this.children,
    this.passengerAges = const [],
    this.hotelName,
    this.reservationId,
    this.previewMode = false,
    this.groupProfileLabel,
    this.holidayTypes = const [],
  });

  final String cityName;
  final String country;
  final String destinationIata;
  final DateTime departureDate;
  final DateTime returnDate;
  final int nights;
  final int adults;
  final int children;
  final List<int> passengerAges;
  final String? hotelName;
  final String? reservationId;
  final bool previewMode;
  final String? groupProfileLabel;
  final List<String> holidayTypes;

  @override
  State<DestinationGuideScreen> createState() => _DestinationGuideScreenState();
}

class _DestinationGuideScreenState extends State<DestinationGuideScreen> {
  PersonalizedGuide? _guide;
  SmartTravelAdvisorResponse? _advisor;
  Map<String, dynamic>? _activitiesData;
  bool _loading = true;
  String? _error;
  bool _forceRefreshNext = false;

  TravelerGroupProfile get _groupProfile => TravelerGroupProfile.from(
        adults: widget.adults,
        children: widget.children,
        passengerAges: widget.passengerAges,
      );

  String get _groupLabel =>
      widget.groupProfileLabel ?? _groupProfile.summaryLabel;

  @override
  void initState() {
    super.initState();
    if (!widget.previewMode) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadAdvisor() async {
    try {
      final advisor = await SmartTravelAdvisorService.fetchDiscovery(
        destinationIata: widget.destinationIata,
        cityName: widget.cityName,
        country: widget.country,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        nights: widget.nights,
        adults: widget.adults,
        children: widget.children,
        passengerAges: widget.passengerAges,
      );
      if (!mounted) return;
      setState(() => _advisor = advisor);
    } catch (_) {}
  }

  Future<void> _openTicketUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı')),
      );
    }
  }

  Future<void> _load() async {
    if (!widget.previewMode) _loadAdvisor();

    final localGuide = TravelGuideService.buildLocalGuide(
      cityName: widget.cityName,
      country: widget.country,
      destinationIata: widget.destinationIata,
      nights: widget.nights,
      adults: widget.adults,
      children: widget.children,
      passengerAges: widget.passengerAges,
      holidayTypes: widget.holidayTypes,
    );

    setState(() {
      _guide = localGuide;
      _loading = false;
      _error = null;
    });

    final dep = widget.departureDate.toIso8601String().split('T').first;
    final ret = widget.returnDate.toIso8601String().split('T').first;

    PersonalizedGuide? guide;
    Map<String, dynamic>? activities;

    try {
      final results = await Future.wait([
        TravelGuideService.load(
          cityName: widget.cityName,
          country: widget.country,
          destinationIata: widget.destinationIata,
          departureDate: widget.departureDate,
          returnDate: widget.returnDate,
          nights: widget.nights,
          adults: widget.adults,
          children: widget.children,
          passengerAges: widget.passengerAges,
          hotelName: widget.hotelName,
          reservationId: widget.reservationId,
          forceRefresh: _forceRefreshNext,
          holidayTypes: widget.holidayTypes,
        ),
        ApiService.getCommissionActivities(
          iata: widget.destinationIata,
          cityName: widget.cityName,
          departure: dep,
          returnDate: ret,
        ).then((r) {
          if (r['success'] == true && r['data'] != null) {
            return r['data'] as Map<String, dynamic>;
          }
          return null;
        }).catchError((_) => null),
      ]);

      guide = results[0] as PersonalizedGuide?;
      activities = results[1] as Map<String, dynamic>?;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _guide = guide ?? _guide;
      _activitiesData = activities;
      _forceRefreshNext = false;
      if (_guide == null || _guide!.isEmpty) {
        _error = 'Rehber yüklenemedi. Lütfen tekrar deneyin.';
      }
    });
  }

  void _retry() {
    setState(() => _forceRefreshNext = true);
    _load();
  }

  void _openActivities() {
    if (_activitiesData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommissionActivitiesScreen(data: _activitiesData!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: HeroPageScroll(
        title: widget.previewMode ? null : 'Seyahat rehberiniz',
        expandedHeight: 180,
        hero: Stack(
          fit: StackFit.expand,
          children: [
            DestinationHeroImage(iataCode: widget.destinationIata),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.previewMode)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Ödeme sonrası açılır',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    widget.cityName,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.country} · ${widget.nights} gece',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  if (!widget.previewMode) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _groupLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        slivers: [
          if (widget.previewMode)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _previewTeaser(),
                ]),
              ),
            )
          else if (_loading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      '${_groupProfile.groupType.label} için kişisel rehber hazırlanıyor…',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _groupLabel,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _retry,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (widget.holidayTypes.isNotEmpty) ...[
                    const HolidayTypeMatchHint(),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    _guide!.headline,
                    style: TatilTheme.sectionLabel.copyWith(fontSize: 18),
                  ),
                  if (_guide!.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _guide!.subtitle,
                      style: TatilTheme.hint.copyWith(height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_guide!.weather != null) _weatherCard(_guide!.weather!),
                  ..._guide!.sections.map(_sectionCard),
                  if (_advisor != null) ...[
                    const SizedBox(height: 8),
                    AdvisorInsightsSections(
                      advisor: _advisor!,
                      onOpenTicketUrl: _openTicketUrl,
                    ),
                  ],
                  if (_activitiesData != null) ...[
                    const SizedBox(height: 8),
                    _activitiesCta(),
                  ],
                  const SizedBox(height: 16),
                  _disclaimer(_guide!.disclaimer),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewTeaser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.cityName}\'da ne yapmalısın?',
          style: TatilTheme.sectionLabel.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Ödeme tamamlandığında kişisel seyahat rehberin hazır olacak.',
          style: TatilTheme.hint.copyWith(height: 1.45),
        ),
        const SizedBox(height: 20),
        _teaserRow('🌤️', 'Seyahat tarihlerindeki hava durumu ve giyim önerisi'),
        _teaserRow('🎯', 'Mutlaka yapılacaklar listesi'),
        _teaserRow('⚠️', 'Uyulması gereken keskin kurallar'),
        _teaserRow('🆘', 'Hayat kurtaran tavsiyeler (çöl safarisi, sıcak, dolandırıcılık)'),
        _teaserRow('🎒', 'Valiz & ekipman checklist'),
        _teaserRow('💡', 'Yerel seyahat ipuçları'),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
          ),
          child: Text(
            'Rehber yapay zeka ile destinasyonunuza özel üretilir ve Seyahat Kartınızda saklanır.',
            style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _teaserRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherCard(TripWeatherSummary weather) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90D9).withValues(alpha: 0.12),
            AppTheme.teal.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🌤️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Hava durumu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weather.summaryLine,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (weather.clothingHint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              weather.clothingHint,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          if (weather.days.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weather.days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = weather.days[i];
                  return Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _shortDate(day.date),
                          style: TatilTheme.hint.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.highC.round()}°',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          day.label,
                          style: TatilTheme.hint.copyWith(fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard(PersonalizedGuideSection section) {
    final style = _sectionStyle(section.kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(section.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: style.titleColor,
                  ),
                ),
              ),
              if (style.icon != null)
                Icon(style.icon, size: 16, color: style.titleColor),
            ],
          ),
          const SizedBox(height: 10),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.bullet,
                    style: TextStyle(
                      color: style.bulletColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Widget _disclaimer(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.4),
    );
  }

  Widget _activitiesCta() {
    return GestureDetector(
      onTap: _openActivities,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.orangeSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.ticket, color: AppTheme.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.cityName} aktiviteleri',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Tur ve deneyimleri incele, rezerve et',
                    style: TatilTheme.hint.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppTheme.orange,
            ),
          ],
        ),
      ),
    );
  }

  _SectionStyle _sectionStyle(GuideSectionKind kind) {
    switch (kind) {
      case GuideSectionKind.groupProfile:
        return _SectionStyle(
          background: AppTheme.orange.withValues(alpha: 0.08),
          border: AppTheme.orange.withValues(alpha: 0.25),
          titleColor: AppTheme.orange,
          bulletColor: AppTheme.orange,
          bullet: '· ',
          icon: CupertinoIcons.person_2_fill,
        );
      case GuideSectionKind.interests:
        return _SectionStyle(
          background: AppTheme.teal.withValues(alpha: 0.08),
          border: AppTheme.teal.withValues(alpha: 0.25),
          titleColor: AppTheme.teal,
          bulletColor: AppTheme.teal,
          bullet: '· ',
          icon: CupertinoIcons.bag_fill,
        );
      case GuideSectionKind.strictRules:
        return const _SectionStyle(
          background: Color(0xFFFFF5F5),
          border: Color(0xFFFECACA),
          titleColor: Color(0xFFB91C1C),
          bulletColor: Color(0xFFDC2626),
          bullet: '✕ ',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
        );
      case GuideSectionKind.lifeSavers:
        return const _SectionStyle(
          background: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
          titleColor: Color(0xFFB45309),
          bulletColor: Color(0xFFD97706),
          bullet: '⚡ ',
          icon: CupertinoIcons.shield_fill,
        );
      case GuideSectionKind.packing:
        return _SectionStyle(
          background: AppTheme.teal.withValues(alpha: 0.06),
          border: AppTheme.teal.withValues(alpha: 0.2),
          titleColor: AppTheme.teal,
          bulletColor: AppTheme.teal,
          bullet: '· ',
        );
      case GuideSectionKind.mustDo:
        return const _SectionStyle(
          background: AppTheme.bgSecondary,
          border: AppTheme.border,
          titleColor: AppTheme.textPrimary,
          bulletColor: AppTheme.teal,
          bullet: '· ',
        );
      case GuideSectionKind.localTips:
      case GuideSectionKind.other:
        return const _SectionStyle(
          background: AppTheme.bgSecondary,
          border: AppTheme.border,
          titleColor: AppTheme.textPrimary,
          bulletColor: AppTheme.textMuted,
          bullet: '· ',
        );
    }
  }
}

class _SectionStyle {
  const _SectionStyle({
    required this.background,
    required this.border,
    required this.titleColor,
    required this.bulletColor,
    required this.bullet,
    this.icon,
  });

  final Color background;
  final Color border;
  final Color titleColor;
  final Color bulletColor;
  final String bullet;
  final IconData? icon;
}

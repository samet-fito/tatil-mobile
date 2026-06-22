import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/commission_activities.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../utils/activity_booking_briefing.dart';
import '../utils/app_navigation.dart';
import '../utils/price_format.dart';
import 'commission_activities_screen.dart';

/// Yalnızca aktivite / etkinlik rezervasyonu sonrası ekran.
class ActivityBookingSuccessScreen extends StatefulWidget {
  const ActivityBookingSuccessScreen({
    super.key,
    required this.activity,
    required this.cityName,
    required this.destinationIata,
    required this.reservationId,
    required this.passengerName,
    required this.passengerEmail,
    required this.totalPrice,
    required this.eventDate,
    this.activityCategory = 'tours',
    this.passengers = 1,
  });

  final Map<String, dynamic> activity;
  final String cityName;
  final String destinationIata;
  final String reservationId;
  final String passengerName;
  final String passengerEmail;
  final int totalPrice;
  final DateTime eventDate;
  final String activityCategory;
  final int passengers;

  @override
  State<ActivityBookingSuccessScreen> createState() =>
      _ActivityBookingSuccessScreenState();
}

class _ActivityBookingSuccessScreenState
    extends State<ActivityBookingSuccessScreen> {
  Map<String, dynamic>? _otherActivities;
  bool _loadingOthers = true;

  late final ActivityBookingBriefing _briefing =
      ActivityBookingBriefing.fromActivity(
    activity: widget.activity,
    cityName: widget.cityName,
    category: widget.activityCategory,
    eventDate: widget.eventDate,
  );

  @override
  void initState() {
    super.initState();
    _loadOtherActivities();
  }

  Future<void> _loadOtherActivities() async {
    final dep = widget.eventDate.toIso8601String().split('T')[0];
    final ret = widget.eventDate
        .add(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];
    try {
      final result = await ApiService.getCommissionActivities(
        iata: widget.destinationIata,
        cityName: widget.cityName,
        departure: dep,
        returnDate: ret,
      );
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _otherActivities = Map<String, dynamic>.from(result['data'] as Map);
          _loadingOthers = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingOthers = false);
  }

  String get _title => widget.activity['title'] as String? ?? 'Aktivite';
  String get _duration => widget.activity['duration'] as String? ?? '—';

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  void _goHome() => AppNavigation.openExploreTab(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: AppTheme.textPrimary),
          onPressed: _goHome,
        ),
        title: Text(
          'Rezervasyon Tamamlandı',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildConfirmationCard(),
                  const SizedBox(height: 16),
                  _buildActivityHeroCard(),
                  const SizedBox(height: 16),
                  _buildBriefingSection(
                    icon: CupertinoIcons.doc_text,
                    title: 'Etkinlik içeriği',
                    body: _briefing.program,
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleCard(),
                  const SizedBox(height: 12),
                  _buildBulletSection(
                    icon: CupertinoIcons.checkmark_shield,
                    title: 'Kurallar',
                    items: _briefing.rules,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(height: 12),
                  _buildBulletSection(
                    icon: CupertinoIcons.bag,
                    title: 'Kıyafet önerileri',
                    items: _briefing.clothingTips,
                    color: AppTheme.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildBulletSection(
                    icon: CupertinoIcons.exclamationmark_triangle,
                    title: 'Önemli uyarılar',
                    items: _briefing.warnings,
                    color: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 20),
                  _buildOtherActivities(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.ticket_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ETKİNLİK ONAYLANDI',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        widget.reservationId,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E4E9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Column(
              children: [
                _row('Katılımcı', widget.passengerName),
                if (widget.passengerEmail.isNotEmpty)
                  _row('E-posta', widget.passengerEmail),
                _row('Etkinlik tarihi', _formatDate(widget.eventDate)),
                _row('Süre', _duration),
                _row('Kişi', '${widget.passengers}'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam Ödenen',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  PriceFormat.format(widget.totalPrice),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.orange.withValues(alpha: 0.14),
            AppTheme.teal.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.cityName} · $_duration',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.clock, color: AppTheme.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Alınış & bırakılış',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _scheduleRow('Alınış', _briefing.pickupTime, CupertinoIcons.arrow_up_circle),
          const SizedBox(height: 10),
          _scheduleRow('Bırakılış', _briefing.dropoffTime, CupertinoIcons.arrow_down_circle),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(CupertinoIcons.location_solid, size: 16, color: AppTheme.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buluşma noktası',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _briefing.meetingPoint,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(String label, String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        const Spacer(),
        Text(
          time,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildBriefingSection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4),
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

  Widget _buildOtherActivities() {
    final bookedTitle = _title.toLowerCase();
    final others = _otherActivities == null
        ? <Map<String, dynamic>>[]
        : CommissionActivities.flatActivities(_otherActivities!)
            .where((a) => (a['title'] as String? ?? '').toLowerCase() != bookedTitle)
            .take(5)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diğer aktiviteler',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.cityName} — ilginizi çekebilecek deneyimler',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        if (_loadingOthers)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTheme.orange, strokeWidth: 2),
            ),
          )
        else if (others.isEmpty)
          Text(
            'Şu an başka öneri yüklenemedi.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
          )
        else
          ...others.map(_otherActivityTile),
        if (_otherActivities != null && others.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => pushAppRoute(
              context,
              CommissionActivitiesScreen(data: _otherActivities!),
            ),
            child: const Text('Tüm aktiviteleri gör'),
          ),
        ],
      ],
    );
  }

  Widget _otherActivityTile(Map<String, dynamic> act) {
    final price = (act['priceTL'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act['title'] as String? ?? '',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  act['duration'] as String? ?? '—',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (price > 0)
            Text(
              PriceFormat.format(price),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_title biletiniz e-posta / SMS ile gönderilecek.'),
                      backgroundColor: AppTheme.orange,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Dijital biletim',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            TextButton(onPressed: _goHome, child: const Text('Keşfet\'e dön')),
          ],
        ),
      ),
    );
  }
}

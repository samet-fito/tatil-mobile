import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/consumer_copy.dart';

enum LoadingPhase { routes, spending }

class _ScatteredTip {
  const _ScatteredTip(this.text, this.align, this.topFactor, this.leftFactor);

  final String text;
  final TextAlign align;
  final double topFactor;
  final double leftFactor;
}

/// Rota arama beklerken — animasyonsuz, asimetrik seyahat ipuçları.
class LoadingScreen extends StatefulWidget {
  final LoadingPhase phase;
  final String? destinationIata;

  const LoadingScreen({
    super.key,
    this.phase = LoadingPhase.routes,
    this.destinationIata,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _tips = [
    _ScatteredTip(
      'Pasaportunuzun dönüşten sonra en az 6 ay geçerli olduğunu kontrol edin.',
      TextAlign.left,
      0.08,
      0.06,
    ),
    _ScatteredTip(
      'Havalimanına en az 2–3 saat önce gidin; check-in ve güvenlik süresi değişebilir.',
      TextAlign.right,
      0.18,
      0.22,
    ),
    _ScatteredTip(
      'Nakit para ve yedek kartı ayrı çantada taşıyın — kayıp riskine karşı.',
      TextAlign.left,
      0.30,
      0.04,
    ),
    _ScatteredTip(
      'Seyahat sigortası acil sağlık ve bagaj kaybında işinizi kolaylaştırır.',
      TextAlign.center,
      0.42,
      0.12,
    ),
    _ScatteredTip(
      'Otel adresini ve rezervasyon numaranızı telefonda çevrimdışı saklayın.',
      TextAlign.right,
      0.54,
      0.08,
    ),
    _ScatteredTip(
      'İlaçlarınızı orijinal kutusunda ve reçete kopyasıyla yanınıza alın.',
      TextAlign.left,
      0.66,
      0.18,
    ),
    _ScatteredTip(
      'Gidiş-dönüş uçuş saatlerini yerel saat dilimine göre tekrar kontrol edin.',
      TextAlign.right,
      0.76,
      0.05,
    ),
    _ScatteredTip(
      'Fiyatlar bilgilendirme amaçlıdır; kesin tutar onay adımında doğrulanır.',
      TextAlign.center,
      0.86,
      0.10,
    ),
  ];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  Timer? _revealTimer;
  int _visibleTips = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
    _revealTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
      if (!mounted) return;
      if (_visibleTips >= _tips.length) return;
      setState(() => _visibleTips++);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _title => widget.phase == LoadingPhase.routes
      ? 'Rotalar hazırlanıyor'
      : 'Harcama verileri hazırlanıyor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: TatilTheme.screenHeadline(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(
                      widget.phase == LoadingPhase.routes
                          ? ConsumerCopy.loadingMerge
                          : 'Tatil bütçeniz için tahminler hesaplanıyor',
                      style: TatilTheme.bodyMuted.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.orange.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Seyahat ipuçları',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < _visibleTips && i < _tips.length; i++)
                          _tipBubble(
                            tip: _tips[i],
                            index: i,
                            maxWidth: w,
                            maxHeight: h,
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Text(
                  'İpuçları genel bilgilendirme içindir; resmi kurallar için '
                  'havayolu, otel ve konsolosluk duyurularını kontrol edin.',
                  textAlign: TextAlign.center,
                  style: TatilTheme.hint.copyWith(fontSize: 10, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipBubble({
    required _ScatteredTip tip,
    required int index,
    required double maxWidth,
    required double maxHeight,
  }) {
    final bubbleW = math.min(maxWidth * 0.72, 280.0);
    final left = (maxWidth - bubbleW) * tip.leftFactor;
    final top = maxHeight * tip.topFactor;

    return Positioned(
      left: left.clamp(8.0, maxWidth - bubbleW - 8),
      top: top.clamp(0.0, maxHeight - 72),
      width: bubbleW,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(index),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            tip.text,
            textAlign: tip.align,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.38,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

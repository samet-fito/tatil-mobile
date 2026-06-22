import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/search_category.dart';
import '../theme/tatil_theme.dart';
import 'login_background_pattern.dart';

/// Keşfet üst bölümü — sade başlık + katlanabilir kategori kartı.
class ExploreTopSection extends StatefulWidget {
  const ExploreTopSection({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onSearchTap,
  });

  final SearchCategory selected;
  final ValueChanged<SearchCategory> onSelected;
  final VoidCallback? onSearchTap;

  @override
  State<ExploreTopSection> createState() => _ExploreTopSectionState();
}

class _ExploreTopSectionState extends State<ExploreTopSection>
    with SingleTickerProviderStateMixin {
  static const _row1 = [
    SearchCategory.flight,
    SearchCategory.hotel,
    SearchCategory.bus,
    SearchCategory.packageTour,
  ];

  static const _row2 = [
    SearchCategory.carRental,
    SearchCategory.transfer,
    SearchCategory.activities,
  ];

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() => _expanded = value);
    if (value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _toggleExpanded() => _setExpanded(!_expanded);

  void _selectCategory(SearchCategory category) {
    widget.onSelected(category);
    _setExpanded(false);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(child: LoginBackgroundPattern()),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 6, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Keşfet',
                        style: TatilTheme.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onSearchTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                    child: _SelectedCategoryHint(category: widget.selected),
                  ),
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: _expandAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                for (var i = 0; i < _row1.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(
                                    child: _CategoryTile(
                                      category: _row1[i],
                                      isSelected: widget.selected == _row1[i],
                                      onTap: () => _selectCategory(_row1[i]),
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (var i = 0; i < _row2.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(
                                    child: _CategoryTile(
                                      category: _row2[i],
                                      isSelected: widget.selected == _row2[i],
                                      onTap: () => _selectCategory(_row2[i]),
                                      compact: false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                  ),
                  _CategoryPanelHandle(
                    expanded: _expanded,
                    onTap: _toggleExpanded,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _CategoryPanelHandle extends StatelessWidget {
  const _CategoryPanelHandle({
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                  color: TatilTheme.orange.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedCategoryHint extends StatelessWidget {
  const _SelectedCategoryHint({required this.category});

  final SearchCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TatilTheme.orangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(category.icon, size: 18, color: TatilTheme.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.headerSubtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TatilTheme.textDark,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.compact,
  });

  final SearchCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 36.0 : 38.0;
    final fontSize = compact ? 10.0 : 9.5;
    final maxLines = category == SearchCategory.activities ? 2 : 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 6,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? TatilTheme.orange.withValues(alpha: 0.1)
                : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? TatilTheme.orange : const Color(0xFFE6E8EC),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: isSelected ? TatilTheme.orange : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? TatilTheme.orange : Colors.black)
                          .withValues(alpha: isSelected ? 0.28 : 0.06),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  category.icon,
                  size: compact ? 19 : 20,
                  color: isSelected ? Colors.white : TatilTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.gridLabel,
                textAlign: TextAlign.center,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? TatilTheme.orange : TatilTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

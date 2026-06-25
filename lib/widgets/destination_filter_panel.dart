import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/destination_filter_state.dart';
import '../theme/app_theme.dart';

/// RouteVS tarzı 3 katmanlı gelişmiş filtre bottom sheet.
class DestinationFilterPanel extends StatelessWidget {
  const DestinationFilterPanel({
    super.key,
    required this.state,
    this.showRegion = true,
    this.onApply,
    this.onClear,
    this.extraSections = const [],
  });

  final DestinationFilterState state;
  final bool showRegion;
  final VoidCallback? onApply;
  final VoidCallback? onClear;
  final List<Widget> extraSections;

  static Future<void> show(
    BuildContext context, {
    required DestinationFilterState state,
    bool showRegion = true,
    VoidCallback? onApply,
    VoidCallback? onClear,
    List<Widget> extraSections = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: state,
        builder: (_, __) => DestinationFilterPanel(
          state: state,
          showRegion: showRegion,
          extraSections: extraSections,
          onApply: () {
            onApply?.call();
            Navigator.pop(ctx);
          },
          onClear: () {
            state.clearAll();
            onClear?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Gelişmiş filtreler',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (state.activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${state.activeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Temizle'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  if (showRegion) ...[
                    _sectionTitle('REGION', 'Bölge'),
                    const SizedBox(height: 10),
                    _chipWrap(
                      DestinationFilterState.regionOptions,
                      selected: state.regions,
                      onToggle: state.toggleRegion,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _sectionTitle('TRAVEL STYLE', 'Seyahat stili'),
                  const SizedBox(height: 10),
                  _chipWrap(
                    DestinationFilterState.travelStyleOptions,
                    selected: state.travelStyles,
                    onToggle: state.toggleTravelStyle,
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('COST', 'Bütçe'),
                  const SizedBox(height: 10),
                  _chipWrap(
                    DestinationFilterState.costOptions,
                    selected: state.costTiers,
                    onToggle: state.toggleCost,
                  ),
                  if (extraSections.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ...extraSections,
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    state.activeCount > 0
                        ? 'Filtreleri uygula (${state.activeCount})'
                        : 'Filtreleri uygula',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String en, String tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          en,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppTheme.purple,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tr,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _chipWrap(
    List<(String, String)> options, {
    required Set<String> selected,
    required void Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final id = opt.$1;
        final label = opt.$2;
        final isOn = selected.contains(id);
        return GestureDetector(
          onTap: () => onToggle(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isOn ? AppTheme.orange : Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isOn ? AppTheme.orange : AppTheme.border,
                width: isOn ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOn ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Yatay kaydırmalı hızlı filtre şeridi (GetYourGuide tarzı).
class ActivityFilterChipBar extends StatelessWidget {
  const ActivityFilterChipBar({
    super.key,
    required this.filterCount,
    required this.onOpenFilters,
    this.categoryChips = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  final int filterCount;
  final VoidCallback onOpenFilters;
  final List<(String id, String label)> categoryChips;
  final String? selectedCategory;
  final void Function(String? id)? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterIconChip(
            badge: filterCount,
            onTap: onOpenFilters,
          ),
          const SizedBox(width: 8),
          ...categoryChips.map((c) {
            final selected = selectedCategory == c.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TextChip(
                label: c.$2,
                selected: selected,
                onTap: () => onCategorySelected?.call(
                  selected ? null : c.$1,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterIconChip extends StatelessWidget {
  const _FilterIconChip({required this.badge, required this.onTap});

  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(CupertinoIcons.slider_horizontal_3, size: 20),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.fuchsia,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  const _TextChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.orange : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.orange : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

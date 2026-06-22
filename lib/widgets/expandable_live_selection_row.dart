import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/selection_detail_resolver.dart';
import 'live_selection_row.dart';

/// Özet satır + açılır detay paneli (before.click — bilgi, satış yok).
class ExpandableLiveSelectionRow extends StatefulWidget {
  const ExpandableLiveSelectionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.priceSecondaryLabel,
    this.loading = false,
    this.onChange,
    this.details = const [],
    this.detailsTitle = 'Detaylar',
    this.sourceIsLive = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String priceLabel;
  final String? priceSecondaryLabel;
  final bool loading;
  final VoidCallback? onChange;
  final List<SelectionDetailLine> details;
  final String detailsTitle;
  final bool sourceIsLive;

  @override
  State<ExpandableLiveSelectionRow> createState() =>
      _ExpandableLiveSelectionRowState();
}

class _ExpandableLiveSelectionRowState extends State<ExpandableLiveSelectionRow> {
  bool _expanded = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails = widget.details.isNotEmpty && !widget.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiveSelectionRow(
          icon: widget.icon,
          iconColor: widget.iconColor,
          title: widget.title,
          subtitle: widget.subtitle,
          priceLabel: widget.priceLabel,
          priceSecondaryLabel: widget.priceSecondaryLabel,
          loading: widget.loading,
          onChange: widget.onChange,
          sourceIsLive: widget.sourceIsLive,
        ),
        if (hasDetails) ...[
          Material(
            color: AppTheme.bgTertiary,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _expanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 14,
                          color: AppTheme.teal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _expanded ? 'Detayları gizle' : widget.detailsTitle,
                          style: TatilTheme.hint.copyWith(
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 10),
                      ...widget.details.map(_detailTile),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailTile(SelectionDetailLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
                if (line.actionLabel != null && line.actionUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: () => _openUrl(line.actionUrl!),
                      child: Text(
                        line.actionLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.teal,
                        ),
                      ),
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

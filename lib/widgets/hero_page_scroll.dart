import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hero görseli + kaydırınca okunabilir üst bar (açık arka plan / koyu metin).
class HeroPageScroll extends StatefulWidget {
  const HeroPageScroll({
    super.key,
    this.title,
    required this.expandedHeight,
    required this.hero,
    required this.slivers,
  });

  final String? title;
  final double expandedHeight;
  final Widget hero;
  final List<Widget> slivers;

  @override
  State<HeroPageScroll> createState() => _HeroPageScrollState();
}

class _HeroPageScrollState extends State<HeroPageScroll> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final collapseAt = widget.expandedHeight - kToolbarHeight - topPad;
    final fg = _collapsed ? AppTheme.textPrimary : Colors.white;
    final barBg = _collapsed ? AppTheme.bgSecondary : Colors.transparent;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0) return false;
        final collapsed = notification.metrics.pixels >= collapseAt - 2;
        if (collapsed != _collapsed) {
          setState(() => _collapsed = collapsed);
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: widget.expandedHeight,
            pinned: true,
            elevation: _collapsed ? 0.5 : 0,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            backgroundColor: barBg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: fg,
            iconTheme: IconThemeData(color: fg),
            leading: IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: fg),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: widget.title == null || widget.title!.isEmpty
                ? null
                : Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.hero,
                  if (!_collapsed)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topPad + kToolbarHeight + 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ...widget.slivers,
        ],
      ),
    );
  }
}

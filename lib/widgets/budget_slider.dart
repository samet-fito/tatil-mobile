import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BudgetSlider extends StatefulWidget {
  final double value;
  final double maxValue;
  final Function(double) onChanged;
  final bool isHealthMode;

  const BudgetSlider({
    super.key,
    required this.value,
    required this.maxValue,
    required this.onChanged,
    this.isHealthMode = false,
  });

  @override
  State<BudgetSlider> createState() => _BudgetSliderState();
}

class _BudgetSliderState extends State<BudgetSlider> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toInt().toString(),
    );
  }

  @override
  void didUpdateWidget(BudgetSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatBudget(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M TL';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K TL';
    return '${value.toInt()} TL';
  }

  String get _segmentLabel {
    if (widget.isHealthMode) return '🏥 Sağlık Turizmi';
    if (widget.value < 25000) return '💚 Ekonomik';
    if (widget.value < 60000) return '💙 Standart';
    return '💜 Premium';
  }

  Color get _segmentColor {
    if (widget.isHealthMode) return AppTheme.health;
    if (widget.value < 25000) return AppTheme.accent;
    if (widget.value < 60000) return Colors.blue;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isHealthMode
            ? AppTheme.healthLight
            : AppTheme.accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _segmentLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _segmentColor,
                ),
              ),
              // Manuel giriş alanı
              GestureDetector(
                onTap: () => setState(() => _isEditing = true),
                child: _isEditing
                    ? SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            suffix: const Text(' TL'),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          onSubmitted: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null && parsed >= 10000) {
                              widget.onChanged(parsed.clamp(10000, widget.maxValue));
                            }
                            setState(() => _isEditing = false);
                          },
                          onTapOutside: (_) {
                            final parsed = double.tryParse(_controller.text);
                            if (parsed != null && parsed >= 10000) {
                              widget.onChanged(parsed.clamp(10000, widget.maxValue));
                            }
                            setState(() => _isEditing = false);
                          },
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            _formatBudget(widget.value),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _segmentColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: _segmentColor.withOpacity(0.6),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _segmentColor,
              inactiveTrackColor: _segmentColor.withOpacity(0.2),
              thumbColor: _segmentColor,
              overlayColor: _segmentColor.withOpacity(0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: widget.value.clamp(10000, widget.maxValue),
              min: 10000,
              max: widget.maxValue,
              divisions: 100,
              onChanged: widget.onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10K TL', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(_formatBudget(widget.maxValue),
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
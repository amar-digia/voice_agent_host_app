import 'package:flutter/material.dart';

import '../models/market_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'sparkline.dart';

class PortfolioCard extends StatefulWidget {
  const PortfolioCard({
    super.key,
    required this.history,
    required this.invested,
  });

  final Map<ChartRange, List<double>> history;
  final double invested;

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  ChartRange _range = ChartRange.day;

  static String _rangeLabel(ChartRange range) => switch (range) {
    ChartRange.day => 'Today',
    ChartRange.week => 'Past week',
    ChartRange.month => 'Past month',
    ChartRange.year => 'Past year',
    ChartRange.all => 'All time',
  };

  @override
  Widget build(BuildContext context) {
    final points = widget.history[_range] ?? const <double>[];
    final value = points.isEmpty ? 0.0 : points.last;
    final change = points.isEmpty ? 0.0 : points.last - points.first;
    final changePercent = points.isEmpty ? 0.0 : change / points.first * 100;
    final returns = value - widget.invested;
    final returnsPercent = returns / widget.invested * 100;
    final changeColor = AppColors.forChange(change);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio value',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(value),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: changeColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${formatSignedCurrency(change)} (${formatPercent(changePercent)})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _rangeLabel(_range),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: Sparkline(
              points: points,
              color: changeColor,
              strokeWidth: 2,
              fill: true,
            ),
          ),
          const SizedBox(height: 12),
          _RangeSelector(
            selected: _range,
            onChanged: (range) => setState(() => _range = range),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Invested',
                  value: formatCurrency(widget.invested, decimals: 0),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Total returns',
                  value:
                      '${formatSignedCurrency(returns)} (${formatPercent(returnsPercent)})',
                  valueColor: AppColors.forChange(returns),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});

  final ChartRange selected;
  final ValueChanged<ChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final range in ChartRange.values)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: range == selected
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: range == selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

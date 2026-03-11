import 'package:flutter/material.dart';

import '../../domain/entities/signal.dart';
import '../theme/app_theme.dart';

class SignalStrengthBar extends StatelessWidget {
  final Signal signal;
  final bool compact;

  const SignalStrengthBar({
    super.key,
    required this.signal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBull = signal.action == SignalAction.buy;
    final isBear = signal.action == SignalAction.sell;

    final bars = <_IndicatorBar>[
      _IndicatorBar('EMA', signal.emaScore),
      _IndicatorBar('MACD', signal.macdScore),
      _IndicatorBar('RSI', signal.rsiScore),
      _IndicatorBar('BB', signal.bbScore),
      _IndicatorBar('VSA', signal.vsaScore),
    ];

    final activeCount = bars.where((b) => b.score != null).length;
    final bullCount = bars.where((b) => b.score == 1).length;
    final bearCount = bars.where((b) => b.score == -1).length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  signal.symbol,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  signal.timeframe,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
                const Spacer(),
                _ActionBadge(action: signal.action),
              ],
            ),
            const SizedBox(height: 10),

            // ── Strength bar ──────────────────────────────────────────────
            if (activeCount > 0) ...[
              Row(
                children: [
                  Text(
                    isBull
                        ? '$bullCount/$activeCount BULL'
                        : isBear
                            ? '$bearCount/$activeCount BEAR'
                            : '${signal.bullScore > signal.bearScore ? bullCount : bearCount}/$activeCount',
                    style: TextStyle(
                      color: isBull
                          ? kProfitColor
                          : isBear
                              ? kDangerColor
                              : kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isBull
                            ? bullCount / activeCount
                            : isBear
                                ? bearCount / activeCount
                                : 0,
                        backgroundColor: kDividerColor,
                        color: isBull
                            ? kProfitColor
                            : isBear
                                ? kDangerColor
                                : kTextSecondary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // ── Indicator dots ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bars.map((b) => _IndicatorDot(bar: b)).toList(),
            ),

            // ── VSA pattern line ──────────────────────────────────────────
            if (signal.vsaScore != null && signal.vsaPattern != 'Normal') ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: signal.vsaBullish == true
                      ? kProfitColor.withValues(alpha: 0.08)
                      : signal.vsaBullish == false
                          ? kDangerColor.withValues(alpha: 0.08)
                          : kSurfaceColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: signal.vsaBullish == true
                        ? kProfitColor.withValues(alpha: 0.3)
                        : signal.vsaBullish == false
                            ? kDangerColor.withValues(alpha: 0.3)
                            : kDividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      signal.vsaBullish == true
                          ? Icons.show_chart
                          : signal.vsaBullish == false
                              ? Icons.trending_down
                              : Icons.horizontal_rule,
                      size: 13,
                      color: signal.vsaBullish == true
                          ? kProfitColor
                          : signal.vsaBullish == false
                              ? kDangerColor
                              : kTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'VSA: ${signal.vsaPattern}',
                      style: TextStyle(
                        color: signal.vsaBullish == true
                            ? kProfitColor
                            : signal.vsaBullish == false
                                ? kDangerColor
                                : kTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (signal.vsaVolRatio != null) ...[
                      const Spacer(),
                      Text(
                        'Vol ${signal.vsaVolRatio!.toStringAsFixed(1)}x',
                        style: const TextStyle(color: kTextSecondary, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Indicator dot pill ─────────────────────────────────────────────────────
class _IndicatorDot extends StatelessWidget {
  final _IndicatorBar bar;
  const _IndicatorDot({required this.bar});

  @override
  Widget build(BuildContext context) {
    final disabled = bar.score == null;
    final score = bar.score ?? 0;

    Color dotColor;
    IconData dotIcon;

    if (disabled) {
      dotColor = kTextSecondary.withValues(alpha: 0.35);
      dotIcon = Icons.circle_outlined;
    } else if (score == 1) {
      dotColor = kProfitColor;
      dotIcon = Icons.arrow_upward;
    } else if (score == -1) {
      dotColor = kDangerColor;
      dotIcon = Icons.arrow_downward;
    } else {
      dotColor = kWarningColor;
      dotIcon = Icons.remove;
    }

    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor.withValues(alpha: disabled ? 0.08 : 0.15),
              border: Border.all(color: dotColor.withValues(alpha: disabled ? 0.2 : 0.6)),
            ),
            child: Icon(dotIcon, color: dotColor, size: 14),
          ),
          const SizedBox(height: 3),
          Text(
            bar.name,
            style: TextStyle(
              color: disabled ? kTextSecondary.withValues(alpha: 0.4) : kTextSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (disabled)
            const Text('OFF', style: TextStyle(color: kTextSecondary, fontSize: 8)),
        ],
      ),
    );
  }
}

class _IndicatorBar {
  final String name;
  final int? score; // null = disabled
  const _IndicatorBar(this.name, this.score);
}

class _ActionBadge extends StatelessWidget {
  final SignalAction action;
  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (action) {
      case SignalAction.buy:
        color = kProfitColor;
        text = '▲ BUY';
      case SignalAction.sell:
        color = kDangerColor;
        text = '▼ SELL';
      case SignalAction.none:
        color = kTextSecondary;
        text = '— HOLD';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

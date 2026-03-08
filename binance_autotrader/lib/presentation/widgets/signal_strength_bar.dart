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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                const Spacer(),
                _ActionBadge(action: signal.action),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BULL',
                        style: TextStyle(color: kProfitColor, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      _ScoreDots(score: signal.bullScore, maxScore: 4, color: kProfitColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BEAR',
                        style: TextStyle(color: kDangerColor, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      _ScoreDots(score: signal.bearScore, maxScore: 4, color: kDangerColor),
                    ],
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              _IndicatorRow(
                indicators: [
                  _IndicatorItem('EMA', signal.emaScore),
                  _IndicatorItem('MACD', signal.macdScore),
                  _IndicatorItem('RSI', signal.rsiScore),
                  _IndicatorItem('BB', signal.bbScore),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreDots extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color color;

  const _ScoreDots({
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxScore, (i) {
        final active = i < score;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 20,
            height: 8,
            decoration: BoxDecoration(
              color: active ? color : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final List<_IndicatorItem> indicators;

  const _IndicatorRow({required this.indicators});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: indicators.map((item) {
        Color color;
        IconData icon;
        if (item.score > 0) {
          color = kProfitColor;
          icon = Icons.arrow_upward;
        } else if (item.score < 0) {
          color = kDangerColor;
          icon = Icons.arrow_downward;
        } else {
          color = kTextSecondary;
          icon = Icons.remove;
        }
        return Column(
          children: [
            Text(
              item.name,
              style: const TextStyle(color: kTextSecondary, fontSize: 9),
            ),
            const SizedBox(height: 2),
            Icon(icon, size: 12, color: color),
          ],
        );
      }).toList(),
    );
  }
}

class _IndicatorItem {
  final String name;
  final int score;
  const _IndicatorItem(this.name, this.score);
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

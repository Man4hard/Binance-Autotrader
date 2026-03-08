import 'package:flutter/material.dart';

import '../../core/extensions/double_ext.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../domain/entities/trade.dart';
import '../theme/app_theme.dart';
import 'paper_badge.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final double? currentPrice;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const TradeCard({
    super.key,
    required this.trade,
    this.currentPrice,
    this.onClose,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = trade.status == TradeStatus.open;
    final price = currentPrice ?? trade.exitPrice ?? trade.entryPrice;
    final pnl = isOpen
        ? (trade.side == TradeSide.buy
            ? (price - trade.entryPrice) * trade.quantity
            : (trade.entryPrice - price) * trade.quantity)
        : (trade.realizedPnl ?? 0);
    final pnlColor = pnl >= 0 ? kProfitColor : kDangerColor;
    final sideColor = trade.side == TradeSide.buy ? kProfitColor : kDangerColor;
    final sideLabel = trade.side == TradeSide.buy ? 'LONG' : 'SHORT';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sideColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    sideLabel,
                    style: TextStyle(
                      color: sideColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trade.symbol,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  trade.timeframe,
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                const Spacer(),
                if (trade.isPaper) const PaperBadge(),
                if (showCloseButton && onClose != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kDangerColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kDangerColor.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: kDangerColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoItem(label: 'ENTRY', value: '\$${trade.entryPrice.toCurrencyString(decimals: 4)}'),
                const SizedBox(width: 16),
                _InfoItem(
                  label: isOpen ? 'CURRENT' : 'EXIT',
                  value: '\$${price.toCurrencyString(decimals: 4)}',
                ),
                const SizedBox(width: 16),
                _InfoItem(
                  label: 'P&L',
                  value: pnl.toSignedString(),
                  valueColor: pnlColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoItem(
                  label: 'SL',
                  value: '\$${trade.stopLoss.toCurrencyString(decimals: 4)}',
                  valueColor: kDangerColor,
                ),
                const SizedBox(width: 16),
                _InfoItem(
                  label: 'TP',
                  value: '\$${trade.takeProfit.toCurrencyString(decimals: 4)}',
                  valueColor: kProfitColor,
                ),
                const SizedBox(width: 16),
                _InfoItem(
                  label: 'QTY',
                  value: trade.quantity.toStringAsFixed(4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(
                  trade.openedAt.toDisplayString(),
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
                if (!isOpen && trade.closedAt != null) ...[
                  const Text(
                    ' → ',
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                  Text(
                    trade.openedAt.tradeDuration(trade.closedAt!),
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

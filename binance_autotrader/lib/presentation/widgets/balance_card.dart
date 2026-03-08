import 'package:flutter/material.dart';

import '../../core/extensions/double_ext.dart';
import '../theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double dailyPnl;
  final bool isPaper;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.dailyPnl,
    this.isPaper = true,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor = dailyPnl >= 0 ? kProfitColor : kDangerColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isPaper ? 'Paper Balance' : 'Live Balance',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isPaper)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kWarningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kWarningColor.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'PAPER',
                      style: TextStyle(
                        color: kWarningColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (onRefresh != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRefresh,
                    child: const Icon(Icons.refresh, size: 18, color: kTextSecondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const SizedBox(
                height: 36,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Text(
                '\$${balance.toCurrencyString()}',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  dailyPnl >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: pnlColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Today: ${dailyPnl.toSignedString()} USDT',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

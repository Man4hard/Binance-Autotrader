import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/double_ext.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/trade_card.dart';
import '../widgets/stat_chip.dart';
import '../widgets/balance_card.dart';

class PaperTradingScreen extends ConsumerWidget {
  const PaperTradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(strategySettingsProvider);
    final settings = settingsState.settings;
    final isPaper = settings.isPaperMode;
    final paperBalance = ref.watch(paperBalanceProvider);
    final activeTrades = ref.watch(activeTradesProvider);
    final historyState = ref.watch(tradeHistoryProvider);

    final paperHistory = historyState.trades.where((t) => t.isPaper).toList();
    final liveHistory = historyState.trades.where((t) => !t.isPaper).toList();

    final paperPnl = paperHistory.fold<double>(
        0.0, (sum, t) => sum + (t.realizedPnl ?? 0));
    final livePnl = liveHistory.fold<double>(
        0.0, (sum, t) => sum + (t.realizedPnl ?? 0));
    final paperWins =
        paperHistory.where((t) => (t.realizedPnl ?? 0) > 0).length;
    final liveWins = liveHistory.where((t) => (t.realizedPnl ?? 0) > 0).length;
    final paperWinRate = paperHistory.isEmpty
        ? 0.0
        : (paperWins / paperHistory.length) * 100;
    final liveWinRate =
        liveHistory.isEmpty ? 0.0 : (liveWins / liveHistory.length) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Trading'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SizedBox(height: 8),
          _ModeToggleCard(
            isPaper: isPaper,
            onToggle: (value) async {
              if (!value) {
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: '⚠️ Switch to LIVE Trading',
                  message:
                      'LIVE mode uses real funds from your Binance account.\n\n'
                      'Losses are real and not recoverable. Only proceed if you understand the risks and have configured your API keys.\n\n'
                      'This app targets \$10/day but cannot guarantee profits. Algorithmic trading carries significant risk.',
                  confirmLabel: 'I UNDERSTAND — GO LIVE',
                  cancelLabel: 'Stay in Paper Mode',
                  isDangerous: true,
                );
                if (!confirmed) return;
              }
              await ref
                  .read(strategySettingsProvider.notifier)
                  .togglePaperMode(value);
              if (context.mounted) {
                showSuccessSnackbar(
                  context,
                  value ? 'Switched to Paper Mode' : '🔴 Switched to LIVE Mode',
                );
              }
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BalanceCard(
              balance: paperBalance.value ?? 1000.0,
              dailyPnl: paperPnl,
              isPaper: true,
              isLoading: paperBalance.isLoading,
            ),
          ),
          const SizedBox(height: 16),
          if (paperHistory.isNotEmpty || liveHistory.isNotEmpty)
            _ComparisonCard(
              paperTrades: paperHistory.length,
              liveTrades: liveHistory.length,
              paperPnl: paperPnl,
              livePnl: livePnl,
              paperWinRate: paperWinRate,
              liveWinRate: liveWinRate,
            ),
          const SizedBox(height: 16),
          if (activeTrades.trades.where((t) => t.isPaper).isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Active Paper Positions',
                style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            ...activeTrades.trades
                .where((t) => t.isPaper)
                .map((t) => TradeCard(trade: t)),
          ],
          if (paperHistory.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Paper Trade History',
                style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            ...paperHistory.take(10).map((t) => TradeCard(trade: t)),
            if (paperHistory.length > 10)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Showing 10 of ${paperHistory.length} — see Trade History tab for all',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ModeToggleCard extends StatelessWidget {
  final bool isPaper;
  final ValueChanged<bool> onToggle;

  const _ModeToggleCard({required this.isPaper, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPaper
                      ? kWarningColor.withValues(alpha: 0.1)
                      : kDangerColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaper ? Icons.science : Icons.attach_money,
                  color: isPaper ? kWarningColor : kDangerColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaper ? 'Paper Mode (Safe)' : '⚠️ LIVE Mode (Real Funds)',
                      style: TextStyle(
                        color: isPaper ? kWarningColor : kDangerColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaper
                          ? 'Simulated trades with \$1,000 virtual balance'
                          : 'Real orders placed on Binance account',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(value: !isPaper, onChanged: (v) => onToggle(!v)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final int paperTrades;
  final int liveTrades;
  final double paperPnl;
  final double livePnl;
  final double paperWinRate;
  final double liveWinRate;

  const _ComparisonCard({
    required this.paperTrades,
    required this.liveTrades,
    required this.paperPnl,
    required this.livePnl,
    required this.paperWinRate,
    required this.liveWinRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Comparison',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PAPER', style: TextStyle(color: kWarningColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        StatChip(label: 'P&L', value: paperPnl.toSignedString(), valueColor: paperPnl >= 0 ? kProfitColor : kDangerColor),
                        const SizedBox(height: 4),
                        StatChip(label: 'WIN RATE', value: '${paperWinRate.toStringAsFixed(1)}%', valueColor: paperWinRate >= 50 ? kProfitColor : kDangerColor),
                        const SizedBox(height: 4),
                        StatChip(label: 'TRADES', value: paperTrades.toString()),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 100, color: kDividerColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIVE', style: TextStyle(color: kDangerColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        StatChip(label: 'P&L', value: livePnl.toSignedString(), valueColor: livePnl >= 0 ? kProfitColor : kDangerColor),
                        const SizedBox(height: 4),
                        StatChip(label: 'WIN RATE', value: '${liveWinRate.toStringAsFixed(1)}%', valueColor: liveWinRate >= 50 ? kProfitColor : kDangerColor),
                        const SizedBox(height: 4),
                        StatChip(label: 'TRADES', value: liveTrades.toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

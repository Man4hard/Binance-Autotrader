import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/double_ext.dart';
import '../providers/providers.dart';
import '../providers/trade_history_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/trade_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/stat_chip.dart';

class TradeHistoryScreen extends ConsumerWidget {
  const TradeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradeHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            color: kCardColor,
            onSelected: (value) async {
              if (value == 'clear_paper') {
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Clear Paper History',
                  message: 'Delete all paper trade history?',
                  confirmLabel: 'Clear',
                  isDangerous: true,
                );
                if (confirmed) {
                  ref
                      .read(tradeHistoryProvider.notifier)
                      .clearHistory(isPaper: true);
                }
              } else if (value == 'clear_all') {
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Clear All History',
                  message: 'Delete ALL trade history (paper + live)?',
                  confirmLabel: 'Delete All',
                  isDangerous: true,
                );
                if (confirmed) {
                  ref.read(tradeHistoryProvider.notifier).clearHistory();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear_paper', child: Text('Clear Paper History')),
              PopupMenuItem(value: 'clear_all', child: Text('Clear All History')),
            ],
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: Column(
          children: [
            _FilterBar(filter: state.filter),
            if (state.trades.isNotEmpty) _SummaryRow(state: state),
            Expanded(
              child: state.trades.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: kProfitColor,
                      onRefresh: () =>
                          ref.read(tradeHistoryProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 100),
                        itemCount: state.trades.length,
                        itemBuilder: (context, i) => TradeCard(
                          trade: state.trades[i],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final HistoryFilter filter;

  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final f in HistoryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.name.toUpperCase()),
                selected: filter == f,
                onSelected: (_) =>
                    ref.read(tradeHistoryProvider.notifier).setFilter(f),
                selectedColor: kProfitColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: filter == f ? kProfitColor : kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: kTextSecondary),
            onPressed: () =>
                ref.read(tradeHistoryProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final TradeHistoryState state;

  const _SummaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          StatChip(
            label: 'TOTAL P&L',
            value: state.totalPnl.toSignedString(),
            valueColor: state.totalPnl >= 0 ? kProfitColor : kDangerColor,
          ),
          const SizedBox(width: 8),
          StatChip(
            label: 'WIN RATE',
            value: '${state.winRate.toStringAsFixed(1)}%',
            valueColor: state.winRate >= 50 ? kProfitColor : kDangerColor,
          ),
          const SizedBox(width: 8),
          StatChip(
            label: 'TOTAL TRADES',
            value: state.trades.length.toString(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: kTextSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Trade History',
            style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completed trades will appear here',
            style: TextStyle(color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

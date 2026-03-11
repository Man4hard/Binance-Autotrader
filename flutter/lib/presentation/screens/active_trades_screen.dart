import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/trade_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/loading_overlay.dart';

class ActiveTradesScreen extends ConsumerWidget {
  const ActiveTradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeTradesProvider);
    final settingsState = ref.watch(strategySettingsProvider);
    final isPaper = settingsState.settings.isPaperMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Active Trades'),
            const SizedBox(width: 8),
            if (state.trades.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kProfitColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.trades.length.toString(),
                  style: const TextStyle(color: kProfitColor, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () =>
                ref.read(activeTradesProvider.notifier).refresh(isPaper: isPaper),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: state.trades.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                color: kProfitColor,
                onRefresh: () =>
                    ref.read(activeTradesProvider.notifier).refresh(isPaper: isPaper),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: state.trades.length,
                  itemBuilder: (context, i) {
                    final trade = state.trades[i];
                    return TradeCard(
                      trade: trade,
                      showCloseButton: true,
                      onClose: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context,
                          title: 'Close Position',
                          message:
                              'Manually close ${trade.symbol} ${trade.side.name.toUpperCase()} trade at market price?',
                          confirmLabel: 'Close Position',
                        );
                        if (confirmed && context.mounted) {
                          try {
                            await ref
                                .read(activeTradesProvider.notifier)
                                .closeTrade(trade, trade.entryPrice);
                            ref.read(dailyStatsProvider.notifier).refresh();
                            if (context.mounted) {
                              showSuccessSnackbar(context, 'Position closed');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showErrorSnackbar(context, e.toString());
                            }
                          }
                        }
                      },
                    );
                  },
                ),
              ),
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
            Icons.swap_horiz,
            size: 64,
            color: kTextSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Positions',
            style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the trading engine from the dashboard',
            style: TextStyle(color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

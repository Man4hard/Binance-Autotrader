import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../core/extensions/double_ext.dart';
import '../../domain/entities/strategy_settings.dart';
import '../../domain/entities/trade.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/engine_toggle_button.dart';
import '../widgets/signal_strength_bar.dart';
import '../widgets/stat_chip.dart';
import '../widgets/trade_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/error_snackbar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _engineLoading = false;

  @override
  void initState() {
    super.initState();
    _listenToEngineEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeTradesProvider.notifier).loadTrades();
      ref.read(dailyStatsProvider.notifier).refresh();
    });
  }

  void _listenToEngineEvents() {
    final service = FlutterBackgroundService();
    service.on('signalUpdate').listen((data) {
      if (data != null && mounted) {
        ref.read(signalProvider.notifier).updateFromJson(
              Map<String, dynamic>.from(data),
            );
      }
    });
    service.on('tradeUpdate').listen((data) {
      if (data != null && mounted) {
        ref.read(activeTradesProvider.notifier).refresh();
        ref.read(dailyStatsProvider.notifier).refresh();
      }
    });
  }

  Future<void> _toggleEngine(bool start) async {
    final settings = ref.read(strategySettingsProvider).settings;

    if (start && !settings.isPaperMode) {
      final hasKeys = await ref.read(secureStorageProvider).hasKeys();
      if (!hasKeys) {
        if (mounted) {
          showErrorSnackbar(context, 'Configure API keys in Settings first');
        }
        return;
      }
    }

    setState(() => _engineLoading = true);
    try {
      final service = FlutterBackgroundService();
      if (start) {
        await service.startService();
        ref.read(engineRunningProvider.notifier).state = true;
        await ref
            .read(strategySettingsProvider.notifier)
            .toggleEngine(true);
      } else {
        service.invoke('stop');
        ref.read(engineRunningProvider.notifier).state = false;
        await ref
            .read(strategySettingsProvider.notifier)
            .toggleEngine(false);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _engineLoading = false);
    }
  }

  Future<void> _emergencyStop() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '🛑 Emergency Stop',
      message: 'This will immediately close ALL open positions and stop the engine. Are you sure?',
      confirmLabel: 'STOP ALL',
      isDangerous: true,
    );
    if (confirmed && mounted) {
      final service = FlutterBackgroundService();
      service.invoke('emergencyStop');
      ref.read(engineRunningProvider.notifier).state = false;
      await ref.read(strategySettingsProvider.notifier).toggleEngine(false);
      await ref.read(activeTradesProvider.notifier).refresh();
      if (mounted) showSuccessSnackbar(context, 'Emergency stop executed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(strategySettingsProvider);
    final settings = settingsState.settings;
    final engineRunning = ref.watch(engineRunningProvider);
    final dailyStats = ref.watch(dailyStatsProvider);
    final activeTrades = ref.watch(activeTradesProvider);
    final signals = ref.watch(signalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('CryptoBot'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: engineRunning
                    ? kProfitColor.withValues(alpha: 0.15)
                    : kTextSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                engineRunning ? '● LIVE' : '○ STOPPED',
                style: TextStyle(
                  color: engineRunning ? kProfitColor : kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (engineRunning)
            IconButton(
              icon: const Icon(Icons.emergency, color: kDangerColor),
              onPressed: _emergencyStop,
              tooltip: 'Emergency Stop',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              ref.read(activeTradesProvider.notifier).refresh();
              ref.read(dailyStatsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kProfitColor,
        onRefresh: () async {
          ref.read(activeTradesProvider.notifier).refresh();
          ref.read(dailyStatsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BalanceCard(
                balance: settings.isPaperMode ? _getPaperBalance(ref) : 0,
                dailyPnl: dailyStats.todayStats.totalPnl,
                isPaper: settings.isPaperMode,
              ),
            ),
            const SizedBox(height: 16),
            _EngineControlCard(
              isRunning: engineRunning,
              isLoading: _engineLoading,
              isPaper: settings.isPaperMode,
              onStart: () => _toggleEngine(true),
              onStop: () => _toggleEngine(false),
              settings: settings,
            ),
            const SizedBox(height: 16),
            _StatsRow(stats: dailyStats),
            const SizedBox(height: 16),
            if (signals.signals.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Signal Strength',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...signals.signals.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SignalStrengthBar(signal: s, compact: true),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (activeTrades.trades.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Active Positions',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ...activeTrades.trades.take(3).map(
                    (t) => TradeCard(trade: t),
                  ),
            ] else
              const _NoActiveTradesPlaceholder(),
          ],
        ),
      ),
    );
  }

  double _getPaperBalance(WidgetRef ref) {
    final balance = ref.watch(paperBalanceProvider);
    return balance.valueOrNull ?? 1000.0;
  }
}

class _EngineControlCard extends StatelessWidget {
  final bool isRunning;
  final bool isLoading;
  final bool isPaper;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final StrategySettings settings;

  const _EngineControlCard({
    required this.isRunning,
    required this.isLoading,
    required this.isPaper,
    required this.onStart,
    required this.onStop,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunning ? 'Engine Running' : 'Engine Stopped',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaper
                          ? '🟡 Paper Mode — No real funds at risk'
                          : '🔴 LIVE Mode — Real funds active',
                      style: TextStyle(
                        color: isPaper ? kWarningColor : kDangerColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring: ${settings.symbols.join(", ")} | ${settings.timeframe}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              EngineToggleButton(
                isRunning: isRunning,
                onStart: onStart,
                onStop: onStop,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  final DailyStatsState stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = stats.todayStats;
    final all = stats.allTimeStats;
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          StatChip(
            label: 'TODAY P&L',
            value: today.totalPnl.toSignedString(),
            valueColor: today.totalPnl >= 0 ? kProfitColor : kDangerColor,
            icon: Icons.attach_money,
          ),
          const SizedBox(width: 8),
          StatChip(
            label: 'WIN RATE',
            value: '${today.winRate.toStringAsFixed(1)}%',
            valueColor: today.winRate >= 50 ? kProfitColor : kDangerColor,
            icon: Icons.percent,
          ),
          const SizedBox(width: 8),
          StatChip(
            label: 'TRADES TODAY',
            value: today.totalTrades.toString(),
            icon: Icons.swap_horiz,
          ),
          const SizedBox(width: 8),
          StatChip(
            label: 'PROFIT FACTOR',
            value: all.profitFactor.isInfinite
                ? '∞'
                : all.profitFactor.toStringAsFixed(2),
            valueColor: all.profitFactor >= 1.5 ? kProfitColor : kWarningColor,
            icon: Icons.trending_up,
          ),
          const SizedBox(width: 8),
          StatChip(
            label: 'ALL TIME P&L',
            value: all.totalPnl.toSignedString(),
            valueColor: all.totalPnl >= 0 ? kProfitColor : kDangerColor,
            icon: Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }
}

class _NoActiveTradesPlaceholder extends StatelessWidget {
  const _NoActiveTradesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: kTextSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No active positions',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start the engine to begin monitoring markets',
            style: TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

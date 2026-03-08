import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/signal.dart';
import '../../domain/usecases/evaluate_signal.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/indicator_chart.dart';
import '../widgets/signal_strength_bar.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_snackbar.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  String _selectedSymbol = 'BTCUSDT';
  String _selectedTimeframe = '15m';
  List<Candle> _candles = [];
  Signal? _signal;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(restClientProvider);
      final candles = await client.getKlines(
        _selectedSymbol,
        _selectedTimeframe,
        limit: 200,
      );
      final settings = ref.read(strategySettingsProvider).settings;
      Signal? sig;
      if (candles.length >= 200) {
        sig = evaluateSignal(candles, settings, _selectedSymbol);
      }
      if (mounted) {
        setState(() {
          _candles = candles;
          _signal = sig;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load chart data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(strategySettingsProvider).settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts & Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _ControlBar(
              selectedSymbol: _selectedSymbol,
              selectedTimeframe: _selectedTimeframe,
              symbols: settings.symbols,
              onSymbolChanged: (s) {
                setState(() => _selectedSymbol = s);
                _loadData();
              },
              onTimeframeChanged: (t) {
                setState(() => _selectedTimeframe = t);
                _loadData();
              },
            ),
            Expanded(
              child: _candles.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        _error ?? 'Select a symbol to view chart',
                        style: const TextStyle(color: kTextSecondary),
                      ),
                    )
                  : _buildCharts(settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(dynamic settings) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        if (_signal != null) ...[
          SignalStrengthBar(signal: _signal!),
          const SizedBox(height: 8),
        ],
        _ChartSection(
          title: 'Price + EMA (9/21/50) + Bollinger Bands',
          legend: const [
            _LegendItem('Price', kTextPrimary),
            _LegendItem('EMA9', kProfitColor),
            _LegendItem('EMA21', kWarningColor),
            _LegendItem('EMA50', kDangerColor),
            _LegendItem('BB', kBlueAccent),
          ],
          child: SizedBox(
            height: 220,
            child: PriceWithIndicatorChart(
              candles: _candles,
              ema1Period: settings.emaPeriod1,
              ema2Period: settings.emaPeriod2,
              ema3Period: settings.emaPeriod3,
              bbPeriod: settings.bbPeriod,
              bbStdDev: settings.bbStdDev,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ChartSection(
          title: 'RSI (14)',
          legend: const [
            _LegendItem('RSI', kAccentColor),
          ],
          child: SizedBox(
            height: 100,
            child: RsiChart(candles: _candles, period: settings.rsiPeriod),
          ),
        ),
        const SizedBox(height: 12),
        _ChartSection(
          title: 'MACD Histogram',
          legend: const [
            _LegendItem('Bullish', kProfitColor),
            _LegendItem('Bearish', kDangerColor),
          ],
          child: SizedBox(
            height: 100,
            child: MacdChart(candles: _candles),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  final String selectedSymbol;
  final String selectedTimeframe;
  final List<String> symbols;
  final ValueChanged<String> onSymbolChanged;
  final ValueChanged<String> onTimeframeChanged;

  const _ControlBar({
    required this.selectedSymbol,
    required this.selectedTimeframe,
    required this.symbols,
    required this.onSymbolChanged,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSymbol,
                dropdownColor: kCardColor,
                style: const TextStyle(color: kTextPrimary, fontSize: 14),
                items: symbols
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => v != null ? onSymbolChanged(v) : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ...AppConstants.availableTimeframes.map(
            (tf) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => onTimeframeChanged(tf),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selectedTimeframe == tf
                        ? kProfitColor.withValues(alpha: 0.15)
                        : kSurfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selectedTimeframe == tf
                          ? kProfitColor.withValues(alpha: 0.4)
                          : kDividerColor,
                    ),
                  ),
                  child: Text(
                    tf,
                    style: TextStyle(
                      color: selectedTimeframe == tf ? kProfitColor : kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final List<_LegendItem> legend;
  final Widget child;

  const _ChartSection({
    required this.title,
    required this.legend,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ...legend.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 2,
                          color: l.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l.label,
                          style: TextStyle(color: l.color, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);
}

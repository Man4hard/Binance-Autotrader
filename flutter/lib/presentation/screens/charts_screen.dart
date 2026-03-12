import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/signal.dart';
import '../../domain/usecases/evaluate_signal.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/signal_strength_bar.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_snackbar.dart';

String _tvInterval(String tf) {
  switch (tf) {
    case '1m':  return '1';
    case '5m':  return '5';
    case '15m': return '15';
    case '1h':  return '60';
    case '4h':  return '240';
    case '1d':  return 'D';
    default:    return '60';
  }
}

String _buildTvHtml(String symbol, String timeframe) {
  final tvSym = 'BINANCE:$symbol';
  final tvInt = _tvInterval(timeframe);
  return '''
<!DOCTYPE html>
<html style="margin:0;padding:0;width:100%;height:100%;background:#0d1117;">
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #0d1117; overflow: hidden; }
    #tv_chart_container { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="tv_chart_container"></div>
  <script src="https://s3.tradingview.com/tv.js"></script>
  <script>
    new TradingView.widget({
      "container_id": "tv_chart_container",
      "autosize": true,
      "symbol": "$tvSym",
      "interval": "$tvInt",
      "timezone": "Etc/UTC",
      "theme": "dark",
      "style": "1",
      "locale": "en",
      "toolbar_bg": "#161b22",
      "enable_publishing": false,
      "hide_top_toolbar": false,
      "hide_legend": false,
      "save_image": false,
      "show_popup_button": false,
      "withdateranges": true,
      "allow_symbol_change": false,
      "backgroundColor": "#0d1117",
      "gridColor": "rgba(255,255,255,0.04)",
      "overrides": {
        "paneProperties.background": "#0d1117",
        "paneProperties.backgroundType": "solid"
      }
    });
  </script>
</body>
</html>
''';
}

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _selectedSymbol = 'BTCUSDT';
  String _selectedTimeframe = AppConstants.defaultTimeframe;

  List<Candle> _candles = [];
  Signal? _signal;
  bool _isLoadingSignal = false;
  String? _signalError;

  List<String> _allSymbols = [];
  bool _symbolsLoading = false;

  late WebViewController _webViewController;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initWebView();
    _loadSignal();
    _fetchAllSymbols();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSymbols() async {
    setState(() => _symbolsLoading = true);
    try {
      final client = ref.read(restClientProvider);
      final symbols = await client.getAllUsdtSymbols();
      if (mounted) setState(() => _allSymbols = symbols);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _symbolsLoading = false);
    }
  }

  void _openSymbolPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SymbolPickerSheet(
        allSymbols: _allSymbols.isNotEmpty
            ? _allSymbols
            : (ref.read(strategySettingsProvider).settings.symbols.toSet().toList()
              ..sort()),
        selectedSymbol: _selectedSymbol,
        onSelected: (s) {
          Navigator.pop(context);
          if (s != _selectedSymbol) {
            setState(() => _selectedSymbol = s);
            _updateChart();
            _loadSignal();
          }
        },
      ),
    );
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0d1117))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _webViewReady = true);
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_buildTvHtml(_selectedSymbol, _selectedTimeframe));
  }

  void _updateChart() {
    setState(() => _webViewReady = false);
    _webViewController.loadHtmlString(
      _buildTvHtml(_selectedSymbol, _selectedTimeframe),
    );
  }

  Future<void> _loadSignal() async {
    setState(() {
      _isLoadingSignal = true;
      _signalError = null;
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
      if (candles.length >= 50) {
        sig = evaluateSignal(candles, settings, _selectedSymbol);
      }
      if (mounted) {
        setState(() {
          _candles = candles;
          _signal = sig;
          _isLoadingSignal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signalError = e.toString();
          _isLoadingSignal = false;
        });
        showErrorSnackbar(context, 'Failed to load signal data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _openSymbolPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedSymbol,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              _symbolsLoading
                  ? const SizedBox(
                      width: 13, height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: kTextSecondary),
                    )
                  : const Icon(Icons.expand_more,
                      color: kTextSecondary, size: 18),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              _updateChart();
              _loadSignal();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kProfitColor,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kProfitColor,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Market Chart'),
            Tab(text: 'Indicators'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Full-screen TradingView chart ────────────────────
          _MarketChartTab(
            selectedSymbol: _selectedSymbol,
            selectedTimeframe: _selectedTimeframe,
            webViewController: _webViewController,
            webViewReady: _webViewReady,
            onTimeframeChanged: (t) {
              setState(() => _selectedTimeframe = t);
              _updateChart();
              _loadSignal();
            },
          ),

          // ── Tab 2: Signal & indicator analysis ──────────────────────
          _IndicatorsTab(
            signal: _signal,
            candles: _candles,
            isLoading: _isLoadingSignal,
            error: _signalError,
            onRefresh: _loadSignal,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Market Chart
// ─────────────────────────────────────────────────────────────────────────────

class _MarketChartTab extends StatelessWidget {
  final String selectedSymbol;
  final String selectedTimeframe;
  final WebViewController webViewController;
  final bool webViewReady;
  final ValueChanged<String> onTimeframeChanged;

  const _MarketChartTab({
    required this.selectedSymbol,
    required this.selectedTimeframe,
    required this.webViewController,
    required this.webViewReady,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timeframe selector row
        Container(
          color: kSurfaceColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.availableTimeframes.map((tf) {
                final active = selectedTimeframe == tf;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onTimeframeChanged(tf),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? kProfitColor.withValues(alpha: 0.15)
                            : kCardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active
                              ? kProfitColor.withValues(alpha: 0.5)
                              : kDividerColor,
                        ),
                      ),
                      child: Text(
                        tf,
                        style: TextStyle(
                          color: active ? kProfitColor : kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // TradingView chart — takes all remaining space
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: webViewController),
              if (!webViewReady)
                const Center(
                  child: CircularProgressIndicator(color: kProfitColor),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Indicators
// ─────────────────────────────────────────────────────────────────────────────

class _IndicatorsTab extends StatelessWidget {
  final Signal? signal;
  final List<Candle> candles;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const _IndicatorsTab({
    required this.signal,
    required this.candles,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      child: error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: kDangerColor, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load indicator data',
                    style: const TextStyle(
                        color: kTextPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh,
                        color: kProfitColor, size: 18),
                    label: const Text('Retry',
                        style: TextStyle(color: kProfitColor)),
                  ),
                ],
              ),
            )
          : signal == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart,
                          color: kTextSecondary, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'No indicator data yet',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Needs 50+ candles to compute signals',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh,
                            color: kProfitColor, size: 18),
                        label: const Text('Load',
                            style: TextStyle(color: kProfitColor)),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  children: [
                    // Signal strength bar
                    SignalStrengthBar(signal: signal!),
                    const SizedBox(height: 16),

                    // Indicator cards grid
                    _IndicatorCardsGrid(
                        signal: signal!, candles: candles),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicator cards
// ─────────────────────────────────────────────────────────────────────────────

class _IndicatorCardsGrid extends StatelessWidget {
  final Signal signal;
  final List<Candle> candles;

  const _IndicatorCardsGrid(
      {required this.signal, required this.candles});

  @override
  Widget build(BuildContext context) {
    final last = candles.last;
    final ind = signal.indicators;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Overall signal header ──────────────────────────────────
        _SectionHeader('Overall Signal'),
        _BigSignalCard(signal: signal, lastClose: last.close),
        const SizedBox(height: 16),

        // ── Trend indicators ─────────────────────────────────────
        _SectionHeader('Trend'),
        Row(
          children: [
            Expanded(
              child: _IndicatorCard(
                label: 'EMA 20',
                value: ind['ema20'] != null
                    ? '\$${(ind['ema20'] as double).toStringAsFixed(4)}'
                    : '—',
                subtitle: ind['ema20'] != null
                    ? (last.close > (ind['ema20'] as double)
                        ? 'Price above EMA ↑'
                        : 'Price below EMA ↓')
                    : null,
                color: ind['ema20'] != null
                    ? (last.close > (ind['ema20'] as double)
                        ? kProfitColor
                        : kDangerColor)
                    : kTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IndicatorCard(
                label: 'EMA 50',
                value: ind['ema50'] != null
                    ? '\$${(ind['ema50'] as double).toStringAsFixed(4)}'
                    : '—',
                subtitle: ind['ema50'] != null
                    ? (last.close > (ind['ema50'] as double)
                        ? 'Price above EMA ↑'
                        : 'Price below EMA ↓')
                    : null,
                color: ind['ema50'] != null
                    ? (last.close > (ind['ema50'] as double)
                        ? kProfitColor
                        : kDangerColor)
                    : kTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Momentum ────────────────────────────────────────────
        _SectionHeader('Momentum'),
        Row(
          children: [
            Expanded(
              child: _RsiCard(rsi: ind['rsi'] as double?),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MacdCard(
                macd: ind['macd'] as double?,
                signal: ind['macdSignal'] as double?,
                hist: ind['macdHist'] as double?,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Volatility ──────────────────────────────────────────
        _SectionHeader('Volatility'),
        _BbCard(
          upper: ind['bbUpper'] as double?,
          middle: ind['bbMiddle'] as double?,
          lower: ind['bbLower'] as double?,
          close: last.close,
        ),
        const SizedBox(height: 8),

        // ── Volume / VSA ─────────────────────────────────────────
        _SectionHeader('Volume & VSA'),
        Row(
          children: [
            Expanded(
              child: _IndicatorCard(
                label: 'Volume',
                value: _fmt(last.volume),
                subtitle: ind['avgVolume'] != null
                    ? (last.volume > (ind['avgVolume'] as double)
                        ? 'Above average ↑'
                        : 'Below average ↓')
                    : null,
                color: ind['avgVolume'] != null
                    ? (last.volume > (ind['avgVolume'] as double)
                        ? kProfitColor
                        : kTextSecondary)
                    : kTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IndicatorCard(
                label: 'VSA Signal',
                value: ind['vsaSignal'] != null
                    ? '${ind['vsaSignal']}'
                    : '—',
                subtitle: ind['vsaStrength'] != null
                    ? 'Strength: ${ind['vsaStrength']}'
                    : null,
                color: ind['vsaSignal'] != null &&
                        ind['vsaSignal'].toString().toLowerCase().contains('bull')
                    ? kProfitColor
                    : ind['vsaSignal'] != null &&
                            ind['vsaSignal'].toString().toLowerCase().contains('bear')
                        ? kDangerColor
                        : kTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Price info ──────────────────────────────────────────
        _SectionHeader('Price'),
        Row(
          children: [
            Expanded(
              child: _IndicatorCard(
                label: 'Last Close',
                value: '\$${last.close.toStringAsFixed(4)}',
                color: kTextPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IndicatorCard(
                label: 'Candle Range',
                value: '\$${(last.high - last.low).toStringAsFixed(4)}',
                subtitle: 'H: \$${last.high.toStringAsFixed(4)}',
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _IndicatorCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _IndicatorCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kDividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 10)),
            ],
          ],
        ),
      );
}

class _BigSignalCard extends StatelessWidget {
  final Signal signal;
  final double lastClose;
  const _BigSignalCard({required this.signal, required this.lastClose});

  @override
  Widget build(BuildContext context) {
    final isBuy = signal.action == 'BUY';
    final color = isBuy ? kProfitColor : kDangerColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isBuy ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.action,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  'Score ${signal.score.toStringAsFixed(1)} · ${signal.symbol}',
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${lastClose.toStringAsFixed(4)}',
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              if (signal.stopLoss != null)
                Text(
                  'SL \$${signal.stopLoss!.toStringAsFixed(4)}',
                  style: const TextStyle(
                      color: kDangerColor, fontSize: 11),
                ),
              if (signal.takeProfit != null)
                Text(
                  'TP \$${signal.takeProfit!.toStringAsFixed(4)}',
                  style: const TextStyle(
                      color: kProfitColor, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RsiCard extends StatelessWidget {
  final double? rsi;
  const _RsiCard({this.rsi});

  @override
  Widget build(BuildContext context) {
    final label = rsi == null
        ? '—'
        : rsi! >= 70
            ? 'Overbought'
            : rsi! <= 30
                ? 'Oversold'
                : 'Neutral';
    final color = rsi == null
        ? kTextSecondary
        : rsi! >= 70
            ? kDangerColor
            : rsi! <= 30
                ? kProfitColor
                : kTextPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RSI (14)',
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            rsi != null ? rsi!.toStringAsFixed(1) : '—',
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (rsi != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rsi! / 100,
                backgroundColor: kDividerColor,
                color: color,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(label,
              style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MacdCard extends StatelessWidget {
  final double? macd;
  final double? signal;
  final double? hist;
  const _MacdCard({this.macd, this.signal, this.hist});

  @override
  Widget build(BuildContext context) {
    final bullish = hist != null && hist! > 0;
    final color = hist == null
        ? kTextSecondary
        : bullish
            ? kProfitColor
            : kDangerColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MACD',
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            macd != null ? macd!.toStringAsFixed(4) : '—',
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          if (hist != null)
            Text(
              'Hist: ${hist! >= 0 ? '+' : ''}${hist!.toStringAsFixed(4)}',
              style: TextStyle(color: color, fontSize: 10),
            ),
          if (signal != null)
            Text(
              'Signal: ${signal!.toStringAsFixed(4)}',
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _BbCard extends StatelessWidget {
  final double? upper;
  final double? middle;
  final double? lower;
  final double close;
  const _BbCard(
      {this.upper, this.middle, this.lower, required this.close});

  @override
  Widget build(BuildContext context) {
    double? pct;
    if (upper != null && lower != null && (upper! - lower!) > 0) {
      pct = (close - lower!) / (upper! - lower!);
    }
    final color = pct == null
        ? kTextSecondary
        : pct > 0.8
            ? kDangerColor
            : pct < 0.2
                ? kProfitColor
                : kTextPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bollinger Bands (20, 2)',
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bbVal('Upper', upper, kDangerColor),
              _bbVal('Middle', middle, kTextSecondary),
              _bbVal('Lower', lower, kProfitColor),
            ],
          ),
          if (pct != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: kDividerColor,
                color: color,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pct > 0.8
                  ? 'Near upper band — potential resistance'
                  : pct < 0.2
                      ? 'Near lower band — potential support'
                      : 'Mid-band — no extreme reading',
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bbVal(String lbl, double? v, Color c) => Column(
        children: [
          Text(lbl,
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            v != null ? '\$${v.toStringAsFixed(2)}' : '—',
            style: TextStyle(
                color: c, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Symbol picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SymbolPickerSheet extends StatefulWidget {
  final List<String> allSymbols;
  final String selectedSymbol;
  final ValueChanged<String> onSelected;

  const _SymbolPickerSheet({
    required this.allSymbols,
    required this.selectedSymbol,
    required this.onSelected,
  });

  @override
  State<_SymbolPickerSheet> createState() => _SymbolPickerSheetState();
}

class _SymbolPickerSheetState extends State<_SymbolPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.allSymbols;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toUpperCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.allSymbols
          : widget.allSymbols.where((s) => s.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: kDividerColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Text('Select Symbol',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${_filtered.length} pairs',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search (e.g. BTC, PEPE, DOGE…)',
                hintStyle:
                    const TextStyle(color: kTextSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: kTextSecondary, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: kTextSecondary, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: kCardColor,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kDividerColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kDividerColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: kProfitColor.withValues(alpha: 0.5))),
              ),
            ),
          ),
          const Divider(color: kDividerColor, height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No pairs found',
                        style: TextStyle(color: kTextSecondary)))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemExtent: 60,
                    itemBuilder: (ctx, i) {
                      final sym = _filtered[i];
                      final base = sym.endsWith('USDT')
                          ? sym.replaceAll('USDT', '')
                          : sym;
                      final isSelected = sym == widget.selectedSymbol;
                      return InkWell(
                        onTap: () => widget.onSelected(sym),
                        child: Container(
                          color: isSelected
                              ? kProfitColor.withValues(alpha: 0.06)
                              : null,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: kCardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kDividerColor),
                                ),
                                child: Text(
                                  base.length <= 4
                                      ? base
                                      : base.substring(0, 4),
                                  style: TextStyle(
                                    color: isSelected
                                        ? kProfitColor
                                        : kTextPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(base,
                                        style: TextStyle(
                                          color: isSelected
                                              ? kProfitColor
                                              : kTextPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    const Text('/ USDT',
                                        style: TextStyle(
                                            color: kTextSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: kProfitColor, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

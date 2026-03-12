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

// Maps app timeframe strings to TradingView interval strings
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
      "studies": [
        "MASimple@tv-basicstudies",
        "MACD@tv-basicstudies",
        "RSI@tv-basicstudies",
        "BB@tv-basicstudies",
        "Volume@tv-basicstudies"
      ],
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

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  String _selectedSymbol = 'BTCUSDT';
  String _selectedTimeframe = AppConstants.defaultTimeframe;

  List<Candle> _candles = [];
  Signal? _signal;
  bool _isLoadingSignal = false;
  String? _signalError;

  // All Binance USDT pairs — fetched once from API
  List<String> _allSymbols = [];
  bool _symbolsLoading = false;

  late WebViewController _webViewController;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadSignal();
    _fetchAllSymbols();
  }

  Future<void> _fetchAllSymbols() async {
    setState(() => _symbolsLoading = true);
    try {
      final client = ref.read(restClientProvider);
      final symbols = await client.getAllUsdtSymbols();
      if (mounted) setState(() => _allSymbols = symbols);
    } catch (_) {
      // Fall back to settings symbols — no crash
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

  Future<void> _onRefresh() async {
    _updateChart();
    await _loadSignal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts & Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Symbol + Timeframe selector ───────────────────────────────
          _ControlBar(
            selectedSymbol: _selectedSymbol,
            selectedTimeframe: _selectedTimeframe,
            symbolsLoading: _symbolsLoading,
            onSymbolTap: _openSymbolPicker,
            onTimeframeChanged: (t) {
              setState(() => _selectedTimeframe = t);
              _updateChart();
              _loadSignal();
            },
          ),

          // ── TradingView chart (360px tall) ────────────────────────────
          Container(
            height: 360,
            color: const Color(0xFF0d1117),
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (!_webViewReady)
                  const Center(
                    child: CircularProgressIndicator(color: kProfitColor),
                  ),
              ],
            ),
          ),

          // ── Signal analysis panel ─────────────────────────────────────
          Expanded(
            child: LoadingOverlay(
              isLoading: _isLoadingSignal,
              child: _signalError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Signal error: $_signalError',
                          style: const TextStyle(
                              color: kDangerColor, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      padding:
                          const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      children: [
                        if (_signal != null) ...[
                          SignalStrengthBar(signal: _signal!),
                          const SizedBox(height: 8),
                        ],
                        _SignalDetailsPanel(
                          signal: _signal,
                          candles: _candles,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Control bar ───────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final String selectedSymbol;
  final String selectedTimeframe;
  final bool symbolsLoading;
  final VoidCallback onSymbolTap;
  final ValueChanged<String> onTimeframeChanged;

  const _ControlBar({
    required this.selectedSymbol,
    required this.selectedTimeframe,
    required this.symbolsLoading,
    required this.onSymbolTap,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Symbol picker button — tap to open full searchable list
          GestureDetector(
            onTap: onSymbolTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedSymbol,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  symbolsLoading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: kTextSecondary,
                          ),
                        )
                      : const Icon(Icons.expand_more,
                          color: kTextSecondary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timeframe buttons
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.availableTimeframes.map((tf) {
                  final active = selectedTimeframe == tf;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => onTimeframeChanged(tf),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: active
                              ? kProfitColor.withValues(alpha: 0.15)
                              : kSurfaceColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: active
                                ? kProfitColor.withValues(alpha: 0.4)
                                : kDividerColor,
                          ),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            color: active ? kProfitColor : kTextSecondary,
                            fontSize: 11,
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
        ],
      ),
    );
  }
}

// ── Symbol picker bottom sheet ────────────────────────────────────────────────

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
          : widget.allSymbols
              .where((s) => s.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kDividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title + count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Text(
                  'Select Symbol',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filtered.length} pairs',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Search field
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
                prefixIcon:
                    const Icon(Icons.search, color: kTextSecondary, size: 18),
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
                  borderSide: BorderSide(color: kDividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kDividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: kProfitColor.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          const Divider(color: kDividerColor, height: 1),
          // Symbol list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No pairs found',
                      style: TextStyle(color: kTextSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemExtent: 60,
                    itemBuilder: (ctx, i) {
                      final sym = _filtered[i];
                      final base =
                          sym.endsWith('USDT') ? sym.replaceAll('USDT', '') : sym;
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
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: kCardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: kDividerColor),
                                ),
                                child: Text(
                                  base.length <= 4 ? base : base.substring(0, 4),
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
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    base,
                                    style: TextStyle(
                                      color: isSelected
                                          ? kProfitColor
                                          : kTextPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Text(
                                    '/ USDT',
                                    style: TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                const Spacer(),
                                const Icon(Icons.check_circle,
                                    color: kProfitColor, size: 18),
                              ],
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

// ── Signal details panel ──────────────────────────────────────────────────────

class _SignalDetailsPanel extends StatelessWidget {
  final Signal? signal;
  final List<Candle> candles;

  const _SignalDetailsPanel(
      {required this.signal, required this.candles});

  @override
  Widget build(BuildContext context) {
    if (signal == null || candles.isEmpty) return const SizedBox.shrink();
    final sig = signal!;
    final last = candles.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicator Snapshot',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _row('Current Price',
                '\$${last.close.toStringAsFixed(2)}', kTextPrimary),
            _row(
              'EMA 9 / 21 / 50',
              '${sig.ema9.toStringAsFixed(2)}'
              ' / ${sig.ema21.toStringAsFixed(2)}'
              ' / ${sig.ema50.toStringAsFixed(2)}',
              kProfitColor,
            ),
            _row('RSI (14)', sig.rsi.toStringAsFixed(1),
                _rsiColor(sig.rsi)),
            _row(
              'MACD Histogram',
              sig.macdHist.toStringAsFixed(4),
              sig.macdHist >= 0 ? kProfitColor : kDangerColor,
            ),
            if (sig.vsaPattern.isNotEmpty && sig.vsaPattern != 'Normal')
              _row('VSA Pattern', sig.vsaPattern, kWarningColor),
            const Divider(color: kDividerColor, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Signal Score',
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                Text(
                  '${sig.activeScore} / ${sig.maxScore}',
                  style: TextStyle(
                    color: sig.activeScore >= sig.maxScore
                        ? kProfitColor
                        : sig.activeScore >= (sig.maxScore / 2).ceil()
                            ? kWarningColor
                            : kTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 12)),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  static Color _rsiColor(double rsi) {
    if (rsi >= 70) return kDangerColor;
    if (rsi <= 30) return kProfitColor;
    return kTextSecondary;
  }
}

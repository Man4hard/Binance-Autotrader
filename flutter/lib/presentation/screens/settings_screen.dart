import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/entities/strategy_settings.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/loading_overlay.dart';
import 'saved_strategies_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _obscureSecret = true;
  bool _isSavingKeys = false;
  bool _isTestingConnection = false;
  bool _isSavingSettings = false;

  StrategySettings? _draft;

  bool get _hasChanges => _draft != null;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_draft == null) return;
    setState(() => _isSavingSettings = true);
    try {
      await ref.read(strategySettingsProvider.notifier).updateSettings(_draft!);
      if (mounted) {
        setState(() {
          _draft = null;
          _isSavingSettings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: kProfitColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingSettings = false);
        showErrorSnackbar(context, 'Failed to save: $e');
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    return ConfirmationDialog.show(
      context,
      title: 'Unsaved Changes',
      message: 'You have unsaved changes. Discard them?',
      confirmLabel: 'Discard',
      isDangerous: true,
    );
  }

  Future<void> _loadKeys() async {
    final secure = ref.read(secureStorageProvider);
    final apiKey = await secure.getApiKey();
    final secret = await secure.getSecretKey();
    if (apiKey != null) _apiKeyController.text = apiKey;
    if (secret != null) _secretKeyController.text = secret;
  }

  Future<void> _saveKeys() async {
    final apiKey = _apiKeyController.text.trim();
    final secret = _secretKeyController.text.trim();

    if (apiKey.isEmpty || secret.isEmpty) {
      showErrorSnackbar(context, 'Both API key and secret are required');
      return;
    }

    setState(() => _isSavingKeys = true);
    try {
      final secure = ref.read(secureStorageProvider);
      await secure.saveApiKey(apiKey);
      await secure.saveSecretKey(secret);
      ref.invalidate(apiCredentialsProvider);
      if (mounted) showSuccessSnackbar(context, 'API keys saved securely');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Failed to save keys: $e');
    } finally {
      if (mounted) setState(() => _isSavingKeys = false);
    }
  }

  Future<void> _deleteKeys() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete API Keys',
      message: 'Remove saved API credentials? You will not be able to trade live.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
    if (!confirmed) return;

    final secure = ref.read(secureStorageProvider);
    await secure.deleteKeys();
    _apiKeyController.clear();
    _secretKeyController.clear();
    ref.invalidate(apiCredentialsProvider);
    if (mounted) showSuccessSnackbar(context, 'API keys deleted');
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    final secret = _secretKeyController.text.trim();

    if (apiKey.isEmpty || secret.isEmpty) {
      showErrorSnackbar(context, 'Enter API credentials first');
      return;
    }

    setState(() => _isTestingConnection = true);
    try {
      final repo = ref.read(binanceRepositoryProvider);
      await repo.syncServerTime();
      final balance = await repo.getAccountBalance(
        apiKey: apiKey,
        secret: secret,
      );
      if (mounted) {
        showSuccessSnackbar(
          context,
          '✅ Connected! USDT Balance: \$${balance.usdtFree.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(strategySettingsProvider);
    final saved = settingsState.settings;
    final working = _draft ?? saved;

    void onChanged(StrategySettings updated) =>
        setState(() => _draft = updated);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) {
          setState(() => _draft = null);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: _hasChanges
              ? [
                  TextButton(
                    onPressed: () => setState(() => _draft = null),
                    child: const Text('Discard',
                        style: TextStyle(color: kDangerColor, fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                ]
              : null,
        ),
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: _hasChanges ? 80 : 0,
          child: _hasChanges
              ? Container(
                  color: kSurfaceColor,
                  padding:
                      const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSavingSettings ? null : _saveSettings,
                      icon: _isSavingSettings
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kBgColor),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSavingSettings
                            ? 'Saving…'
                            : 'Save Settings',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kProfitColor,
                        foregroundColor: kBgColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        body: LoadingOverlay(
          isLoading: settingsState.isLoading,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_hasChanges)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kWarningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: kWarningColor.withValues(alpha: 0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.edit_note_rounded,
                        color: kWarningColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have unsaved changes — tap Save Settings to apply them.',
                        style: TextStyle(
                            color: kWarningColor, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              _SavedStrategiesBanner(settings: working),
              _SectionHeader(
                  title: '🔑 API Keys',
                  subtitle: 'Stored securely in Android Keystore'),
              _ApiKeysSection(
                apiKeyController: _apiKeyController,
                secretController: _secretKeyController,
                obscureApiKey: _obscureApiKey,
                obscureSecret: _obscureSecret,
                isSaving: _isSavingKeys,
                isTesting: _isTestingConnection,
                onToggleApiKey: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
                onToggleSecret: () =>
                    setState(() => _obscureSecret = !_obscureSecret),
                onSave: _saveKeys,
                onDelete: _deleteKeys,
                onTest: _testConnection,
              ),
              _SectionHeader(
                title: '🔬 Active Indicators',
                subtitle:
                    'Toggle which indicators are used to generate signals',
              ),
              _IndicatorTogglesSection(
                settings: working,
                onChanged: onChanged,
              ),
              _SectionHeader(title: '📈 Strategy Parameters'),
              _StrategySection(
                settings: working,
                onChanged: onChanged,
              ),
              _SectionHeader(title: '⚖️ Risk Management'),
              _RiskSection(
                settings: working,
                onChanged: onChanged,
              ),
              _SectionHeader(title: '📊 Symbols & Timeframe'),
              _SymbolsSection(
                settings: working,
                onChanged: onChanged,
              ),
              _SectionHeader(title: '⚙️ Engine'),
              _EngineSection(
                settings: working,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Saved Strategies Banner ───────────────────────────────────────────────────
class _SavedStrategiesBanner extends ConsumerWidget {
  final StrategySettings settings;
  const _SavedStrategiesBanner({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(savedStrategiesProvider).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kProfitColor.withValues(alpha: 0.12),
            kProfitColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kProfitColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.bookmark, color: kProfitColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const Text('Saved Strategies',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? 'No saved strategies yet'
                      : '$count saved ${count == 1 ? "strategy" : "strategies"}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SavedStrategiesScreen()),
                ),
                child: const Text('View All',
                    style: TextStyle(color: kProfitColor, fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _quickSave(context, ref),
                style: TextButton.styleFrom(
                  backgroundColor: kProfitColor,
                  foregroundColor: kBgColor,
                  minimumSize: const Size(80, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Future<void> _quickSave(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text:
          'Strategy ${DateTime.now().day}/${DateTime.now().month} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Save Strategy',
            style:
                TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. EMA Scalp 5-12-20',
            hintStyle:
                TextStyle(color: kTextSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: kCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kDividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kProfitColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kProfitColor,
              foregroundColor: kBgColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final n = controller.text.trim();
              if (n.isNotEmpty) Navigator.pop(ctx, n);
            },
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (name != null && context.mounted) {
      await ref
          .read(savedStrategiesProvider.notifier)
          .saveStrategy(name, settings);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" saved'),
          backgroundColor: kProfitColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 6),
          const Divider(color: kDividerColor),
        ],
      ),
    );
  }
}

// ── Active Indicators Toggles ─────────────────────────────────────────────────
class _IndicatorTogglesSection extends StatelessWidget {
  final StrategySettings settings;
  final ValueChanged<StrategySettings> onChanged;

  const _IndicatorTogglesSection({required this.settings, required this.onChanged});

  void _toggle(String key, bool value) {
    final updated = Map<String, bool>.from(settings.activeIndicators);
    updated[key] = value;
    final enabledCount = updated.values.where((v) => v).length;
    // Keep minScoreToEnter within valid range
    final newMin = settings.minScoreToEnter.clamp(1, enabledCount > 0 ? enabledCount : 1);
    onChanged(settings.copyWith(
      activeIndicators: updated,
      minScoreToEnter: newMin,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ai = settings.activeIndicators;
    final enabledCount = ai.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _IndicatorToggleRow(
            name: 'EMA',
            subtitle: 'Triple EMA trend filter (9/21/50)',
            icon: Icons.show_chart,
            color: kProfitColor,
            enabled: ai['ema'] ?? true,
            onChanged: (v) => _toggle('ema', v),
          ),
          _IndicatorToggleRow(
            name: 'MACD',
            subtitle: 'Momentum — histogram direction',
            icon: Icons.bar_chart,
            color: kWarningColor,
            enabled: ai['macd'] ?? true,
            onChanged: (v) => _toggle('macd', v),
          ),
          _IndicatorToggleRow(
            name: 'RSI',
            subtitle: 'Relative strength — 14-period',
            icon: Icons.speed,
            color: kBlueAccent,
            enabled: ai['rsi'] ?? true,
            onChanged: (v) => _toggle('rsi', v),
          ),
          _IndicatorToggleRow(
            name: 'BB',
            subtitle: 'Bollinger Band midline trend filter',
            icon: Icons.timeline,
            color: const Color(0xFFAB47BC),
            enabled: ai['bb'] ?? true,
            onChanged: (v) => _toggle('bb', v),
          ),
          _IndicatorToggleRow(
            name: 'VSA',
            subtitle: 'Volume Spread Analysis — smart money',
            icon: Icons.candlestick_chart,
            color: const Color(0xFFFF7043),
            enabled: ai['vsa'] ?? true,
            onChanged: (v) => _toggle('vsa', v),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: kTextSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$enabledCount indicator${enabledCount == 1 ? "" : "s"} active  •  '
                    'Min score to enter: ${settings.effectiveMinScore}/$enabledCount',
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorToggleRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _IndicatorToggleRow({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? color.withValues(alpha: 0.15) : kDividerColor.withValues(alpha: 0.3),
              border: Border.all(
                color: enabled ? color.withValues(alpha: 0.5) : kDividerColor,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: enabled ? color : kTextSecondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: enabled ? kTextPrimary : kTextSecondary.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: enabled ? kTextSecondary : kTextSecondary.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── API Keys Section ──────────────────────────────────────────────────────────
class _ApiKeysSection extends StatelessWidget {
  final TextEditingController apiKeyController;
  final TextEditingController secretController;
  final bool obscureApiKey;
  final bool obscureSecret;
  final bool isSaving;
  final bool isTesting;
  final VoidCallback onToggleApiKey;
  final VoidCallback onToggleSecret;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const _ApiKeysSection({
    required this.apiKeyController,
    required this.secretController,
    required this.obscureApiKey,
    required this.obscureSecret,
    required this.isSaving,
    required this.isTesting,
    required this.onToggleApiKey,
    required this.onToggleSecret,
    required this.onSave,
    required this.onDelete,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: apiKeyController,
            obscureText: obscureApiKey,
            style: const TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'Enter Binance API key',
              suffixIcon: IconButton(
                icon: Icon(
                  obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  color: kTextSecondary,
                ),
                onPressed: onToggleApiKey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: secretController,
            obscureText: obscureSecret,
            style: const TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              labelText: 'Secret Key',
              hintText: 'Enter Binance secret key',
              suffixIcon: IconButton(
                icon: Icon(
                  obscureSecret ? Icons.visibility : Icons.visibility_off,
                  color: kTextSecondary,
                ),
                onPressed: onToggleSecret,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kBgColor),
                        )
                      : const Icon(Icons.lock, size: 16),
                  label: const Text('Save Keys'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isTesting ? null : onTest,
                icon: isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kProfitColor),
                      )
                    : const Icon(Icons.wifi, size: 16, color: kProfitColor),
                label: const Text('Test', style: TextStyle(color: kProfitColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kProfitColor),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: kDangerColor),
                tooltip: 'Delete keys',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '🔒 Keys are encrypted using Android Keystore (AES-GCM). Never sent to third parties.',
            style: TextStyle(color: kTextSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Strategy Parameters ───────────────────────────────────────────────────────
class _StrategySection extends StatelessWidget {
  final StrategySettings settings;
  final ValueChanged<StrategySettings> onChanged;

  const _StrategySection({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final maxActive = settings.enabledIndicatorCount.clamp(1, 5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SliderTile(
            label: 'EMA Fast Period',
            value: settings.emaPeriod1.toDouble(),
            min: 5,
            max: 20,
            divisions: 15,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(emaPeriod1: v.toInt())),
          ),
          _SliderTile(
            label: 'EMA Mid Period',
            value: settings.emaPeriod2.toDouble(),
            min: 10,
            max: 50,
            divisions: 40,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(emaPeriod2: v.toInt())),
          ),
          _SliderTile(
            label: 'EMA Slow Period',
            value: settings.emaPeriod3.toDouble(),
            min: 20,
            max: 200,
            divisions: 36,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(emaPeriod3: v.toInt())),
          ),
          _SliderTile(
            label: 'RSI Period',
            value: settings.rsiPeriod.toDouble(),
            min: 7,
            max: 28,
            divisions: 21,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(rsiPeriod: v.toInt())),
          ),
          _SliderTile(
            label: 'RSI Neutral Low',
            value: settings.rsiNeutralLow,
            min: 30,
            max: 50,
            divisions: 20,
            format: (v) => v.toStringAsFixed(0),
            onChanged: (v) => onChanged(settings.copyWith(rsiNeutralLow: v)),
          ),
          _SliderTile(
            label: 'RSI Neutral High',
            value: settings.rsiNeutralHigh,
            min: 50,
            max: 70,
            divisions: 20,
            format: (v) => v.toStringAsFixed(0),
            onChanged: (v) => onChanged(settings.copyWith(rsiNeutralHigh: v)),
          ),
          const SizedBox(height: 4),
          _SectionDivider(label: 'MACD Parameters'),
          _SliderTile(
            label: 'MACD Fast Period',
            value: settings.macdFast.toDouble(),
            min: 5,
            max: 20,
            divisions: 15,
            format: (v) => v.toInt().toString(),
            hint: 'Short EMA — standard: 12',
            onChanged: (v) => onChanged(settings.copyWith(macdFast: v.toInt())),
          ),
          _SliderTile(
            label: 'MACD Slow Period',
            value: settings.macdSlow.toDouble(),
            min: 15,
            max: 50,
            divisions: 35,
            format: (v) => v.toInt().toString(),
            hint: 'Long EMA — standard: 26',
            onChanged: (v) => onChanged(settings.copyWith(macdSlow: v.toInt())),
          ),
          _SliderTile(
            label: 'MACD Signal Period',
            value: settings.macdSignal.toDouble(),
            min: 3,
            max: 15,
            divisions: 12,
            format: (v) => v.toInt().toString(),
            hint: 'Signal line smoothing — standard: 9',
            onChanged: (v) => onChanged(settings.copyWith(macdSignal: v.toInt())),
          ),
          const SizedBox(height: 4),
          _SectionDivider(label: 'Bollinger Bands Parameters'),
          _SliderTile(
            label: 'BB Period',
            value: settings.bbPeriod.toDouble(),
            min: 10,
            max: 50,
            divisions: 40,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(bbPeriod: v.toInt())),
          ),
          _SliderTile(
            label: 'BB Std Dev Multiplier',
            value: settings.bbStdDev,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            format: (v) => v.toStringAsFixed(1),
            onChanged: (v) => onChanged(settings.copyWith(bbStdDev: v)),
          ),
          const SizedBox(height: 4),
          _SectionDivider(label: 'VSA Parameters'),
          _SliderTile(
            label: 'VSA Lookback Period',
            value: settings.vsaLookback.toDouble(),
            min: 10,
            max: 50,
            divisions: 40,
            format: (v) => v.toInt().toString(),
            hint: 'Candles used for average volume — standard: 20',
            onChanged: (v) => onChanged(settings.copyWith(vsaLookback: v.toInt())),
          ),
          _SliderTile(
            label: 'High Volume Threshold',
            value: settings.vsaHighVolThreshold,
            min: 1.1,
            max: 3.0,
            divisions: 19,
            format: (v) => '${v.toStringAsFixed(1)}×',
            hint: 'Volume must be this × avg to be "high" — standard: 1.5×',
            onChanged: (v) => onChanged(settings.copyWith(vsaHighVolThreshold: v)),
          ),
          _SliderTile(
            label: 'Very High Volume Threshold',
            value: settings.vsaVeryHighVolThreshold,
            min: 1.5,
            max: 5.0,
            divisions: 35,
            format: (v) => '${v.toStringAsFixed(1)}×',
            hint: 'Climax volume trigger — standard: 2.0×',
            onChanged: (v) => onChanged(settings.copyWith(vsaVeryHighVolThreshold: v)),
          ),
          _SliderTile(
            label: 'Low Volume Threshold',
            value: settings.vsaLowVolThreshold,
            min: 0.3,
            max: 0.9,
            divisions: 12,
            format: (v) => '${v.toStringAsFixed(1)}×',
            hint: 'No-supply / no-demand threshold — standard: 0.7×',
            onChanged: (v) => onChanged(settings.copyWith(vsaLowVolThreshold: v)),
          ),
          _SliderTile(
            label: 'Wide Spread Threshold',
            value: settings.vsaWideSpreadThreshold,
            min: 1.0,
            max: 2.5,
            divisions: 15,
            format: (v) => '${v.toStringAsFixed(1)}×',
            hint: 'Candle range vs average — standard: 1.3×',
            onChanged: (v) => onChanged(settings.copyWith(vsaWideSpreadThreshold: v)),
          ),
          const SizedBox(height: 4),
          _SectionDivider(label: 'Scoring'),
          if (maxActive >= 2)
            _SliderTile(
              label: 'Min Score to Enter (out of $maxActive)',
              value: settings.minScoreToEnter.toDouble().clamp(1.0, maxActive.toDouble()),
              min: 1,
              max: maxActive.toDouble(),
              divisions: maxActive - 1,
              format: (v) => v.toInt().toString(),
              onChanged: (v) => onChanged(settings.copyWith(minScoreToEnter: v.toInt())),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Min Score to Enter',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                  Text(
                    '1 / 1',
                    style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Risk Management ───────────────────────────────────────────────────────────
class _RiskSection extends StatelessWidget {
  final StrategySettings settings;
  final ValueChanged<StrategySettings> onChanged;

  const _RiskSection({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SliderTile(
            label: 'Daily Profit Target (USDT)',
            value: settings.dailyProfitTarget,
            min: 1,
            max: 100,
            divisions: 99,
            format: (v) => '\$${v.toStringAsFixed(0)}',
            onChanged: (v) => onChanged(settings.copyWith(dailyProfitTarget: v)),
          ),
          _SliderTile(
            label: 'Max Daily Loss (USDT)',
            value: settings.maxDailyLoss,
            min: 5,
            max: 200,
            divisions: 39,
            format: (v) => '\$${v.toStringAsFixed(0)}',
            onChanged: (v) => onChanged(settings.copyWith(maxDailyLoss: v)),
          ),
          _SliderTile(
            label: 'Max Daily Trades',
            value: settings.maxDailyTrades.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(maxDailyTrades: v.toInt())),
          ),
          _SliderTile(
            label: 'Risk Per Trade (%)',
            value: settings.riskPercent * 100,
            min: 0.1,
            max: 5.0,
            divisions: 49,
            format: (v) => '${v.toStringAsFixed(1)}%',
            onChanged: (v) => onChanged(settings.copyWith(riskPercent: v / 100)),
          ),
          _SliderTile(
            label: 'ATR Multiplier (Stop Loss)',
            value: settings.atrMultiplier,
            min: 0.5,
            max: 4.0,
            divisions: 35,
            format: (v) => v.toStringAsFixed(1),
            onChanged: (v) => onChanged(settings.copyWith(atrMultiplier: v)),
          ),
          _SliderTile(
            label: 'Min Risk:Reward Ratio',
            value: settings.minRR,
            min: 1.0,
            max: 5.0,
            divisions: 40,
            format: (v) => '1:${v.toStringAsFixed(1)}',
            onChanged: (v) => onChanged(settings.copyWith(minRR: v)),
          ),
        ],
      ),
    );
  }
}

// ── Symbols & Timeframe ───────────────────────────────────────────────────────
class _SymbolsSection extends StatelessWidget {
  final StrategySettings settings;
  final ValueChanged<StrategySettings> onChanged;

  const _SymbolsSection({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trading Pairs', style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: AppConstants.defaultSymbols.map((symbol) {
              final selected = settings.symbols.contains(symbol);
              return FilterChip(
                label: Text(symbol),
                selected: selected,
                onSelected: (v) {
                  final updated = List<String>.from(settings.symbols);
                  if (v) {
                    if (!updated.contains(symbol)) updated.add(symbol);
                  } else {
                    if (updated.length > 1) updated.remove(symbol);
                  }
                  onChanged(settings.copyWith(symbols: updated));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Timeframe', style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppConstants.availableTimeframes.map((tf) {
              final selected = settings.timeframe == tf;
              return ChoiceChip(
                label: Text(tf),
                selected: selected,
                onSelected: (_) => onChanged(settings.copyWith(timeframe: tf)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _SwitchTile(
            label: 'Paper Trading Mode',
            subtitle: 'Simulate trades without real money',
            value: settings.isPaperMode,
            onChanged: (v) => onChanged(settings.copyWith(isPaperMode: v)),
          ),
        ],
      ),
    );
  }
}

// ── Engine Section ────────────────────────────────────────────────────────────
class _EngineSection extends StatelessWidget {
  final StrategySettings settings;
  final ValueChanged<StrategySettings> onChanged;

  const _EngineSection({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SwitchTile(
            label: 'Auto-start on device boot',
            subtitle: 'Resume engine automatically after restart',
            value: settings.autoStartOnBoot,
            onChanged: (v) => onChanged(settings.copyWith(autoStartOnBoot: v)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Request battery optimization exemption
              },
              icon: const Icon(Icons.battery_saver, color: kWarningColor),
              label: const Text(
                'Disable Battery Optimization',
                style: TextStyle(color: kWarningColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kWarningColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Required for reliable background trading on MIUI/One UI/EMUI devices.',
            style: TextStyle(color: kTextSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          const Text(
            '⚠️ Risk Disclaimer: Algorithmic trading carries significant financial risk. '
            'The \$10/day target is a strategy goal, not a guarantee. '
            'Only trade with funds you can afford to lose.',
            style: TextStyle(color: kTextSecondary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Slider Tile ───────────────────────────────────────────────────────────────
class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final String? hint;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                if (hint != null)
                  Text(hint!, style: const TextStyle(color: kTextSecondary, fontSize: 10)),
                Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: kProfitColor,
                  inactiveColor: kDividerColor,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              format(value),
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Divider(color: kDividerColor, height: 1)),
          ],
        ),
      );
}

// ── Switch Tile ───────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: kTextPrimary, fontSize: 14)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

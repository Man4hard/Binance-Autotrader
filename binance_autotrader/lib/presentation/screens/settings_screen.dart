import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/entities/strategy_settings.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/loading_overlay.dart';

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
    final settings = settingsState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LoadingOverlay(
        isLoading: settingsState.isLoading,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _SectionHeader(title: '🔑 API Keys', subtitle: 'Stored securely in Android Keystore'),
            _ApiKeysSection(
              apiKeyController: _apiKeyController,
              secretController: _secretKeyController,
              obscureApiKey: _obscureApiKey,
              obscureSecret: _obscureSecret,
              isSaving: _isSavingKeys,
              isTesting: _isTestingConnection,
              onToggleApiKey: () => setState(() => _obscureApiKey = !_obscureApiKey),
              onToggleSecret: () => setState(() => _obscureSecret = !_obscureSecret),
              onSave: _saveKeys,
              onDelete: _deleteKeys,
              onTest: _testConnection,
            ),
            _SectionHeader(title: '📈 Strategy Parameters'),
            _StrategySection(
              settings: settings,
              onChanged: (updated) =>
                  ref.read(strategySettingsProvider.notifier).updateSettings(updated),
            ),
            _SectionHeader(title: '⚖️ Risk Management'),
            _RiskSection(
              settings: settings,
              onChanged: (updated) =>
                  ref.read(strategySettingsProvider.notifier).updateSettings(updated),
            ),
            _SectionHeader(title: '📊 Symbols & Timeframe'),
            _SymbolsSection(
              settings: settings,
              onChanged: (updated) =>
                  ref.read(strategySettingsProvider.notifier).updateSettings(updated),
            ),
            _SectionHeader(title: '⚙️ Engine'),
            _EngineSection(
              settings: settings,
              onChanged: (updated) =>
                  ref.read(strategySettingsProvider.notifier).updateSettings(updated),
            ),
          ],
        ),
      ),
    );
  }
}

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
                icon: Icon(obscureApiKey ? Icons.visibility : Icons.visibility_off, color: kTextSecondary),
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
                icon: Icon(obscureSecret ? Icons.visibility : Icons.visibility_off, color: kTextSecondary),
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

class _StrategySection extends StatelessWidget {
  final StrategySettings settings;
  final ValueChanged<StrategySettings> onChanged;

  const _StrategySection({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SliderTile(
            label: 'EMA Period 1 (Fast)',
            value: settings.emaPeriod1.toDouble(),
            min: 5,
            max: 20,
            divisions: 15,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(emaPeriod1: v.toInt())),
          ),
          _SliderTile(
            label: 'EMA Period 2 (Medium)',
            value: settings.emaPeriod2.toDouble(),
            min: 10,
            max: 50,
            divisions: 40,
            format: (v) => v.toInt().toString(),
            onChanged: (v) => onChanged(settings.copyWith(emaPeriod2: v.toInt())),
          ),
          _SliderTile(
            label: 'EMA Period 3 (Slow)',
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
          _SliderTile(
            label: 'Min Score to Enter (out of 4)',
            value: settings.minScoreToEnter.toDouble(),
            min: 2,
            max: 4,
            divisions: 2,
            format: (v) => v.toInt().toString(),
            onChanged: (v) =>
                onChanged(settings.copyWith(minScoreToEnter: v.toInt())),
          ),
        ],
      ),
    );
  }
}

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
            onChanged: (v) =>
                onChanged(settings.copyWith(maxDailyTrades: v.toInt())),
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
                selectedColor: kProfitColor.withValues(alpha: 0.2),
                checkmarkColor: kProfitColor,
                labelStyle: TextStyle(
                  color: selected ? kProfitColor : kTextSecondary,
                  fontSize: 12,
                ),
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
                selectedColor: kProfitColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? kProfitColor : kTextSecondary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 5,
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: kProfitColor,
                inactiveTrackColor: kDividerColor,
                thumbColor: kProfitColor,
                overlayColor: Color(0x2200FF88),
                trackHeight: 2,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              format(value),
              style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

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
                Text(subtitle!, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

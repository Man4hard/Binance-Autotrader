import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/saved_strategy.dart';
import '../providers/providers.dart';
import '../providers/saved_strategies_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';

class SavedStrategiesScreen extends ConsumerWidget {
  const SavedStrategiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategies = ref.watch(savedStrategiesProvider);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        title: const Text('Saved Strategies',
            style: TextStyle(
                color: kTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: kTextPrimary),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showSaveDialog(context, ref),
            icon: const Icon(Icons.save_outlined, color: kProfitColor, size: 18),
            label: const Text('Save Current',
                style: TextStyle(color: kProfitColor, fontSize: 13)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: strategies.isEmpty
          ? _EmptyState(onSave: () => _showSaveDialog(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: strategies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _StrategyCard(
                strategy: strategies[i],
                onLoad: () => _loadStrategy(context, ref, strategies[i]),
                onRename: () => _showRenameDialog(context, ref, strategies[i]),
                onDelete: () => _confirmDelete(context, ref, strategies[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSaveDialog(context, ref),
        backgroundColor: kProfitColor,
        foregroundColor: kBgColor,
        icon: const Icon(Icons.save_alt),
        label: const Text('Save Current Strategy',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: 'Strategy ${DateTime.now().day}/${DateTime.now().month}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Save Strategy',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Give this strategy a name so you can find it later.',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. EMA Scalp 5-12-20',
                hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: kCardColor,
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
                  borderSide: BorderSide(color: kProfitColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
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
      final settings = ref.read(strategySettingsProvider).settings;
      await ref
          .read(savedStrategiesProvider.notifier)
          .saveStrategy(name, settings);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name" saved'),
            backgroundColor: kProfitColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadStrategy(
      BuildContext context, WidgetRef ref, SavedStrategy strategy) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Load Strategy',
      message: 'Load "${strategy.name}"?\n\nThis will replace your current settings.',
      confirmLabel: 'Load',
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(strategySettingsProvider.notifier)
          .updateSettings(strategy.settings);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${strategy.name}" loaded'),
            backgroundColor: kProfitColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, SavedStrategy strategy) async {
    final controller = TextEditingController(text: strategy.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Rename Strategy',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: kCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kDividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kProfitColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (name != null) {
      await ref
          .read(savedStrategiesProvider.notifier)
          .rename(strategy.id, name);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SavedStrategy strategy) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Strategy',
      message: 'Delete "${strategy.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
    if (confirmed == true) {
      await ref.read(savedStrategiesProvider.notifier).delete(strategy.id);
    }
  }
}

// ─── Strategy Card ───────────────────────────────────────────────────────────

class _StrategyCard extends StatelessWidget {
  final SavedStrategy strategy;
  final VoidCallback onLoad;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _StrategyCard({
    required this.strategy,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = strategy.settings;
    final enabledIndicators = s.activeIndicators.entries
        .where((e) => e.value)
        .map((e) => e.key.toUpperCase())
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDividerColor),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kProfitColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_graph,
                      color: kProfitColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strategy.name,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(strategy.createdAt),
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // 3-dot menu
                PopupMenuButton<String>(
                  color: kSurfaceColor,
                  onSelected: (v) {
                    if (v == 'rename') onRename();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            color: kTextSecondary, size: 16),
                        SizedBox(width: 8),
                        Text('Rename',
                            style: TextStyle(color: kTextPrimary)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            color: kDangerColor, size: 16),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: kDangerColor)),
                      ]),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.more_vert,
                        color: kTextSecondary, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Parameters summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag(
                    '${s.timeframe} timeframe', kProfitColor.withValues(alpha: 0.15), kProfitColor),
                _Tag('EMA ${s.emaPeriod1}/${s.emaPeriod2}/${s.emaPeriod3}',
                    kCardColor, kTextSecondary),
                _Tag(
                    'MACD ${s.macdFast}/${s.macdSlow}/${s.macdSignal}',
                    kCardColor,
                    kTextSecondary),
                _Tag('RSI ${s.rsiPeriod}', kCardColor, kTextSecondary),
                if (s.activeIndicators['vsa'] == true)
                  _Tag('VSA', kCardColor, kTextSecondary),
                _Tag(s.isPaperMode ? 'Paper' : 'Live',
                    s.isPaperMode
                        ? kWarningColor.withValues(alpha: 0.15)
                        : kDangerColor.withValues(alpha: 0.15),
                    s.isPaperMode ? kWarningColor : kDangerColor),
              ],
            ),
          ),

          if (enabledIndicators.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: kTextSecondary, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      enabledIndicators,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Load button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Load Strategy',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kProfitColor,
                  foregroundColor: kBgColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Tag(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onSave;
  const _EmptyState({required this.onSave});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border,
                color: kTextSecondary.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            const Text('No saved strategies yet',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Configure a strategy in Settings,\nthen save it here to use later.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save Current Strategy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kProfitColor,
                foregroundColor: kBgColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/dashboard_screen.dart';
import '../screens/active_trades_screen.dart';
import '../screens/trade_history_screen.dart';
import '../screens/charts_screen.dart';
import '../screens/paper_trading_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    ActiveTradesScreen(),
    TradeHistoryScreen(),
    ChartsScreen(),
    PaperTradingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeTradesState = ref.watch(activeTradesProvider);
    final engineRunning = ref.watch(engineRunningProvider);
    final activeCount = activeTradesState.trades.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('CryptoBot'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Dev by Tayyab',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _CompactNavBar(
        currentIndex: _currentIndex,
        activeCount: activeCount,
        engineRunning: engineRunning,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _CompactNavBar extends StatelessWidget {
  final int currentIndex;
  final int activeCount;
  final bool engineRunning;
  final ValueChanged<int> onTap;

  const _CompactNavBar({
    required this.currentIndex,
    required this.activeCount,
    required this.engineRunning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard,   label: 'Home'),
      _NavItem(icon: Icons.swap_vert_outlined, activeIcon: Icons.swap_vert,   label: 'Active',   badge: activeCount > 0 ? '$activeCount' : null),
      _NavItem(icon: Icons.history_outlined,   activeIcon: Icons.history,      label: 'History'),
      _NavItem(icon: Icons.show_chart_outlined,activeIcon: Icons.show_chart,   label: 'Charts'),
      _NavItem(icon: Icons.science_outlined,   activeIcon: Icons.science,      label: 'Paper'),
      _NavItem(icon: Icons.settings_outlined,  activeIcon: Icons.settings,     label: 'Settings', dot: engineRunning),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        border: Border(top: BorderSide(color: kDividerColor, width: 0.8)),
      ),
      // SafeArea handles home-bar phones (iPhone X style notches)
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: kProfitColor.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with optional badge / dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              key: ValueKey(selected),
                              color: selected ? kProfitColor : kTextSecondary,
                              size: 22,
                            ),
                          ),
                          if (item.badge != null)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: kProfitColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.badge!,
                                  style: const TextStyle(
                                    color: kBgColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          else if (item.dot)
                            Positioned(
                              right: -3,
                              top: -2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: kProfitColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Label
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? kProfitColor : kTextSecondary,
                          fontSize: 9.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? badge;
  final bool dot;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
    this.dot = false,
  });
}

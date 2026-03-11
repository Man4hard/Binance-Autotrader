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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kDividerColor)),
        ),
        child: NavigationBar(
          backgroundColor: kSurfaceColor,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          indicatorColor: kProfitColor.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.dashboard_outlined,
                color: _currentIndex == 0 ? kProfitColor : kTextSecondary,
              ),
              selectedIcon: const Icon(Icons.dashboard, color: kProfitColor),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: activeCount > 0,
                label: Text('$activeCount'),
                backgroundColor: kProfitColor,
                textColor: kBgColor,
                child: Icon(
                  Icons.swap_vert_outlined,
                  color: _currentIndex == 1 ? kProfitColor : kTextSecondary,
                ),
              ),
              selectedIcon: const Icon(Icons.swap_vert, color: kProfitColor),
              label: 'Active',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.history_outlined,
                color: _currentIndex == 2 ? kProfitColor : kTextSecondary,
              ),
              selectedIcon: const Icon(Icons.history, color: kProfitColor),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.show_chart_outlined,
                color: _currentIndex == 3 ? kProfitColor : kTextSecondary,
              ),
              selectedIcon: const Icon(Icons.show_chart, color: kProfitColor),
              label: 'Charts',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.science_outlined,
                color: _currentIndex == 4 ? kProfitColor : kTextSecondary,
              ),
              selectedIcon: const Icon(Icons.science, color: kProfitColor),
              label: 'Paper',
            ),
            NavigationDestination(
              icon: Stack(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    color: _currentIndex == 5 ? kProfitColor : kTextSecondary,
                  ),
                  if (engineRunning)
                    Positioned(
                      right: 0,
                      top: 0,
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
              selectedIcon: const Icon(Icons.settings, color: kProfitColor),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

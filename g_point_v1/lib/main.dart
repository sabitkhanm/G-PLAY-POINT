import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_controller.dart';
import 'core/motion/page_transitions.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/players/players_screen.dart';
import 'features/ledger/ledger_screen.dart';
import 'features/payments/payments_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/settings/settings_screen.dart';

void main() => runApp(const GPointApp());

class GPointApp extends StatelessWidget {
  const GPointApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController()..refreshSummary(),
      child: Consumer<AppController>(
        builder: (context, app, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'G-POINT',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: app.themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          ),
          home: const ShellScreen(),
        ),
      ),
    );
  }
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final screens = const [
    DashboardScreen(),
    PlayersScreen(),
    LedgerScreen(),
    PaymentsScreen(),
    ExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);
    final destinations = [
      NavigationDestination(icon: const Icon(CupertinoIcons.square_grid_2x2), label: s.dashboard),
      NavigationDestination(icon: const Icon(CupertinoIcons.person_2), label: s.players),
      NavigationDestination(icon: const Icon(CupertinoIcons.list_bullet_rectangle), label: s.ledger),
      NavigationDestination(icon: const Icon(CupertinoIcons.creditcard), label: s.payments),
      NavigationDestination(icon: const Icon(CupertinoIcons.arrow_down_circle), label: s.expenses),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('G-POINT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        actions: [
          IconButton(
            tooltip: s.settings,
            onPressed: () => Navigator.of(context).push(IosPageRoute(page: const SettingsScreen())),
            icon: const Icon(CupertinoIcons.gear_alt),
          ),
        ],
      ),
      body: IndexedStack(index: app.tabIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tabIndex,
        onDestinationSelected: (i) => context.read<AppController>().setTab(i),
        destinations: destinations,
      ),
    );
  }
}

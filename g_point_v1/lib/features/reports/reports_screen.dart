import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AppDatabase _db = AppDatabase.instance;

  DashboardSummary? _summary;
  double _payments = 0;
  double _expenses = 0;
  int _pointsAdded = 0;
  int _pointsSpent = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _db.getSummary(),
        _db.getTotalPayments(),
        _db.getTotalExpenses(),
        _db.getTotalPointsAdded(),
        _db.getTotalPointsSpent(),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = results[0] as DashboardSummary;
        _payments = results[1] as double;
        _expenses = results[2] as double;
        _pointsAdded = results[3] as int;
        _pointsSpent = results[4] as int;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load report.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double get _netBalance => _payments - _expenses;

  String _money(double value) {
    return '৳${value.toStringAsFixed(2)}';
  }

  Widget _summaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    bool negative = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final iconColor = negative
        ? scheme.error
        : scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _summary == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final summary = _summary;

    if (summary == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _loadReport,
          icon: const Icon(CupertinoIcons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Business Report',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadReport,
                icon: const Icon(
                  CupertinoIcons.refresh,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Complete financial and points overview',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 18),

          _summaryCard(
            context: context,
            title: 'Net Balance',
            value: _money(_netBalance),
            icon: CupertinoIcons.chart_bar_circle,
            negative: _netBalance < 0,
          ),

          const SizedBox(height: 10),

          _summaryCard(
            context: context,
            title: 'Total Payments',
            value: _money(_payments),
            icon: CupertinoIcons.arrow_down_circle_fill,
          ),

          const SizedBox(height: 10),

          _summaryCard(
            context: context,
            title: 'Total Expenses',
            value: _money(_expenses),
            icon: CupertinoIcons.arrow_up_circle_fill,
            negative: true,
          ),

          _sectionTitle(
            context,
            'Business Overview',
          ),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Column(
                children: [
                  _statRow(
                    context,
                    icon: CupertinoIcons.person_2_fill,
                    title: 'Total Players',
                    value: '${summary.players}',
                  ),
                  const Divider(height: 1),
                  _statRow(
                    context,
                    icon: CupertinoIcons.star_fill,
                    title: 'Current Points',
                    value: '${summary.points}',
                  ),
                  const Divider(height: 1),
                  _statRow(
                    context,
                    icon: CupertinoIcons.add_circled_solid,
                    title: 'Points Added / Refunded',
                    value: '$_pointsAdded',
                  ),
                  const Divider(height: 1),
                  _statRow(
                    context,
                    icon: CupertinoIcons.minus_circle_fill,
                    title: 'Points Spent',
                    value: '$_pointsSpent',
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(
            context,
            'Today',
          ),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Column(
                children: [
                  _statRow(
                    context,
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    title: 'Today Payments',
                    value: _money(summary.todayPayments),
                  ),
                  const Divider(height: 1),
                  _statRow(
                    context,
                    icon: CupertinoIcons.arrow_down_circle_fill,
                    title: 'Today Expenses',
                    value: _money(summary.todayExpenses),
                  ),
                  const Divider(height: 1),
                  _statRow(
                    context,
                    icon: CupertinoIcons.equal_circle_fill,
                    title: 'Today Net',
                    value: _money(
                      summary.todayPayments -
                          summary.todayExpenses,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '1 Point = ৳1',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
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

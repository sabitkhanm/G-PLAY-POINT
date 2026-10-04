import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/premium_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppController>().refreshSummary()); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);
    final data = app.summary;
    return RefreshIndicator(
      onRefresh: app.refreshSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _welcome(app),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: MotionTokens.normal,
            child: data == null ? const _SummaryLoading(key: ValueKey('load')) : GridView.count(
              key: ValueKey(data.players.toString() + data.points.toString()),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _StatCard(label: s.totalPlayers, icon: CupertinoIcons.person_2, child: AnimatedCounter(value: data.players, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
                _StatCard(label: s.totalPoints, icon: CupertinoIcons.gift, child: AnimatedCounter(value: data.points, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
                _MoneyCard(label: s.todayPayments, amount: data.todayPayments, icon: CupertinoIcons.arrow_down_left),
                _MoneyCard(label: s.todayExpenses, amount: data.todayExpenses, icon: CupertinoIcons.arrow_up_right),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PremiumCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('1 Point = ৳1', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(app.bangla ? 'প্রতিটি পয়েন্ট পরিবর্তন লেজারে তারিখ ও সময়সহ সংরক্ষিত হয়।' : 'Every point change is stored in the ledger with date and time.', style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _welcome(AppController app) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(app.bangla ? 'আজকের ম্যানেজমেন্ট' : 'Today at a glance', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
  );
}

class _StatCard extends StatelessWidget {
  final String label; final IconData icon; final Widget child;
  const _StatCard({required this.label, required this.icon, required this.child});
  @override Widget build(BuildContext context) => PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 22), const Spacer(), child, const SizedBox(height: 2), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)]));
}
class _MoneyCard extends StatelessWidget {
  final String label; final double amount; final IconData icon;
  const _MoneyCard({required this.label, required this.amount, required this.icon});
  @override Widget build(BuildContext context) => PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 22), const Spacer(), Text('৳${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)]));
}
class _SummaryLoading extends StatelessWidget { const _SummaryLoading({super.key}); @override Widget build(BuildContext c) => const SizedBox(height: 270, child: Center(child: CircularProgressIndicator.adaptive())); }

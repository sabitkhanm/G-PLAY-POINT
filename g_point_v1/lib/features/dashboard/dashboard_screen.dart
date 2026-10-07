import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_controller.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models.dart';
import 'widgets/dashboard_stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppController>().refreshSummary(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = AppStrings(app.bangla);
    final summary = app.summary;
    final theme = Theme.of(context);

    return RefreshIndicator.adaptive(
      onRefresh: app.refreshSummary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _DashboardHeader(strings: strings),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: MotionTokens.page,
                switchInCurve: MotionTokens.standardCurve,
                switchOutCurve: Curves.easeIn,
                child: summary == null
                    ? const _DashboardLoading(key: ValueKey('loading'))
                    : _DashboardContent(
                        key: ValueKey(
                          '${summary.players}-${summary.points}-'
                          '${summary.todayPayments}-${summary.todayExpenses}',
                        ),
                        summary: summary,
                        strings: strings,
                      ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverToBoxAdapter(
              child: PremiumCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        CupertinoIcons.gift,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1 Point = ৳1',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            app.bangla
                                ? 'পয়েন্টের প্রতিটি পরিবর্তন লেজারে সংরক্ষিত হয়।'
                                : 'Every point change is recorded in the ledger.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AppStrings strings;
  const _DashboardHeader({required this.strings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.dashboard,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          strings.bn
              ? 'আপনার ব্যবসার আজকের অবস্থা এক নজরে'
              : 'Your business at a glance',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;
  final AppStrings strings;

  const _DashboardContent({
    super.key,
    required this.summary,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: strings.bn ? 'সারাংশ' : 'Overview',
          subtitle: strings.bn
              ? 'বর্তমান ব্যবসার মূল পরিসংখ্যান'
              : 'Key business metrics',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: [
            DashboardStatCard(
              icon: CupertinoIcons.person_2_fill,
              label: strings.totalPlayers,
              accent: DashboardStatAccent.primary,
              value: AnimatedCounter(value: summary.players),
            ),
            DashboardStatCard(
              icon: CupertinoIcons.gift_fill,
              label: strings.totalPoints,
              accent: DashboardStatAccent.info,
              value: AnimatedCounter(value: summary.points),
            ),
            DashboardStatCard(
              icon: CupertinoIcons.arrow_down_circle_fill,
              label: strings.todayPayments,
              accent: DashboardStatAccent.success,
              value: _MoneyValue(amount: summary.todayPayments),
            ),
            DashboardStatCard(
              icon: CupertinoIcons.arrow_up_circle_fill,
              label: strings.todayExpenses,
              accent: DashboardStatAccent.warning,
              value: _MoneyValue(amount: summary.todayExpenses),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoneyValue extends StatelessWidget {
  final double amount;
  const _MoneyValue({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Text(
      '৳${amount.toStringAsFixed(2)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.3,
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

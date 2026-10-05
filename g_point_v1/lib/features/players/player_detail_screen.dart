import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/motion/motion_tokens.dart';
import '../../data/models.dart';

class PlayerDetailScreen extends StatefulWidget {
  final int playerId;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  Future<void> _changePoints(String type) async {
    final app = context.read<AppController>();
    final strings = AppStrings(app.bangla);

    final controller = TextEditingController();

    final points = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        String title;

        if (type == 'SPEND') {
          title = strings.spendPoints;
        } else if (type == 'REFUND') {
          title = strings.refundPoints;
        } else {
          title = strings.addPoints;
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(sheetContext).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.amount,
                  prefixIcon: const Icon(CupertinoIcons.number),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value = int.tryParse(
                      controller.text.trim(),
                    );

                    if (value != null && value > 0) {
                      Navigator.pop(sheetContext, value);
                    }
                  },
                  child: Text(strings.save),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (points == null || points <= 0) {
      return;
    }

    try {
      await app.db.applyPoints(
        playerId: widget.playerId,
        type: type,
        points: points,
      );

      await app.refreshSummary();

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
                  'Bad state: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = AppStrings(app.bangla);

    return FutureBuilder<Player?>(
      future: app.db.getPlayer(widget.playerId),
      builder: (context, snapshot) {
        final player = snapshot.data;

        if (player == null) {
          return const Scaffold(
            body: Center(
              child: Text('Player not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(player.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${player.points}',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      strings.bn
                          ? 'বর্তমান পয়েন্ট'
                          : 'Current points',
                    ),
                    const SizedBox(height: 16),

                    if (player.email.isNotEmpty)
                      Text(player.email),

                    if (player.phone.isNotEmpty)
                      Text(player.phone),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _changePoints('ADD'),
                      icon: const Icon(CupertinoIcons.add),
                      label: Text(strings.addPoints),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _changePoints('SPEND'),
                      icon: const Icon(CupertinoIcons.minus),
                      label: Text(strings.spendPoints),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () => _changePoints('REFUND'),
                icon: const Icon(
                  CupertinoIcons.arrow_counterclockwise,
                ),
                label: Text(strings.refundPoints),
              ),

              const SizedBox(height: 24),

              Text(
                strings.history,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 10),

              FutureBuilder<List<LedgerEntry>>(
                future: app.db.getLedger(widget.playerId),
                builder: (context, ledgerSnapshot) {
                  final entries =
                      ledgerSnapshot.data ?? const <LedgerEntry>[];

                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(strings.noData),
                      ),
                    );
                  }

                  return Column(
                    children: entries.map(
                      (entry) {
                        final isSpend = entry.type == 'SPEND';
                        final isRefund = entry.type == 'REFUND';

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 9,
                          ),
                          child: AnimatedContainer(
                            duration: MotionTokens.fast,
                            curve: MotionTokens.curve,
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              tileColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              leading: Icon(
                                isSpend
                                    ? CupertinoIcons
                                        .minus_circle
                                    : isRefund
                                        ? CupertinoIcons
                                            .arrow_counterclockwise_circle
                                        : CupertinoIcons
                                            .add_circled,
                                color: isSpend
                                    ? Theme.of(context)
                                        .colorScheme
                                        .error
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary,
                              ),
                              title: Text(
                                '${entry.type} • ${entry.points}',
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(entry.createdAt),
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

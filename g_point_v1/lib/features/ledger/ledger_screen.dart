import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../data/models.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = AppStrings(app.bangla);

    return FutureBuilder<List<Player>>(
      future: app.db.getPlayers(),
      builder: (context, snapshot) {
        final players = snapshot.data ?? const <Player>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            Text(
              strings.ledger,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            if (players.isEmpty && snapshot.connectionState != ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Text(strings.noData),
                ),
              ),

            ...players.map(
              (player) => FutureBuilder<List<LedgerEntry>>(
                future: app.db.getLedger(player.id!),
                builder: (context, ledgerSnapshot) {
                  final entries =
                      ledgerSnapshot.data ?? const <LedgerEntry>[];

                  if (entries.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final recentEntries = entries.take(10).toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      title: Text(
                        player.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text('${player.points} pts'),
                      children: recentEntries.map(
                        (entry) {
                          final isSpend = entry.type == 'SPEND';
                          final isRefund = entry.type == 'REFUND';

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isSpend
                                  ? Icons.remove_circle_outline
                                  : isRefund
                                      ? Icons.undo
                                      : Icons.add_circle_outline,
                              color: isSpend
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              '${entry.type} • ${entry.points}',
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(entry.createdAt),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

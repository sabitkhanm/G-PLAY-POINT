import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/motion/page_transitions.dart';
import '../../data/models.dart';
import 'player_form_screen.dart';

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
  late Future<Player?> _playerFuture;

  @override
  void initState() {
    super.initState();
    _reloadPlayer();
  }

  void _reloadPlayer() {
    final app = context.read<AppController>();
    _playerFuture = app.db.getPlayer(widget.playerId);
  }

  Future<void> _editPlayer(Player player) async {
    final result = await Navigator.of(context).push(
      IosPageRoute(
        page: PlayerFormScreen(player: player),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        _reloadPlayer();
      });
    }
  }

  Future<void> _deletePlayer(Player player) async {
    final app = context.read<AppController>();
    final s = AppStrings(app.bangla);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            s.bn ? 'প্লেয়ার ডিলিট করবেন?' : 'Delete Player?',
          ),
          content: Text(
            s.bn
                ? '“${player.name}” এবং তার Point History ও Payment History মুছে যাবে। এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।'
                : '“${player.name}”, their point history and payment history will be permanently deleted. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                s.bn ? 'ডিলিট' : 'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final playerId = player.id;

      if (playerId == null) {
        throw StateError(
          s.bn ? 'প্লেয়ার ID পাওয়া যায়নি।' : 'Player ID not found.',
        );
      }

      await app.db.deletePlayer(playerId);
      await app.refreshSummary();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(error),
          ),
        ),
      );
    }
  }

  Future<void> _changePoints(String type) async {
    final app = context.read<AppController>();
    final s = AppStrings(app.bangla);

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    String title;
    IconData icon;

    if (type == 'SPEND') {
      title = s.spendPoints;
      icon = CupertinoIcons.minus_circle;
    } else if (type == 'REFUND') {
      title = s.refundPoints;
      icon = CupertinoIcons.arrow_counterclockwise_circle;
    } else {
      title = s.addPoints;
      icon = CupertinoIcons.add_circled;
    }

    final result = await showModalBottomSheet<_PointActionResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            MediaQuery.of(sheetContext).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 38,
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.amount,
                    prefixIcon: const Icon(CupertinoIcons.number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: noteController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: s.bn ? 'নোট (ঐচ্ছিক)' : 'Note (optional)',
                    hintText: s.bn
                        ? 'যেমন: ম্যাচের পুরস্কার / কেনাকাটা / ভুল পয়েন্ট ফেরত'
                        : 'e.g. Match reward / purchase / point correction',
                    prefixIcon: const Icon(CupertinoIcons.pencil),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final points = int.tryParse(
                        amountController.text.trim(),
                      );

                      if (points == null || points <= 0) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.bn
                                  ? 'সঠিক পয়েন্ট লিখুন।'
                                  : 'Enter a valid point amount.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                        _PointActionResult(
                          points: points,
                          note: noteController.text.trim(),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.checkmark),
                    label: Text(s.save),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (result == null) return;

    try {
      await app.db.applyPoints(
        playerId: widget.playerId,
        type: type,
        points: result.points,
        note: result.note,
      );

      await app.refreshSummary();

      if (!mounted) return;

      setState(() {
        _reloadPlayer();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.bn
                ? 'পয়েন্ট সফলভাবে আপডেট হয়েছে।'
                : 'Points updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(error),
          ),
        ),
      );
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);

    return FutureBuilder<Player?>(
      future: _playerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _cleanError(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final player = snapshot.data;

        if (player == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                s.bn ? 'প্লেয়ার পাওয়া যায়নি।' : 'Player not found.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(player.name),
            actions: [
              IconButton(
                tooltip: s.bn ? 'এডিট' : 'Edit',
                onPressed: () => _editPlayer(player),
                icon: const Icon(CupertinoIcons.pencil),
              ),
              IconButton(
                tooltip: s.bn ? 'ডিলিট' : 'Delete',
                onPressed: () => _deletePlayer(player),
                icon: const Icon(CupertinoIcons.trash),
              ),
            ],
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async {
              setState(() {
                _reloadPlayer();
              });

              await _playerFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildPlayerCard(context, player, s),

                const SizedBox(height: 16),

                _buildPointActions(context, s),

                const SizedBox(height: 26),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.history,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                      s.bn ? 'সাম্প্রতিক' : 'Recent',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                FutureBuilder<List<LedgerEntry>>(
                  future: app.db.getLedger(widget.playerId),
                  builder: (context, ledgerSnapshot) {
                    if (ledgerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    if (ledgerSnapshot.hasError) {
                      return _EmptyCard(
                        message: _cleanError(ledgerSnapshot.error!),
                      );
                    }

                    final entries =
                        ledgerSnapshot.data ?? const <LedgerEntry>[];

                    if (entries.isEmpty) {
                      return _EmptyCard(
                        message: s.noData,
                      );
                    }

                    return Column(
                      children: entries.map(
                        (entry) => _buildLedgerItem(
                          context,
                          entry,
                          s,
                        ),
                      ).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    Player player,
    AppStrings s,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: scheme.primary.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 29,
                child: Text(
                  player.name.trim().isEmpty
                      ? '?'
                      : player.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

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
            s.bn ? 'বর্তমান পয়েন্ট' : 'Current points',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 18),

          if (player.email.isNotEmpty)
            _InfoRow(
              icon: CupertinoIcons.mail,
              text: player.email,
            ),

          if (player.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: CupertinoIcons.phone,
              text: player.phone,
            ),
          ],

          if (player.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                player.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointActions(
    BuildContext context,
    AppStrings s,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _changePoints('ADD'),
                icon: const Icon(CupertinoIcons.add),
                label: Text(s.addPoints),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _changePoints('SPEND'),
                icon: const Icon(CupertinoIcons.minus),
                label: Text(s.spendPoints),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _changePoints('REFUND'),
            icon: const Icon(
              CupertinoIcons.arrow_counterclockwise,
            ),
            label: Text(s.refundPoints),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerItem(
    BuildContext context,
    LedgerEntry entry,
    AppStrings s,
  ) {
    final scheme = Theme.of(context).colorScheme;

    final isSpend = entry.type == 'SPEND';
    final isRefund = entry.type == 'REFUND';

    final title = isSpend
        ? s.spendPoints
        : isRefund
            ? s.refundPoints
            : s.addPoints;

    final icon = isSpend
        ? CupertinoIcons.minus_circle
        : isRefund
            ? CupertinoIcons.arrow_counterclockwise_circle
            : CupertinoIcons.add_circled;

    final iconColor = isSpend
        ? scheme.error
        : isRefund
            ? scheme.tertiary
            : scheme.primary;

    final prefix = isSpend ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        curve: MotionTokens.standardCurve,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 27,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(entry.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (entry.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.note,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$prefix${entry.points}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointActionResult {
  final int points;
  final String note;

  const _PointActionResult({
    required this.points,
    required this.note,
  });
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

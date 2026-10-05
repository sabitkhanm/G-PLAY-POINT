import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/motion/page_transitions.dart';
import '../../core/widgets/premium_card.dart';
import '../../data/models.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String search = '';
  String methodFilter = 'ALL';

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openPaymentForm({Payment? payment}) async {
    final app = context.read<AppController>();

    final result = await Navigator.of(context).push(
      IosPageRoute(
        page: _PaymentFormScreen(
          payment: payment,
        ),
      ),
    );

    if (result == true && mounted) {
      await app.refreshSummary();
      await _reload();
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final app = context.read<AppController>();
    final s = AppStrings(app.bangla);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            s.bn ? 'পেমেন্ট ডিলিট করবেন?' : 'Delete Payment?',
          ),
          content: Text(
            s.bn
                ? 'এই পেমেন্ট রেকর্ডটি স্থায়ীভাবে মুছে যাবে।'
                : 'This payment record will be permanently deleted.',
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
      if (payment.id == null) {
        throw StateError(
          s.bn ? 'Payment ID পাওয়া যায়নি।' : 'Payment ID not found.',
        );
      }

      await app.db.deletePayment(payment.id!);
      await app.refreshSummary();

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.bn
                ? 'পেমেন্ট ডিলিট হয়েছে।'
                : 'Payment deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(error)),
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

  bool _matches(Payment payment, Map<int, Player> players) {
    final query = search.trim().toLowerCase();

    final methodMatches =
        methodFilter == 'ALL' || payment.method == methodFilter;

    if (!methodMatches) return false;

    if (query.isEmpty) return true;

    final playerName = payment.playerId == null
        ? ''
        : players[payment.playerId!]?.name ?? '';

    return playerName.toLowerCase().contains(query) ||
        payment.method.toLowerCase().contains(query) ||
        payment.reference.toLowerCase().contains(query) ||
        payment.note.toLowerCase().contains(query) ||
        payment.amount.toString().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);

    return FutureBuilder<List<Player>>(
      future: app.db.getPlayers(),
      builder: (context, playerSnapshot) {
        final playerList =
            playerSnapshot.data ?? const <Player>[];

        final players = <int, Player>{
          for (final player in playerList)
            if (player.id != null) player.id!: player,
        };

        return FutureBuilder<List<Payment>>(
          future: app.db.getPayments(),
          builder: (context, paymentSnapshot) {
            if (paymentSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }

            if (paymentSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _cleanError(paymentSnapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final allPayments =
                paymentSnapshot.data ?? const <Payment>[];

            final payments = allPayments
                .where((payment) => _matches(payment, players))
                .toList();

            final total = payments.fold<double>(
              0,
              (sum, payment) => sum + payment.amount,
            );

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openPaymentForm(),
                icon: const Icon(CupertinoIcons.add),
                label: Text(
                  s.bn ? 'পেমেন্ট যোগ' : 'Add Payment',
                ),
              ),
              body: RefreshIndicator.adaptive(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    110,
                  ),
                  children: [
                    Text(
                      s.payments,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),

                    const SizedBox(height: 14),

                    _buildSummaryCard(
                      context,
                      s,
                      total,
                      payments.length,
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      onChanged: (value) {
                        setState(() {
                          search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: s.bn
                            ? 'প্লেয়ার, মাধ্যম, রেফারেন্স দিয়ে খুঁজুন'
                            : 'Search player, method or reference',
                        prefixIcon: const Icon(
                          CupertinoIcons.search,
                        ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip(
                            label: s.bn ? 'সব' : 'All',
                            value: 'ALL',
                          ),
                          _filterChip(
                            label: 'Cash',
                            value: 'Cash',
                          ),
                          _filterChip(
                            label: 'bKash',
                            value: 'bKash',
                          ),
                          _filterChip(
                            label: 'Nagad',
                            value: 'Nagad',
                          ),
                          _filterChip(
                            label: 'Bank',
                            value: 'Bank',
                          ),
                          _filterChip(
                            label: 'Other',
                            value: 'Other',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (payments.isEmpty)
                      _EmptyPaymentCard(
                        message: s.noData,
                      ),

                    ...payments.map(
                      (payment) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _PaymentCard(
                          payment: payment,
                          player: payment.playerId == null
                              ? null
                              : players[payment.playerId!],
                          s: s,
                          onEdit: () =>
                              _openPaymentForm(payment: payment),
                          onDelete: () =>
                              _deletePayment(payment),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    AppStrings s,
    double total,
    int count,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.bn ? 'মোট পেমেন্ট' : 'Total Payments',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  '৳${total.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  s.bn ? 'রেকর্ড' : 'Records',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
  }) {
    final selected = methodFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            methodFilter = value;
          });
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final Player? player;
  final AppStrings s;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentCard({
    required this.payment,
    required this.player,
    required this.s,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _methodIcon() {
    switch (payment.method) {
      case 'bKash':
        return CupertinoIcons.money_dollar_circle;
      case 'Nagad':
        return CupertinoIcons.money_dollar;
      case 'Bank':
        return CupertinoIcons.building_2_fill;
      case 'Cash':
        return CupertinoIcons.money_dollar;
      default:
        return CupertinoIcons.creditcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            child: Icon(_methodIcon()),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '৳${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment.method,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (player != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    player!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (payment.reference.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${s.reference}: ${payment.reference}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (payment.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(payment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.pencil),
                    const SizedBox(width: 10),
                    Text(s.bn ? 'এডিট' : 'Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.trash,
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),
                    const SizedBox(width: 10),
                    Text(s.bn ? 'ডিলিট' : 'Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPaymentCard extends StatelessWidget {
  final String message;

  const _EmptyPaymentCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.creditcard,
            size: 42,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PaymentFormScreen extends StatefulWidget {
  final Payment? payment;

  const _PaymentFormScreen({
    this.payment,
  });

  @override
  State<_PaymentFormScreen> createState() =>
      _PaymentFormScreenState();
}

class _PaymentFormScreenState
    extends State<_PaymentFormScreen> {
  late final TextEditingController amountController;
  late final TextEditingController referenceController;
  late final TextEditingController noteController;

  int? playerId;
  String method = 'Cash';
  bool saving = false;

  bool get isEdit => widget.payment != null;

  @override
  void initState() {
    super.initState();

    final payment = widget.payment;

    amountController = TextEditingController(
      text: payment == null
          ? ''
          : payment.amount.toStringAsFixed(2),
    );

    referenceController = TextEditingController(
      text: payment?.reference ?? '',
    );

    noteController = TextEditingController(
      text: payment?.note ?? '',
    );

    playerId = payment?.playerId;
    method = payment?.method ?? 'Cash';
  }

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final app = context.read<AppController>();
    final s = AppStrings(app.bangla);

    final amount = double.tryParse(
      amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      _showError(
        s.bn
            ? 'সঠিক পেমেন্ট amount লিখুন।'
            : 'Enter a valid payment amount.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final old = widget.payment;

      final payment = Payment(
        id: old?.id,
        playerId: playerId,
        amount: amount,
        method: method,
        reference: referenceController.text.trim(),
        note: noteController.text.trim(),
        createdAt: old?.createdAt ?? DateTime.now(),
      );

      if (isEdit) {
        await app.db.updatePayment(payment);
      } else {
        await app.db.insertPayment(payment);
      }

      await app.refreshSummary();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      _showError(
        error
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('Invalid argument(s): ', ''),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (s.bn ? 'পেমেন্ট এডিট করুন' : 'Edit Payment')
              : (s.bn ? 'পেমেন্ট যোগ করুন' : 'Add Payment'),
        ),
      ),
      body: FutureBuilder<List<Player>>(
        future: app.db.getPlayers(),
        builder: (context, snapshot) {
          final players =
              snapshot.data ?? const <Player>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(
                label: s.amount,
                controller: amountController,
                icon: CupertinoIcons.money_dollar,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int?>(
                initialValue: playerId,
                decoration: InputDecoration(
                  labelText: s.players,
                  prefixIcon: const Icon(
                    CupertinoIcons.person,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      s.bn
                          ? 'কোনো প্লেয়ার নয়'
                          : 'No player',
                    ),
                  ),
                  ...players.map(
                    (player) => DropdownMenuItem<int?>(
                      value: player.id,
                      child: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) {
                        setState(() {
                          playerId = value;
                        });
                      },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: InputDecoration(
                  labelText: s.method,
                  prefixIcon: const Icon(
                    CupertinoIcons.creditcard,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: const [
                  'Cash',
                  'bKash',
                  'Nagad',
                  'Bank',
                  'Other',
                ]
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        setState(() {
                          method = value ?? 'Cash';
                        });
                      },
              ),

              const SizedBox(height: 12),

              _field(
                label: s.reference,
                controller: referenceController,
                icon: CupertinoIcons.number,
              ),

              const SizedBox(height: 12),

              _field(
                label: s.notes,
                controller: noteController,
                icon: CupertinoIcons.pencil,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.checkmark,
                        ),
                  label: Text(
                    isEdit
                        ? (s.bn ? 'আপডেট করুন' : 'Update')
                        : s.save,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

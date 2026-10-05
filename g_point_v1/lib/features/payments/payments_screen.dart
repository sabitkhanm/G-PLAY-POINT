import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../data/models.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  Future<void> _addPayment() async {
    final app = context.read<AppController>();
    final strings = AppStrings(app.bangla);

    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final noteController = TextEditingController();

    String method = 'Cash';
    int? playerId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.payments,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),

                    FutureBuilder<List<Player>>(
                      future: app.db.getPlayers(),
                      builder: (context, snapshot) {
                        final players =
                            snapshot.data ?? const <Player>[];

                        return DropdownButtonFormField<int>(
                          value: playerId,
                          items: players.map(
                            (player) {
                              return DropdownMenuItem<int>(
                                value: player.id,
                                child: Text(player.name),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            setLocalState(() {
                              playerId = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: strings.players,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: strings.amount,
                        prefixText: '৳ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: method,
                      items: const [
                        'Cash',
                        'bKash',
                        'Nagad',
                        'Bank',
                        'Other',
                      ].map(
                        (item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        setLocalState(() {
                          method = value ?? 'Cash';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: strings.method,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: referenceController,
                      decoration: InputDecoration(
                        labelText: strings.reference,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: strings.notes,
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
                          Navigator.pop(sheetContext, true);
                        },
                        child: Text(strings.save),
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

    if (saved != true) {
      return;
    }

    final amount = double.tryParse(
      amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      return;
    }

    await app.db.insertPayment(
      Payment(
        playerId: playerId,
        amount: amount,
        method: method,
        reference: referenceController.text.trim(),
        note: noteController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );

    await app.refreshSummary();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = AppStrings(app.bangla);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPayment,
        icon: const Icon(CupertinoIcons.add),
        label: Text(strings.save),
      ),
      body: FutureBuilder<List<Payment>>(
        future: app.db.getPayments(),
        builder: (context, snapshot) {
          final payments = snapshot.data ?? const <Payment>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            children: [
              Text(
                strings.payments,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),

              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(strings.noData),
                  ),
                ),

              ...payments.map(
                (payment) {
                  final reference = payment.reference.isEmpty
                      ? ''
                      : ' • ${payment.reference}';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        CupertinoIcons.creditcard,
                      ),
                      title: Text(
                        '৳${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${payment.method}$reference\n'
                        '${DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt)}',
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

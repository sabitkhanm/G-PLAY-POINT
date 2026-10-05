import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/widgets/premium_card.dart';
import '../../data/models.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _search = TextEditingController();

  Future<List<Expense>>? _future;

  String _query = '';
  String _category = 'All';

  static const _categories = [
    'General',
    'Transport',
    'Internet',
    'Tools',
    'Salary',
    'Marketing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    _future = context.read<AppController>().db.getExpenses();
  }

  String _label(String value, bool bn) {
    if (!bn) return value;

    const map = {
      'All': 'সব',
      'General': 'সাধারণ',
      'Transport': 'যাতায়াত',
      'Internet': 'ইন্টারনেট',
      'Tools': 'টুলস',
      'Salary': 'বেতন',
      'Marketing': 'মার্কেটিং',
      'Other': 'অন্যান্য',
    };

    return map[value] ?? value;
  }

  List<Expense> _filter(List<Expense> all) {
    return all.where((e) {
      final q = _query.trim().toLowerCase();

      final categoryMatch =
          _category == 'All' || e.category == _category;

      final searchMatch =
          q.isEmpty ||
          e.category.toLowerCase().contains(q) ||
          e.note.toLowerCase().contains(q) ||
          e.amount.toString().contains(q);

      return categoryMatch && searchMatch;
    }).toList();
  }

  Future<void> _form({Expense? expense}) async {
    final app = context.read<AppController>();
    final s = AppStrings(app.bangla);

    final amount = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );

    final note = TextEditingController(
      text: expense?.note ?? '',
    );

    String category = expense?.category ?? 'General';

    DateTime date = expense?.createdAt ?? DateTime.now();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      expense == null
                          ? (s.bn ? 'খরচ যোগ করুন' : 'Add Expense')
                          : (s.bn ? 'খরচ এডিট করুন' : 'Edit Expense'),
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: amount,
                      autofocus: expense == null,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: s.amount,
                        prefixText: '৳ ',
                        prefixIcon: const Icon(
                          CupertinoIcons.money_dollar_circle,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: _categories
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(_label(v, s.bn)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setLocal(() {
                          category = v ?? category;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: s.category,
                        prefixIcon: const Icon(
                          CupertinoIcons.tag,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setLocal(() {
                            date = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              date.hour,
                              date.minute,
                            );
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.bn ? 'তারিখ' : 'Date',
                          prefixIcon: const Icon(
                            CupertinoIcons.calendar,
                          ),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(date),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: note,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: s.notes,
                        prefixIcon: const Icon(
                          CupertinoIcons.text_alignleft,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    FilledButton.icon(
                      onPressed: () async {
                        final value =
                            double.tryParse(amount.text.trim());

                        if (value == null || value <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                s.bn
                                    ? 'সঠিক পরিমাণ লিখুন'
                                    : 'Enter a valid amount',
                              ),
                            ),
                          );
                          return;
                        }

                        final item = Expense(
                          id: expense?.id,
                          amount: value,
                          category: category,
                          note: note.text.trim(),
                          createdAt: date,
                        );

                        if (expense == null) {
                          await app.db.insertExpense(item);
                        } else {
                          await app.db.updateExpense(item);
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.checkmark_alt,
                      ),
                      label: Text(s.save),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    amount.dispose();
    note.dispose();

    if (saved == true && mounted) {
      await app.refreshSummary();
      setState(_load);
    }
  }

  Future<void> _delete(Expense expense) async {
    if (expense.id == null) return;

    final app = context.read<AppController>();
    final s = AppStrings(app.bangla);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            s.bn ? 'খরচ মুছে ফেলবেন?' : 'Delete expense?',
          ),
          content: Text(
            s.bn
                ? 'এই রেকর্ডটি স্থায়ীভাবে মুছে যাবে।'
                : 'This expense will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                s.bn ? 'মুছে ফেলুন' : 'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await app.db.deleteExpense(expense.id!);
      await app.refreshSummary();

      if (mounted) {
        setState(_load);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(CupertinoIcons.add),
        label: Text(
          s.bn ? 'খরচ যোগ' : 'Add Expense',
        ),
      ),

      body: FutureBuilder<List<Expense>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          final items = _filter(
            snapshot.data ?? const <Expense>[],
          );

          final total = items.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          return RefreshIndicator.adaptive(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                120,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.expenses,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(_load);
                      },
                      icon: const Icon(
                        CupertinoIcons.refresh,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                PremiumCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .10),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.bn
                                  ? 'মোট খরচ'
                                  : 'Total Expense',
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '৳${total.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        items.length.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _search,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: s.bn
                        ? 'ক্যাটাগরি বা নোট দিয়ে খুঁজুন'
                        : 'Search category or note',
                    prefixIcon: const Icon(
                      CupertinoIcons.search,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(
                              CupertinoIcons.clear_circled,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (ctx, index) {
                      final value = index == 0
                          ? 'All'
                          : _categories[index - 1];

                      return ChoiceChip(
                        label: Text(
                          _label(value, s.bn),
                        ),
                        selected: _category == value,
                        onSelected: (_) {
                          setState(() {
                            _category = value;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 70),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons
                                .money_dollar_circle,
                            size: 52,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .28),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.noData,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...items.map(
                    (expense) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10),
                      child: PremiumCard(
                        onTap: () =>
                            _form(expense: expense),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: .10),
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                              child: Icon(
                                CupertinoIcons
                                    .arrow_down_circle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .error,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _label(
                                      expense.category,
                                      s.bn,
                                    ),
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),

                                  if (expense
                                      .note.isNotEmpty)
                                    Text(
                                      expense.note,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),

                                  const SizedBox(height: 4),

                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(
                                      expense.createdAt,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '−৳${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                    fontWeight:
                                        FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    CupertinoIcons
                                        .ellipsis_circle,
                                    size: 21,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _form(
                                        expense: expense,
                                      );
                                    } else {
                                      _delete(expense);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        s.bn
                                            ? 'এডিট'
                                            : 'Edit',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        s.bn
                                            ? 'ডিলিট'
                                            : 'Delete',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

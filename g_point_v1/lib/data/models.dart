class Player {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final int points;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Player({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.points = 0,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Player copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    int? points,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Player(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        points: points ?? this.points,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class LedgerEntry {
  final int? id;
  final int playerId;
  final String type; // ADD, SPEND, REFUND
  final int points;
  final String note;
  final DateTime createdAt;

  const LedgerEntry({
    this.id,
    required this.playerId,
    required this.type,
    required this.points,
    this.note = '',
    required this.createdAt,
  });
}

class Payment {
  final int? id;
  final int? playerId;
  final double amount;
  final String method;
  final String reference;
  final String note;
  final DateTime createdAt;

  const Payment({
    this.id,
    this.playerId,
    required this.amount,
    required this.method,
    this.reference = '',
    this.note = '',
    required this.createdAt,
  });
}

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String note;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.createdAt,
  });
}

class DashboardSummary {
  final int players;
  final int points;
  final double todayPayments;
  final double todayExpenses;

  const DashboardSummary({
    required this.players,
    required this.points,
    required this.todayPayments,
    required this.todayExpenses,
  });
}

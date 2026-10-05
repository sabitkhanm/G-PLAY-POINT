import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  static const int _databaseVersion = 2;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'g_point.db');

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _db!;
  }

  // ============================================================
  // DATABASE CREATE
  // ============================================================

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT '',
        points INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE point_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        points INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        reference TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY(player_id) REFERENCES players(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'POINTS',
        value REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        player_id INTEGER,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        used_at INTEGER,
        FOREIGN KEY(player_id) REFERENCES players(id)
      )
    ''');

    await _createIndexes(db);
  }

  // ============================================================
  // DATABASE MIGRATION
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vouchers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL DEFAULT '',
          type TEXT NOT NULL DEFAULT 'POINTS',
          value REAL NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          player_id INTEGER,
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          used_at INTEGER,
          FOREIGN KEY(player_id) REFERENCES players(id)
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_vouchers_status
        ON vouchers(status)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_vouchers_created
        ON vouchers(created_at DESC)
      ''');
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_ledger_player
      ON point_ledger(player_id, created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payments_date
      ON payments(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_date
      ON expenses(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vouchers_status
      ON vouchers(status)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vouchers_created
      ON vouchers(created_at DESC)
    ''');
  }

  // ============================================================
  // PLAYER
  // ============================================================

  Future<int> insertPlayer(Player p) async {
    final db = await database;

    return db.insert('players', {
      'name': p.name,
      'phone': p.phone,
      'email': p.email,
      'points': p.points,
      'notes': p.notes,
      'created_at': p.createdAt.millisecondsSinceEpoch,
      'updated_at': p.updatedAt.millisecondsSinceEpoch,
    });
  }

  Future<List<Player>> getPlayers({String query = ''}) async {
    final db = await database;

    final cleanQuery = query.trim();

    final where = cleanQuery.isEmpty
        ? null
        : 'name LIKE ? OR phone LIKE ? OR email LIKE ?';

    final args = cleanQuery.isEmpty
        ? null
        : [
            '%$cleanQuery%',
            '%$cleanQuery%',
            '%$cleanQuery%',
          ];

    final rows = await db.query(
      'players',
      where: where,
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );

    return rows.map(_playerFromRow).toList();
  }

  Future<Player?> getPlayer(int id) async {
    final db = await database;

    final rows = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return _playerFromRow(rows.first);
  }

  Future<int> updatePlayer(Player p) async {
    if (p.id == null) {
      throw ArgumentError('Player ID is required.');
    }

    final db = await database;

    final now = DateTime.now().millisecondsSinceEpoch;

    return db.update(
      'players',
      {
        'name': p.name,
        'phone': p.phone,
        'email': p.email,
        'notes': p.notes,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<int> deletePlayer(int playerId) async {
    final db = await database;

    return db.transaction((txn) async {
      await txn.delete(
        'point_ledger',
        where: 'player_id = ?',
        whereArgs: [playerId],
      );

      await txn.delete(
        'payments',
        where: 'player_id = ?',
        whereArgs: [playerId],
      );

      await txn.update(
        'vouchers',
        {
          'player_id': null,
        },
        where: 'player_id = ?',
        whereArgs: [playerId],
      );

      return txn.delete(
        'players',
        where: 'id = ?',
        whereArgs: [playerId],
      );
    });
  }

  // ============================================================
  // POINTS
  // ============================================================

  Future<void> applyPoints({
    required int playerId,
    required String type,
    required int points,
    String note = '',
  }) async {
    if (points <= 0) {
      throw ArgumentError('Points must be greater than zero.');
    }

    final normalizedType = type.toUpperCase();

    if (!['ADD', 'SPEND', 'REFUND'].contains(normalizedType)) {
      throw ArgumentError('Invalid point transaction type.');
    }

    final db = await database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'players',
        columns: ['points'],
        where: 'id = ?',
        whereArgs: [playerId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw StateError('Player not found.');
      }

      final current = rows.first['points'] as int;

      final delta = normalizedType == 'SPEND' ? -points : points;

      final next = current + delta;

      if (next < 0) {
        throw StateError('Insufficient points.');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await txn.insert(
        'point_ledger',
        {
          'player_id': playerId,
          'type': normalizedType,
          'points': points,
          'note': note,
          'created_at': now,
        },
      );

      await txn.update(
        'players',
        {
          'points': next,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [playerId],
      );
    });
  }

  Future<List<LedgerEntry>> getLedger(int playerId) async {
    final db = await database;

    final rows = await db.query(
      'point_ledger',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'created_at DESC',
    );

    return rows.map(_ledgerFromRow).toList();
  }

  Future<List<LedgerEntry>> getAllLedger({
    int limit = 200,
  }) async {
    final db = await database;

    final rows = await db.query(
      'point_ledger',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows.map(_ledgerFromRow).toList();
  }

  // ============================================================
  // PAYMENTS
  // ============================================================

  Future<int> insertPayment(Payment p) async {
    if (p.amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    final db = await database;

    return db.insert(
      'payments',
      {
        'player_id': p.playerId,
        'amount': p.amount,
        'method': p.method,
        'reference': p.reference,
        'note': p.note,
        'created_at': p.createdAt.millisecondsSinceEpoch,
      },
    );
  }

  Future<int> updatePayment(Payment p) async {
    if (p.id == null) {
      throw ArgumentError('Payment ID is required.');
    }

    if (p.amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    final db = await database;

    return db.update(
      'payments',
      {
        'player_id': p.playerId,
        'amount': p.amount,
        'method': p.method,
        'reference': p.reference,
        'note': p.note,
        'created_at': p.createdAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;

    return db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Payment>> getPayments() async {
    final db = await database;

    final rows = await db.query(
      'payments',
      orderBy: 'created_at DESC',
      limit: 100,
    );

    return rows.map(_paymentFromRow).toList();
  }

  // ============================================================
  // EXPENSES
  // ============================================================

  Future<int> insertExpense(Expense e) async {
    if (e.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final db = await database;

    return db.insert(
      'expenses',
      {
        'amount': e.amount,
        'category': e.category,
        'note': e.note,
        'created_at': e.createdAt.millisecondsSinceEpoch,
      },
    );
  }

  Future<int> updateExpense(Expense e) async {
    if (e.id == null) {
      throw ArgumentError('Expense ID is required.');
    }

    if (e.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final db = await database;

    return db.update(
      'expenses',
      {
        'amount': e.amount,
        'category': e.category,
        'note': e.note,
        'created_at': e.createdAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;

    return db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;

    final rows = await db.query(
      'expenses',
      orderBy: 'created_at DESC',
      limit: 100,
    );

    return rows.map(_expenseFromRow).toList();
  }

  // ============================================================
  // VOUCHERS
  // ============================================================

  Future<int> insertVoucher({
    required String code,
    String title = '',
    String type = 'POINTS',
    double value = 0,
    String status = 'ACTIVE',
    int? playerId,
    String note = '',
  }) async {
    final cleanCode = code.trim();

    if (cleanCode.isEmpty) {
      throw ArgumentError('Voucher code is required.');
    }

    if (value < 0) {
      throw ArgumentError('Voucher value cannot be negative.');
    }

    final db = await database;

    return db.insert(
      'vouchers',
      {
        'code': cleanCode,
        'title': title,
        'type': type.toUpperCase(),
        'value': value,
        'status': status.toUpperCase(),
        'player_id': playerId,
        'note': note,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'used_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, Object?>>> getVouchers() async {
    final db = await database;

    return db.query(
      'vouchers',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, Object?>?> getVoucherByCode(String code) async {
    final db = await database;

    final rows = await db.query(
      'vouchers',
      where: 'code = ?',
      whereArgs: [code.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return rows.first;
  }

  Future<int> updateVoucherStatus(
    int id,
    String status, {
    bool setUsedTime = false,
  }) async {
    final db = await database;

    return db.update(
      'vouchers',
      {
        'status': status.toUpperCase(),
        'used_at': setUsedTime
            ? DateTime.now().millisecondsSinceEpoch
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVoucher(int id) async {
    final db = await database;

    return db.delete(
      'vouchers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // DASHBOARD / SUMMARY
  // ============================================================

  Future<DashboardSummary> getSummary() async {
    final db = await database;

    final playerCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM players'),
        ) ??
        0;

    final totalPoints = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COALESCE(SUM(points), 0) FROM players',
          ),
        ) ??
        0;

    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    final end = start + const Duration(days: 1).inMilliseconds;

    final paymentRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM payments
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start, end],
    );

    final expenseRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start, end],
    );

    return DashboardSummary(
      players: playerCount,
      points: totalPoints,
      todayPayments:
          (paymentRows.first['total'] as num?)?.toDouble() ?? 0,
      todayExpenses:
          (expenseRows.first['total'] as num?)?.toDouble() ?? 0,
    );
  }

  // ============================================================
  // REPORT HELPERS
  // ============================================================

  Future<double> getTotalPayments() async {
    final db = await database;

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM payments',
    );

    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpenses() async {
    final db = await database;

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses',
    );

    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTotalPointsAdded() async {
    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(points), 0) AS total
      FROM point_ledger
      WHERE type IN ('ADD', 'REFUND')
      ''',
    );

    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> getTotalPointsSpent() async {
    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(points), 0) AS total
      FROM point_ledger
      WHERE type = 'SPEND'
      ''',
    );

    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  // ============================================================
  // ROW CONVERTERS
  // ============================================================

  Player _playerFromRow(Map<String, Object?> r) {
    return Player(
      id: r['id'] as int,
      name: r['name'] as String,
      phone: r['phone'] as String,
      email: r['email'] as String,
      points: r['points'] as int,
      notes: r['notes'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        r['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        r['updated_at'] as int,
      ),
    );
  }

  LedgerEntry _ledgerFromRow(Map<String, Object?> r) {
    return LedgerEntry(
      id: r['id'] as int,
      playerId: r['player_id'] as int,
      type: r['type'] as String,
      points: r['points'] as int,
      note: r['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        r['created_at'] as int,
      ),
    );
  }

  Payment _paymentFromRow(Map<String, Object?> r) {
    return Payment(
      id: r['id'] as int,
      playerId: r['player_id'] as int?,
      amount: (r['amount'] as num).toDouble(),
      method: r['method'] as String,
      reference: r['reference'] as String,
      note: r['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        r['created_at'] as int,
      ),
    );
  }

  Expense _expenseFromRow(Map<String, Object?> r) {
    return Expense(
      id: r['id'] as int,
      amount: (r['amount'] as num).toDouble(),
      category: r['category'] as String,
      note: r['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        r['created_at'] as int,
      ),
    );
  }
}

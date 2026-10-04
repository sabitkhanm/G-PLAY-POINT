import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'g_point.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
        await db.execute('CREATE INDEX idx_ledger_player ON point_ledger(player_id, created_at DESC)');
        await db.execute('CREATE INDEX idx_payments_date ON payments(created_at DESC)');
        await db.execute('CREATE INDEX idx_expenses_date ON expenses(created_at DESC)');
      },
    );
    return _db!;
  }

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
    final where = query.trim().isEmpty ? null : 'name LIKE ? OR phone LIKE ? OR email LIKE ?';
    final args = query.trim().isEmpty ? null : ['%$query%', '%$query%', '%$query%'];
    final rows = await db.query('players', where: where, whereArgs: args, orderBy: 'updated_at DESC');
    return rows.map((r) => Player(
      id: r['id'] as int,
      name: r['name'] as String,
      phone: r['phone'] as String,
      email: r['email'] as String,
      points: r['points'] as int,
      notes: r['notes'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
    )).toList();
  }

  Future<Player?> getPlayer(int id) async {
    final db = await database;
    final rows = await db.query('players', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Player(
      id: r['id'] as int,
      name: r['name'] as String,
      phone: r['phone'] as String,
      email: r['email'] as String,
      points: r['points'] as int,
      notes: r['notes'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
    );
  }

  Future<void> applyPoints({required int playerId, required String type, required int points, String note = ''}) async {
    if (points <= 0) throw ArgumentError('Points must be greater than zero.');
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('players', columns: ['points'], where: 'id = ?', whereArgs: [playerId], limit: 1);
      if (rows.isEmpty) throw StateError('Player not found.');
      final current = rows.first['points'] as int;
      final delta = type == 'SPEND' ? -points : points;
      final next = current + delta;
      if (next < 0) throw StateError('Insufficient points.');
      final now = DateTime.now().millisecondsSinceEpoch;
      await txn.insert('point_ledger', {
        'player_id': playerId,
        'type': type,
        'points': points,
        'note': note,
        'created_at': now,
      });
      await txn.update('players', {'points': next, 'updated_at': now}, where: 'id = ?', whereArgs: [playerId]);
    });
  }

  Future<List<LedgerEntry>> getLedger(int playerId) async {
    final db = await database;
    final rows = await db.query('point_ledger', where: 'player_id = ?', whereArgs: [playerId], orderBy: 'created_at DESC');
    return rows.map((r) => LedgerEntry(
      id: r['id'] as int,
      playerId: r['player_id'] as int,
      type: r['type'] as String,
      points: r['points'] as int,
      note: r['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    )).toList();
  }

  Future<int> insertPayment(Payment p) async {
    final db = await database;
    return db.insert('payments', {
      'player_id': p.playerId,
      'amount': p.amount,
      'method': p.method,
      'reference': p.reference,
      'note': p.note,
      'created_at': p.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return db.insert('expenses', {
      'amount': e.amount,
      'category': e.category,
      'note': e.note,
      'created_at': e.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<DashboardSummary> getSummary() async {
    final db = await database;
    final p = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM players')) ?? 0;
    final points = Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(SUM(points),0) FROM players')) ?? 0;
    final start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    final payRows = await db.rawQuery('SELECT COALESCE(SUM(amount),0) AS total FROM payments WHERE created_at >= ? AND created_at < ?', [start, end]);
    final expRows = await db.rawQuery('SELECT COALESCE(SUM(amount),0) AS total FROM expenses WHERE created_at >= ? AND created_at < ?', [start, end]);
    return DashboardSummary(
      players: p,
      points: points,
      todayPayments: (payRows.first['total'] as num).toDouble(),
      todayExpenses: (expRows.first['total'] as num).toDouble(),
    );
  }

  Future<List<Payment>> getPayments() async {
    final db = await database;
    final rows = await db.query('payments', orderBy: 'created_at DESC', limit: 100);
    return rows.map((r) => Payment(
      id: r['id'] as int,
      playerId: r['player_id'] as int?,
      amount: (r['amount'] as num).toDouble(),
      method: r['method'] as String,
      reference: r['reference'] as String,
      note: r['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    )).toList();
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'created_at DESC', limit: 100);
    return rows.map((r) => Expense(
      id: r['id'] as int,
      amount: (r['amount'] as num).toDouble(),
      category: r['category'] as String,
      note: r['note'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    )).toList();
  }
}

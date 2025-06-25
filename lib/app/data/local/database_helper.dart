import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/account_model.dart';
import 'models/transaction_model.dart' as my_models;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ceban.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        initialBalance REAL NOT NULL,
        icon TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        accountId INTEGER NOT NULL,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Operasi CRUD untuk Akun ---
  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  // --- Operasi CRUD untuk Transaksi ---
  Future<int> insertTransaction(my_models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<my_models.Transaction>> getTransactions() async {
    final db = await database;
    // Query join untuk mendapatkan nama akun
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, a.name as accountName 
        FROM transactions t
        JOIN accounts a ON t.accountId = a.id
        ORDER BY t.date DESC
    ''');

    return List.generate(maps.length, (i) {
      return my_models.Transaction.fromMap(maps[i]);
    });
  }
  
  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTransaction(my_models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }
  
  Future<void> deleteAccount(int id) async {
    final db = await database;
    // Karena kita menggunakan FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE,
    // SQLite akan secara otomatis menghapus semua transaksi yang terkait dengan akun ini.
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }}
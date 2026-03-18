import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'my_auto_guide.db');
    return await openDatabase(
      path,
      version: 6, // v6: Añadidas columnas velocidad_max y velocidad_prom en pending_routes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        vehicleId TEXT,
        originName TEXT,
        destinationName TEXT,
        distanceKm REAL,
        durationSeconds INTEGER,
        consumoGalones REAL,
        costoEstimado REAL,
        fecha TEXT,
        synced INTEGER DEFAULT 0,
        viaPuntos TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_kms_updates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId TEXT,
        kmsToAdd INTEGER,
        fecha TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        vehicleId TEXT,
        categoria TEXT,
        monto REAL,
        descripcion TEXT,
        fecha TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Crear tablas para sincronización offline
      await db.execute('''
        CREATE TABLE pending_routes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT,
          vehicleId TEXT,
          originName TEXT,
          destinationName TEXT,
          distanceKm REAL,
          durationSeconds INTEGER,
          consumoGalones REAL,
          costoEstimado REAL,
          fecha TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE pending_kms_updates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicleId TEXT,
          kmsToAdd INTEGER,
          fecha TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE pending_expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT,
          vehicleId TEXT,
          categoria TEXT,
          monto REAL,
          descripcion TEXT,
          fecha TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE pending_routes ADD COLUMN viaPuntos TEXT');
      } catch (e) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE pending_routes ADD COLUMN viaPuntos TEXT');
      } catch (e) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE pending_routes ADD COLUMN velocidad_max REAL');
        await db.execute('ALTER TABLE pending_routes ADD COLUMN velocidad_prom REAL');
      } catch (e) {}
    }
  }

  // Métodos para Pending Routes (sincronización offline)
  Future<int> insertPendingRoute(Map<String, dynamic> route) async {
    final db = await database;
    return await db.insert('pending_routes', route);
  }

  Future<List<Map<String, dynamic>>> getPendingRoutes() async {
    final db = await database;
    return await db
        .query('pending_routes', where: 'synced = ?', whereArgs: [0]);
  }

  Future<int> markRouteAsSynced(int id) async {
    final db = await database;
    return await db.update('pending_routes', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePendingRoute(int id) async {
    final db = await database;
    return await db.delete('pending_routes', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Pending KMS Updates
  Future<int> insertPendingKmsUpdate(String vehicleId, int kmsToAdd) async {
    final db = await database;
    return await db.insert('pending_kms_updates', {
      'vehicleId': vehicleId,
      'kmsToAdd': kmsToAdd,
      'fecha': DateTime.now().toIso8601String(),
      'synced': 0
    });
  }

  Future<List<Map<String, dynamic>>> getPendingKmsUpdates() async {
    final db = await database;
    return await db
        .query('pending_kms_updates', where: 'synced = ?', whereArgs: [0]);
  }

  Future<int> markKmsUpdateAsSynced(int id) async {
    final db = await database;
    return await db.update('pending_kms_updates', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePendingKmsUpdate(int id) async {
    final db = await database;
    return await db
        .delete('pending_kms_updates', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Pending Expenses
  Future<int> insertPendingExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('pending_expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getPendingExpenses() async {
    final db = await database;
    return await db.query('pending_expenses', where: 'synced = ?', whereArgs: [0]);
  }

  Future<int> markExpenseAsSynced(int id) async {
    final db = await database;
    return await db.update('pending_expenses', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePendingExpense(int id) async {
    final db = await database;
    return await db.delete('pending_expenses', where: 'id = ?', whereArgs: [id]);
  }
}

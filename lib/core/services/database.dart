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
      version: 2, // Incrementado para incluir nuevas tablas
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        marca TEXT,
        modelo TEXT,
        apodo TEXT,
        kms INTEGER,
        imagePath TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        vehicleId TEXT,
        originName TEXT,
        destinationName TEXT,
        distanceKm REAL,
        durationSeconds INTEGER,
        consumoGalones REAL,
        costoEstimado REAL,
        fecha TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        vehicleId TEXT,
        categoria TEXT,
        monto REAL,
        descripcion TEXT,
        fecha TEXT
      )
    ''');
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
  }

  // Métodos para Vehicles
  Future<List<Map<String, dynamic>>> getAllVehicles(String userId) async {
    final db = await database;
    return await db.query('vehicles', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> insertVehicle(Map<String, dynamic> vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle);
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> vehicle) async {
    final db = await database;
    return await db
        .update('vehicles', vehicle, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Routes
  Future<List<Map<String, dynamic>>> getRoutesForVehicle(
      String vehicleId) async {
    final db = await database;
    return await db
        .query('routes', where: 'vehicleId = ?', whereArgs: [vehicleId]);
  }

  Future<int> insertRoute(Map<String, dynamic> route) async {
    final db = await database;
    return await db.insert('routes', route);
  }

  // Métodos para Expenses
  Future<List<Map<String, dynamic>>> getExpensesForVehicle(
      String vehicleId) async {
    final db = await database;
    return await db
        .query('expenses', where: 'vehicleId = ?', whereArgs: [vehicleId]);
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', expense);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
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
}

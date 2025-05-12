import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Database table and column names
  static const String tableAccidents = 'accidents';
  static const String columnId = 'id';
  static const String columnTaskId = 'task_id';
  static const String columnTimestamp = 'timestamp';
  static const String columnLocation = 'location';
  static const String columnAccidentType = 'accident_type';
  static const String columnConfidenceScore = 'confidence_score';
  static const String columnVideoPath = 'video_path';
  static const String columnIsNotified = 'is_notified';
  static const String columnIsResolved = 'is_resolved';

  static const String tableNumberPlates = 'number_plates';
  static const String columnJobId = 'job_id';
  static const String columnPlateNumber = 'plate_number';
  static const String columnPlateImage = 'plate_image';
  static const String columnVideoTimestamp = 'video_timestamp';

  // Singleton constructor
  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'accident_detection.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create accidents table
    await db.execute('''
      CREATE TABLE $tableAccidents (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTaskId TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnLocation TEXT,
        $columnAccidentType TEXT,
        $columnConfidenceScore REAL,
        $columnVideoPath TEXT,
        $columnIsNotified INTEGER DEFAULT 0,
        $columnIsResolved INTEGER DEFAULT 0
      )
    ''');

    // Create number plates table
    await db.execute('''
      CREATE TABLE $tableNumberPlates (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnJobId TEXT NOT NULL,
        $columnPlateNumber TEXT NOT NULL,
        $columnPlateImage TEXT,
        $columnVideoTimestamp TEXT,
        $columnTimestamp TEXT NOT NULL
      )
    ''');
  }

  // CRUD Operations for Accidents

  Future<int> insertAccident(Map<String, dynamic> accident) async {
    Database db = await database;
    return await db.insert(tableAccidents, accident);
  }

  Future<List<Map<String, dynamic>>> getAccidents() async {
    Database db = await database;
    return await db.query(tableAccidents, orderBy: '$columnTimestamp DESC');
  }

  Future<Map<String, dynamic>?> getAccidentByTaskId(String taskId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      tableAccidents,
      where: '$columnTaskId = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateAccident(Map<String, dynamic> accident) async {
    Database db = await database;
    return await db.update(
      tableAccidents,
      accident,
      where: '$columnId = ?',
      whereArgs: [accident[columnId]],
    );
  }

  Future<int> deleteAccident(int id) async {
    Database db = await database;
    return await db.delete(
      tableAccidents,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAccidentAsNotified(int id) async {
    Database db = await database;
    return await db.update(
      tableAccidents,
      {columnIsNotified: 1},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAccidentAsResolved(int id) async {
    Database db = await database;
    return await db.update(
      tableAccidents,
      {columnIsResolved: 1},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations for Number Plates

  Future<int> insertNumberPlate(Map<String, dynamic> numberPlate) async {
    Database db = await database;
    return await db.insert(tableNumberPlates, numberPlate);
  }

  Future<List<Map<String, dynamic>>> getNumberPlates() async {
    Database db = await database;
    return await db.query(tableNumberPlates, orderBy: '$columnTimestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getNumberPlatesByJobId(String jobId) async {
    Database db = await database;
    return await db.query(
      tableNumberPlates,
      where: '$columnJobId = ?',
      whereArgs: [jobId],
    );
  }

  Future<int> updateNumberPlate(Map<String, dynamic> numberPlate) async {
    Database db = await database;
    return await db.update(
      tableNumberPlates,
      numberPlate,
      where: '$columnId = ?',
      whereArgs: [numberPlate[columnId]],
    );
  }

  Future<int> deleteNumberPlate(int id) async {
    Database db = await database;
    return await db.delete(
      tableNumberPlates,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Get all notifications (unresolved accidents)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    Database db = await database;
    return await db.query(
      tableAccidents,
      where: '$columnIsResolved = ?',
      whereArgs: [0],
      orderBy: '$columnTimestamp DESC',
    );
  }
} 
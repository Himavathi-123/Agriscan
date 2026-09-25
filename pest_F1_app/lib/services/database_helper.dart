import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pest_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        totalCount INTEGER NOT NULL,
        message TEXT NOT NULL,
        pestSummary TEXT NOT NULL,
        detectionsJson TEXT NOT NULL,
        localImagePath TEXT
      )
    ''');
  }

  Future<int> insertDetection(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('detections', {
      'timestamp': DateTime.now().toIso8601String(),
      'totalCount': data['total_count'] ?? 0,
      'message': data['message'] ?? '',
      'pestSummary': jsonEncode(data['pest_summary'] ?? {}),
      'detectionsJson': jsonEncode(data['detections'] ?? []),
      'localImagePath': data['image_path'] ?? '',
    });
  }

  Future<List<Map<String, dynamic>>> queryAllDetections() async {
    final db = await instance.database;
    return await db.query('detections', orderBy: 'timestamp DESC');
  }

  Future<int> deleteDetection(int id) async {
    final db = await instance.database;
    return await db.delete('detections', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('detections');
  }
}

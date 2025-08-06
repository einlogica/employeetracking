import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'checkin.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE checkins(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            datetime TEXT,
            battery INTEGER,
            latitude REAL,
            longitude REAL
          )
        ''');
      },
    );
  }

  static Future<void> insertCheckIn(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('checkins', data);
  }

  static Future<void> deleteCheckIn() async {
    final db = await database;
    await db.delete('checkins');
  }

  static Future<List<Map<String, dynamic>>> getAllCheckIns() async {
    final db = await database;
    return await db.query('checkins', orderBy: 'id DESC');
  }
}

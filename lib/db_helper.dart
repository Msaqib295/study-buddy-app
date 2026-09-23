import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    final path = join(await getDatabasesPath(), 'study_buddy.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question TEXT,
            answer TEXT,
            source TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
    return _database!;
  }

  static Future<void> insertEntry(
    String question,
    String answer,
    String source,
  ) async {
    final db = await getDatabase();
    await db.insert('history', {
      'question': question,
      'answer': answer,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await getDatabase();
    return await db.query('history', orderBy: 'id DESC');
  }

  static Future<void> clearHistory() async {
    final db = await getDatabase();
    await db.delete('history');
  }

  static Future<void> deleteEntry(int id) async {
    final db = await getDatabase();
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}

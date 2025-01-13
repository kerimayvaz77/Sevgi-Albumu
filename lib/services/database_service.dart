import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/album_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'album_entries';
  static const String _databaseName = 'album_database.db';
  static const int _databaseVersion = 3;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Veritabanı başlatma hatası: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        imagePaths TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _migrateToVersion3(db);
    }
  }

  Future<void> _migrateToVersion3(Database db) async {
    try {
      await db.transaction((txn) async {
        // Yedek tablo oluştur
        await txn.execute(
            'CREATE TABLE ${_tableName}_backup AS SELECT * FROM $_tableName');

        // Ana tabloyu sil
        await txn.execute('DROP TABLE $_tableName');

        // Yeni şema ile tabloyu oluştur
        await txn.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            note TEXT,
            imagePaths TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');

        // Verileri geri yükle
        await txn.execute(
            'INSERT INTO $_tableName SELECT id, title, note, imagePaths, date FROM ${_tableName}_backup');

        // Yedek tabloyu sil
        await txn.execute('DROP TABLE ${_tableName}_backup');
      });
    } catch (e) {
      print('Veritabanı güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> insertEntry(AlbumEntry entry) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Kayıt ekleme hatası: $e');
      rethrow;
    }
  }

  Future<List<AlbumEntry>> getEntries() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'date DESC',
      );

      print('Veritabanından çekilen kayıt sayısı: ${maps.length}');
      return maps.map((map) => AlbumEntry.fromMap(map)).toList();
    } catch (e) {
      print('Kayıtları getirme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Kayıt silme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(AlbumEntry entry) async {
    try {
      final db = await database;
      await db.update(
        _tableName,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      print('Kayıt güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}

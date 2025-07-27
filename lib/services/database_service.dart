import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/user.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbPath = 'database/auth.db';

  static Database get database {
    _database ??= _initDatabase();
    return _database!;
  }

  static Database _initDatabase() {
    // Database klasörünü oluştur
    final dbDir = Directory('database');
    if (!dbDir.existsSync()) {
      dbDir.createSync();
    }

    final db = sqlite3.open(_dbPath);
    _createTables(db);
    return db;
  }

  static void _createTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT UNIQUE NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  static User? getUserByEmail(String email) {
    final result = database.select(
      '''
      SELECT * FROM users WHERE email = ?
    ''',
      [email],
    );

    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  static User? getUserById(int id) {
    final result = database.select(
      '''
      SELECT * FROM users WHERE id = ?
    ''',
      [id],
    );

    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  static User? getUserByUsername(String username) {
    final result = database.select(
      '''
      SELECT * FROM users WHERE username = ?
    ''',
      [username],
    );

    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  static int createUser(User user) {
    database.execute(
      '''
      INSERT INTO users (email, username, password_hash, created_at)
      VALUES (?, ?, ?, ?)
    ''',
      [
        user.email,
        user.username,
        user.passwordHash,
        user.createdAt.toIso8601String(),
      ],
    );

    // Son eklenen ID'yi al
    final result = database.select('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  static bool updateUser(int id, Map<String, dynamic> updates) {
    final setClause = updates.keys.map((key) => '$key = ?').join(', ');
    final values = updates.values.toList()..add(id);

    database.execute('''
      UPDATE users SET $setClause WHERE id = ?
    ''', values);

    // Etkilenen satır sayısını kontrol et
    final result = database.select('SELECT changes() as count');
    return (result.first['count'] as int) > 0;
  }

  static void saveRefreshToken(int userId, String token, DateTime expiresAt) {
    database.execute(
      '''
      INSERT INTO refresh_tokens (user_id, token, expires_at, created_at)
      VALUES (?, ?, ?, ?)
    ''',
      [
        userId,
        token,
        expiresAt.toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  static bool validateRefreshToken(String token) {
    final result = database.select(
      '''
      SELECT * FROM refresh_tokens 
      WHERE token = ? AND expires_at > ?
    ''',
      [token, DateTime.now().toIso8601String()],
    );

    return result.isNotEmpty;
  }

  static void deleteRefreshToken(String token) {
    database.execute(
      '''
      DELETE FROM refresh_tokens WHERE token = ?
    ''',
      [token],
    );
  }

  static void deleteExpiredRefreshTokens() {
    database.execute(
      '''
      DELETE FROM refresh_tokens WHERE expires_at <= ?
    ''',
      [DateTime.now().toIso8601String()],
    );
  }

  static void close() {
    _database?.dispose();
    _database = null;
  }
}

import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/comment.dart';

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
    // Users table
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        phone_number TEXT,
        date_of_birth TEXT,
        address TEXT,
        city TEXT,
        country TEXT,
        bio TEXT,
        avatar_url TEXT,
        is_active INTEGER DEFAULT 1,
        is_email_verified INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Refresh tokens table
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

    // Posts table
    db.execute('''
      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        hashtags TEXT,
        is_public INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        like_count INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0,
        share_count INTEGER DEFAULT 0,
        is_edited INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Comments table
    db.execute('''
      CREATE TABLE IF NOT EXISTS comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        parent_comment_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        like_count INTEGER DEFAULT 0,
        is_edited INTEGER DEFAULT 0,
        FOREIGN KEY (post_id) REFERENCES posts (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (parent_comment_id) REFERENCES comments (id)
      )
    ''');

    // Follows table
    db.execute('''
      CREATE TABLE IF NOT EXISTS follows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        follower_id INTEGER NOT NULL,
        following_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(follower_id, following_id),
        FOREIGN KEY (follower_id) REFERENCES users (id),
        FOREIGN KEY (following_id) REFERENCES users (id)
      )
    ''');

    // Likes table
    db.execute('''
      CREATE TABLE IF NOT EXISTS likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        target_id INTEGER NOT NULL,
        target_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, target_id, target_type),
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

  // Social Media Methods

  // Posts
  static int createPost(Post post) {
    database.execute(
      '''
      INSERT INTO posts (user_id, content, image_url, hashtags, is_public, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    ''',
      [
        post.userId,
        post.content,
        post.imageUrl,
        post.hashtags?.join(','),
        post.isPublic ? 1 : 0,
        post.createdAt.toIso8601String(),
      ],
    );

    final result = database.select('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  static Post? getPostById(int id) {
    final result = database.select(
      '''
      SELECT * FROM posts WHERE id = ?
    ''',
      [id],
    );

    if (result.isEmpty) return null;
    return Post.fromMap(result.first);
  }

  static List<Post> getPostsByUserId(
    int userId, {
    int limit = 20,
    int offset = 0,
  }) {
    final result = database.select(
      '''
      SELECT * FROM posts 
      WHERE user_id = ? AND is_public = 1
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    ''',
      [userId, limit, offset],
    );

    return result.map((row) => Post.fromMap(row)).toList();
  }

  static List<Post> getFeedPosts(int userId, {int limit = 20, int offset = 0}) {
    final result = database.select(
      '''
      SELECT p.* FROM posts p
      INNER JOIN follows f ON p.user_id = f.following_id
      WHERE f.follower_id = ? AND p.is_public = 1
      UNION
      SELECT * FROM posts WHERE user_id = ? AND is_public = 1
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    ''',
      [userId, userId, limit, offset],
    );

    return result.map((row) => Post.fromMap(row)).toList();
  }

  static bool updatePost(int id, Map<String, dynamic> updates) {
    final setClause = updates.keys.map((key) => '$key = ?').join(', ');
    final values = updates.values.toList()..add(id);

    database.execute('''
      UPDATE posts SET $setClause WHERE id = ?
    ''', values);

    final result = database.select('SELECT changes() as count');
    return (result.first['count'] as int) > 0;
  }

  static bool deletePost(int id) {
    database.execute('DELETE FROM posts WHERE id = ?', [id]);
    final result = database.select('SELECT changes() as count');
    return (result.first['count'] as int) > 0;
  }

  // Comments
  static int createComment(Comment comment) {
    database.execute(
      '''
      INSERT INTO comments (post_id, user_id, content, parent_comment_id, created_at)
      VALUES (?, ?, ?, ?, ?)
    ''',
      [
        comment.postId,
        comment.userId,
        comment.content,
        comment.parentCommentId,
        comment.createdAt.toIso8601String(),
      ],
    );

    final result = database.select('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  static List<Comment> getCommentsByPostId(
    int postId, {
    int limit = 50,
    int offset = 0,
  }) {
    final result = database.select(
      '''
      SELECT * FROM comments 
      WHERE post_id = ?
      ORDER BY created_at ASC
      LIMIT ? OFFSET ?
    ''',
      [postId, limit, offset],
    );

    return result.map((row) => Comment.fromMap(row)).toList();
  }

  static bool updateComment(int id, Map<String, dynamic> updates) {
    final setClause = updates.keys.map((key) => '$key = ?').join(', ');
    final values = updates.values.toList()..add(id);

    database.execute('''
      UPDATE comments SET $setClause WHERE id = ?
    ''', values);

    final result = database.select('SELECT changes() as count');
    return (result.first['count'] as int) > 0;
  }

  static bool deleteComment(int id) {
    database.execute('DELETE FROM comments WHERE id = ?', [id]);
    final result = database.select('SELECT changes() as count');
    return (result.first['count'] as int) > 0;
  }

  // Follows
  static bool followUser(int followerId, int followingId) {
    try {
      database.execute(
        '''
        INSERT INTO follows (follower_id, following_id, created_at)
        VALUES (?, ?, ?)
      ''',
        [followerId, followingId, DateTime.now().toIso8601String()],
      );
      return true;
    } catch (e) {
      return false; // Already following
    }
  }

  static bool unfollowUser(int followerId, int followingId) {
    database.execute(
      '''
      DELETE FROM follows 
      WHERE follower_id = ? AND following_id = ?
    ''',
      [followerId, followingId],
    );
    final result = database.select('SELECT changes() as count');
    return (result.first['count'] as int) > 0;
  }

  static bool isFollowing(int followerId, int followingId) {
    final result = database.select(
      '''
      SELECT * FROM follows 
      WHERE follower_id = ? AND following_id = ?
    ''',
      [followerId, followingId],
    );
    return result.isNotEmpty;
  }

  static List<int> getFollowers(int userId) {
    final result = database.select(
      '''
      SELECT follower_id FROM follows WHERE following_id = ?
    ''',
      [userId],
    );
    return result.map((row) => row['follower_id'] as int).toList();
  }

  static List<int> getFollowing(int userId) {
    final result = database.select(
      '''
      SELECT following_id FROM follows WHERE follower_id = ?
    ''',
      [userId],
    );
    return result.map((row) => row['following_id'] as int).toList();
  }

  // Likes
  static bool likePost(int userId, int postId) {
    try {
      database.execute(
        '''
        INSERT INTO likes (user_id, target_id, target_type, created_at)
        VALUES (?, ?, 'post', ?)
      ''',
        [userId, postId, DateTime.now().toIso8601String()],
      );

      // Update post like count
      database.execute(
        '''
        UPDATE posts SET like_count = like_count + 1 WHERE id = ?
      ''',
        [postId],
      );
      return true;
    } catch (e) {
      return false; // Already liked
    }
  }

  static bool unlikePost(int userId, int postId) {
    database.execute(
      '''
      DELETE FROM likes 
      WHERE user_id = ? AND target_id = ? AND target_type = 'post'
    ''',
      [userId, postId],
    );

    final result = database.select('SELECT changes() as count');
    if ((result.first['count'] as int) > 0) {
      // Update post like count
      database.execute(
        '''
        UPDATE posts SET like_count = like_count - 1 WHERE id = ?
      ''',
        [postId],
      );
      return true;
    }
    return false;
  }

  static bool likeComment(int userId, int commentId) {
    try {
      database.execute(
        '''
        INSERT INTO likes (user_id, target_id, target_type, created_at)
        VALUES (?, ?, 'comment', ?)
      ''',
        [userId, commentId, DateTime.now().toIso8601String()],
      );

      // Update comment like count
      database.execute(
        '''
        UPDATE comments SET like_count = like_count + 1 WHERE id = ?
      ''',
        [commentId],
      );
      return true;
    } catch (e) {
      return false; // Already liked
    }
  }

  static bool unlikeComment(int userId, int commentId) {
    database.execute(
      '''
      DELETE FROM likes 
      WHERE user_id = ? AND target_id = ? AND target_type = 'comment'
    ''',
      [userId, commentId],
    );

    final result = database.select('SELECT changes() as count');
    if ((result.first['count'] as int) > 0) {
      // Update comment like count
      database.execute(
        '''
        UPDATE comments SET like_count = like_count - 1 WHERE id = ?
      ''',
        [commentId],
      );
      return true;
    }
    return false;
  }

  static bool isLiked(int userId, int targetId, String targetType) {
    final result = database.select(
      '''
      SELECT * FROM likes 
      WHERE user_id = ? AND target_id = ? AND target_type = ?
    ''',
      [userId, targetId, targetType],
    );
    return result.isNotEmpty;
  }

  static void close() {
    _database?.dispose();
    _database = null;
  }
}

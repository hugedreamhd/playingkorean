import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quizzes.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute('DROP TABLE IF EXISTS quizzes');
          await db.execute('DROP TABLE IF EXISTS vocabulary');
          await _onCreate(db, newVersion);
          return;
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_meta (
              meta_key TEXT PRIMARY KEY,
              meta_value TEXT
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('DELETE FROM vocabulary');
          await db.execute('DELETE FROM app_meta WHERE meta_key LIKE \'seed_%\'');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vocabulary (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        pronunciation TEXT,
        level TEXT,
        pos TEXT,
        homonym_no INTEGER,
        definition_kr TEXT,
        definition_en TEXT,
        lemma_en TEXT,
        example_kr TEXT,
        choseong TEXT,
        jungseong TEXT,
        jongseong TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_word ON vocabulary (word)');
    await db.execute('CREATE INDEX idx_level ON vocabulary (level)');

    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        imageUrl TEXT,
        contextText TEXT,
        options TEXT,
        romaji TEXT,
        englishMeanings TEXT,
        optionImages TEXT,
        explanations TEXT,
        exampleSentences TEXT,
        difficulty TEXT,
        answerIndex INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE app_meta (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT
      )
    ''');
  }

  /// 앱 메타 값 조회
  Future<String?> getMetaValue(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_meta',
      columns: ['meta_value'],
      where: 'meta_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['meta_value'] as String?;
  }

  /// 앱 메타 값 저장/업데이트
  Future<void> setMetaValue(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {'meta_key': key, 'meta_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// 단어 데이터 모델
class VocabularyModel {
  final String id;
  final String word;
  final String? pronunciation;
  final String? level;
  final String? pos;
  final int? homonymNo;
  final String? definitionKr;
  final String? definitionEn;
  final String? lemmaEn;
  final String? exampleKr;

  VocabularyModel({
    required this.id,
    required this.word,
    this.pronunciation,
    this.level,
    this.pos,
    this.homonymNo,
    this.definitionKr,
    this.definitionEn,
    this.lemmaEn,
    this.exampleKr,
  });
}

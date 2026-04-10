import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';

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
      version: 6,
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
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. 사전 단어 테이블 (학습자 사전 기반)
    await db.execute('''
      CREATE TABLE vocabulary (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        pronunciation TEXT,
        level TEXT, -- 초급, 중급, 고급
        pos TEXT,   -- 명사, 동사 등
        homonym_no INTEGER,
        definition_kr TEXT,
        definition_en TEXT,
        lemma_en TEXT,
        example_kr TEXT,
        choseong TEXT, -- 초성 (예: ㅂ)
        jungseong TEXT, -- 중성 (예: ㅏ)
        jongseong TEXT  -- 종성 (예: ㅁ)
      )
    ''');

    // 2. 검색 최적화를 위한 인덱스
    await db.execute('CREATE INDEX idx_word ON vocabulary (word)');
    await db.execute('CREATE INDEX idx_level ON vocabulary (level)');
    await db.execute(
      'CREATE INDEX idx_jamo ON vocabulary (choseong, jungseong, jongseong)',
    );

    // 3. 기존 퀴즈 테이블 (필요 시 유지)
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

    // 4. 앱 메타 정보 저장 테이블 (시드 순서/인덱스 등)
    await db.execute('''
      CREATE TABLE app_meta (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT
      )
    ''');
  }

  /// 퀴즈 데이터 일괄 삽입 (Transaction 사용)
  Future<void> insertQuizzes(List<QuizQuestion> questions) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var q in questions) {
        batch.insert('quizzes', {
          'id': q.id,
          'imageUrl': q.imageUrl,
          'contextText': q.contextText,
          'options': jsonEncode(q.options),
          'romaji': jsonEncode(q.romaji),
          'englishMeanings': jsonEncode(q.englishMeanings),
          'optionImages': jsonEncode(q.optionImages),
          'explanations': jsonEncode(q.explanations),
          'exampleSentences': jsonEncode(q.exampleSentences),
          'difficulty': q.difficulty,
          'answerIndex': q.answerIndex,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  /// 조건에 맞는 퀴즈 랜덤 조회
  Future<List<QuizQuestion>> getQuizQuestions({
    String? difficulty,
    int? count,
  }) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (difficulty != null) {
      whereClause = 'difficulty = ?';
      whereArgs = [difficulty];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'quizzes',
      where: whereClause,
      whereArgs: whereArgs,
      // count가 있을 때만 RANDOM() 사용, 없을 때는 Dart에서 shuffle
      orderBy: count != null ? 'RANDOM()' : null,
      limit: count,
    );

    return List.generate(maps.length, (i) {
      return QuizQuestion(
        id: maps[i]['id'],
        imageUrl: maps[i]['imageUrl'],
        contextText: maps[i]['contextText'],
        options: List<String>.from(jsonDecode(maps[i]['options'])),
        romaji: List<String>.from(jsonDecode(maps[i]['romaji'])),
        englishMeanings: List<String>.from(
          jsonDecode(maps[i]['englishMeanings']),
        ),
        optionImages: List<String>.from(jsonDecode(maps[i]['optionImages'])),
        explanations: List<String>.from(jsonDecode(maps[i]['explanations'])),
        exampleSentences: List<String>.from(
          jsonDecode(maps[i]['exampleSentences']),
        ),
        difficulty: maps[i]['difficulty'],
        answerIndex: maps[i]['answerIndex'],
      );
    });
  }

  /// 특정 난이도의 랜덤 오답용 데이터 가져오기
  Future<List<QuizQuestion>> getRandomDistractors({
    required String difficulty,
    required String excludeId,
    int count = 3,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quizzes',
      where: 'difficulty = ? AND id != ?',
      whereArgs: [difficulty, excludeId],
      orderBy: 'RANDOM()',
      limit: count,
    );

    return List.generate(maps.length, (i) {
      return QuizQuestion(
        id: maps[i]['id'],
        imageUrl: maps[i]['imageUrl'],
        contextText: maps[i]['contextText'],
        options: List<String>.from(jsonDecode(maps[i]['options'])),
        romaji: List<String>.from(jsonDecode(maps[i]['romaji'])),
        englishMeanings: List<String>.from(
          jsonDecode(maps[i]['englishMeanings']),
        ),
        optionImages: List<String>.from(jsonDecode(maps[i]['optionImages'])),
        explanations: List<String>.from(jsonDecode(maps[i]['explanations'])),
        exampleSentences: List<String>.from(
          jsonDecode(maps[i]['exampleSentences']),
        ),
        difficulty: maps[i]['difficulty'],
        answerIndex: maps[i]['answerIndex'],
      );
    });
  }

  /// 사전 데이터 일괄 삽입 (Vocabulary)
  Future<void> insertVocabularies(List<VocabularyModel> items) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var item in items) {
        batch.insert(
          'vocabulary',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 최소 대립어(Minimal Pairs) 검색: 특정 단어와 초성/중성이 같고 종성만 다른 단어들
  Future<List<VocabularyModel>> getMinimalPairs(
    String targetWord, {
    String? level,
  }) async {
    if (targetWord.isEmpty) return [];
    final db = await database;

    // 첫 글자 기준 분석 (단음절 기준 최적화)
    final jamo = KoreanJamo.decompose(targetWord[0]);

    String where = 'choseong = ? AND jungseong = ? AND word != ?';
    List<dynamic> args = [jamo['choseong'], jamo['jungseong'], targetWord];

    if (level != null) {
      where += ' AND level = ?';
      args.add(level);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'vocabulary',
      where: where,
      whereArgs: args,
      limit: 10,
    );

    return maps.map((m) => VocabularyModel.fromMap(m)).toList();
  }

  /// 특정 레벨의 단어 랜덤 조회
  Future<List<VocabularyModel>> getRandomVocabulary({
    required String level,
    int count = 10,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabulary',
      where: 'level = ?',
      whereArgs: [level],
      orderBy: 'RANDOM()',
      limit: count,
    );
    return maps.map((m) => VocabularyModel.fromMap(m)).toList();
  }

  /// DB 상태 확인
  Future<bool> isVocabularyEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM vocabulary'),
    );
    return count == 0;
  }

  /// 기존 quizzes 테이블이 비어있는지 확인 (assets -> SQLite 마이그레이션 용)
  Future<bool> isQuizzesEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM quizzes'),
    );
    return count == 0;
  }

  /// 문맥 퀴즈에 쓸 수 있는(예문이 있는) vocabulary 개수
  Future<int> countUsableVocabulary({required String level}) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM vocabulary WHERE level = ? AND IFNULL(example_kr, '') != ''",
      [level],
    );
    return (result.isNotEmpty ? (result.first['c'] as int? ?? 0) : 0);
  }

  /// vocabulary 전체 행 개수
  Future<int> countVocabularyRows() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM vocabulary'),
    );
    return count ?? 0;
  }

  /// vocabulary 테이블 비우기 (Seeder 재실행 유도)
  Future<void> clearVocabulary() async {
    final db = await database;
    await db.delete('vocabulary');
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
    await db.insert('app_meta', {
      'meta_key': key,
      'meta_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
  final String? choseong;
  final String? jungseong;
  final String? jongseong;

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
    this.choseong,
    this.jungseong,
    this.jongseong,
  });

  Map<String, dynamic> toMap() {
    // 삽입 시 자소 분해 자동 수행 (데이터가 없을 경우)
    final jamo = word.isNotEmpty
        ? KoreanJamo.decompose(word[0])
        : {'choseong': '', 'jungseong': '', 'jongseong': ''};

    return {
      'id': id,
      'word': word,
      'pronunciation': pronunciation,
      'level': level,
      'pos': pos,
      'homonym_no': homonymNo,
      'definition_kr': definitionKr,
      'definition_en': definitionEn,
      'lemma_en': lemmaEn,
      'example_kr': exampleKr,
      'choseong': choseong ?? jamo['choseong'],
      'jungseong': jungseong ?? jamo['jungseong'],
      'jongseong': jongseong ?? jamo['jongseong'],
    };
  }

  factory VocabularyModel.fromMap(Map<String, dynamic> map) {
    return VocabularyModel(
      id: map['id'],
      word: map['word'],
      pronunciation: map['pronunciation'],
      level: map['level'],
      pos: map['pos'],
      homonymNo: map['homonym_no'],
      definitionKr: map['definition_kr'],
      definitionEn: map['definition_en'],
      lemmaEn: map['lemma_en'],
      exampleKr: map['example_kr'],
      choseong: map['choseong'],
      jungseong: map['jungseong'],
      jongseong: map['jongseong'],
    );
  }
}

/// 한글 자소 분석 유틸리티
class KoreanJamo {
  static const choseongs = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];
  static const jungseongs = [
    'ㅏ',
    'ㅐ',
    'ㅑ',
    'ㅒ',
    'ㅓ',
    'ㅔ',
    'ㅕ',
    'ㅖ',
    'ㅗ',
    'ㅘ',
    'ㅙ',
    'ㅚ',
    'ㅛ',
    'ㅜ',
    'ㅝ',
    'ㅞ',
    'ㅟ',
    'ㅠ',
    'ㅡ',
    'ㅢ',
    'ㅣ',
  ];
  static const jongseongs = [
    '',
    'ㄱ',
    'ㄲ',
    'ㄳ',
    'ㄴ',
    'ㄵ',
    'ㄶ',
    'ㄷ',
    'ㄹ',
    'ㄺ',
    'ㄻ',
    'ㄼ',
    'ㄽ',
    'ㄾ',
    'ㄿ',
    'ㅀ',
    'ㅁ',
    'ㅂ',
    'ㅄ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  static Map<String, String> decompose(String syllable) {
    if (syllable.isEmpty)
      return {'choseong': '', 'jungseong': '', 'jongseong': ''};

    final code = syllable.codeUnitAt(0) - 0xAC00;
    if (code < 0 || code > 11171) {
      return {'choseong': syllable, 'jungseong': '', 'jongseong': ''};
    }

    final cho = choseongs[code ~/ 588];
    final jung = jungseongs[(code % 588) ~/ 28];
    final jong = jongseongs[code % 28];

    return {'choseong': cho, 'jungseong': jung, 'jongseong': jong};
  }
}

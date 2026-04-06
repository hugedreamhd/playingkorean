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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // 데이터 생성 로직(assets/quizzes.json)이 바뀐 경우를 반영하기 위해
        // 스키마 버전 업 시 퀴즈 테이블을 재생성한다.
        await db.execute('DROP TABLE IF EXISTS quizzes');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
    
    // 인덱스 추가 (난이도 검색 속도 향상)
    await db.execute('CREATE INDEX idx_difficulty ON quizzes (difficulty)');
  }

  /// 퀴즈 데이터 일괄 삽입 (Transaction 사용)
  Future<void> insertQuizzes(List<QuizQuestion> questions) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var q in questions) {
        batch.insert(
          'quizzes',
          {
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
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 조건에 맞는 퀴즈 랜덤 조회
  Future<List<QuizQuestion>> getQuizQuestions({String? difficulty, int? count}) async {
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
        englishMeanings: List<String>.from(jsonDecode(maps[i]['englishMeanings'])),
        optionImages: List<String>.from(jsonDecode(maps[i]['optionImages'])),
        explanations: List<String>.from(jsonDecode(maps[i]['explanations'])),
        exampleSentences: List<String>.from(jsonDecode(maps[i]['exampleSentences'])),
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
        englishMeanings: List<String>.from(jsonDecode(maps[i]['englishMeanings'])),
        optionImages: List<String>.from(jsonDecode(maps[i]['optionImages'])),
        explanations: List<String>.from(jsonDecode(maps[i]['explanations'])),
        exampleSentences: List<String>.from(jsonDecode(maps[i]['exampleSentences'])),
        difficulty: maps[i]['difficulty'],
        answerIndex: maps[i]['answerIndex'],
      );
    });
  }

  /// DB가 비어있는지 확인 (초기 마이그레이션 판별용)
  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quizzes'));
    return count == 0;
  }
}

import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:playingkorean/core/data/database_helper.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';

class LocalQuizRepositoryImpl implements QuizRepository {
  static const String _assetPath = 'assets/data/quizzes.json';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions({String? difficulty, int? count}) async {
    try {
      // 1. DB가 비어있는지 확인 (초기 마이그레이션 여부 판단)
      final bool isEmpty = await _dbHelper.isDatabaseEmpty();
      
      if (isEmpty) {
        // [중요] 마이그레이션: JSON -> SQLite (최초 1회만 실행됨)
        final ByteData data = await rootBundle.load(_assetPath);
        
        final List<QuizQuestion> allQuestions = await Isolate.run(() {
          final Uint8List bytes = data.buffer.asUint8List();
          final String jsonString = utf8.decode(bytes);
          final List<dynamic> jsonList = json.decode(jsonString);
          return jsonList.map((j) => QuizQuestion.fromJson(j)).toList();
        });

        await _dbHelper.insertQuizzes(allQuestions);
      }

      // 2. 전체 데이터 로드 (동음이의어 뜻이 다른 난이도에 있을 수 있으므로 모두 로드)
      final List<QuizQuestion> allRecords = await _dbHelper.getQuizQuestions(
        difficulty: null, // 전체 로드
        count: null,
      );

      // 3. 같은 단어(options[0])끼리 그룹화
      final Map<String, List<QuizQuestion>> wordGroups = {};
      for (final q in allRecords) {
        final answerWord = q.options.isNotEmpty ? q.options[q.answerIndex] : '';
        if (answerWord.isEmpty) continue;
        wordGroups.putIfAbsent(answerWord, () => []).add(q);
      }

      // 4. 동음이의어 (같은 단어가 2개 이상 뜻을 가지는 경우)만 추출하여 퀴즈 생성
      final List<QuizQuestion> homophonePool = [];

      for (final entry in wordGroups.entries) {
        final group = entry.value;
        if (group.length < 2) continue;

        // 그룹 내 뜻들 중 하나라도 요청한 난이도와 일치하면 이 그룹을 포함
        if (difficulty != null) {
          final hasMatchingDifficulty = group.any((q) => q.difficulty == difficulty);
          if (!hasMatchingDifficulty) continue;
        }

        final List<String> allOptions = group
            .map((g) => g.options.isNotEmpty ? g.options[g.answerIndex] : '')
            .toList();
        final List<String> allRomaji = group
            .map((g) => g.romaji.isNotEmpty ? g.romaji[g.answerIndex] : '')
            .toList();
        final List<String> allExplanations = group
            .map((g) => g.explanations.isNotEmpty ? g.explanations[g.answerIndex] : '')
            .toList();
        final List<String> allEnglishMeanings = group
            .map((g) => g.englishMeanings.isNotEmpty ? g.englishMeanings[g.answerIndex] : '')
            .toList();
        final List<String> allExampleSentences = group
            .map((g) => g.exampleSentences.isNotEmpty ? g.exampleSentences[g.answerIndex] : '')
            .toList();

        // 각 의미(레코드)를 하나의 퀴즈 문항으로 생성
        for (int targetIdx = 0; targetIdx < group.length; targetIdx++) {
          final targetRecord = group[targetIdx];

          // 중요: 난이도 설정이 있는 경우, '정답'이 될 뜻의 난이도가 사용자가 선택한 난이도와 일치할 때만 문제로 출제
          if (difficulty != null && targetRecord.difficulty != difficulty) {
            continue;
          }

          // 옵션 순서 셔플 (정답 위치 무작위화)
          final shuffleIndices = List.generate(group.length, (i) => i)..shuffle();
          final newAnswerIndex = shuffleIndices.indexOf(targetIdx);

          homophonePool.add(targetRecord.copyWith(
            options: shuffleIndices.map((i) => allOptions[i]).toList(),
            romaji: shuffleIndices.map((i) => allRomaji[i]).toList(),
            explanations: shuffleIndices.map((i) => allExplanations[i]).toList(),
            englishMeanings: shuffleIndices.map((i) => allEnglishMeanings[i]).toList(),
            exampleSentences: shuffleIndices.map((i) => allExampleSentences[i]).toList(),
            answerIndex: newAnswerIndex,
          ));
        }
      }

      // 5. 셔플 후 count만큼 반환
      homophonePool.shuffle();
      final result = (count != null && count < homophonePool.length)
          ? homophonePool.take(count).toList()
          : homophonePool;

      return Result.success(result);
    } catch (e, stack) {
      return Result.failure('데이터베이스 처리 중 오류가 발생했습니다: $e\n$stack');
    }
  }

  @override
  Future<Result<bool, String>> submitAnswer(String quizId, int selectedIndex) async {
    return Result.success(true);
  }
}


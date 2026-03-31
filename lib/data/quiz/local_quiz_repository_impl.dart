import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';

class LocalQuizRepositoryImpl implements QuizRepository {
  static const String _assetPath = 'assets/data/quizzes.json';

  @override
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions({String? difficulty, int? count}) async {
    try {
      // 1. ByteData로 로딩하여 메인 스레드의 메모리 부하를 줄임
      final ByteData data = await rootBundle.load(_assetPath);
      
      // 2. Isolate 내에서 바이트 데이터를 직접 문자열로 변환하고 파싱함
      final List<QuizQuestion> questions = await Isolate.run(() {
        // Uint8List로 변환 후 utf8 디코딩
        final Uint8List bytes = data.buffer.asUint8List();
        final String jsonString = utf8.decode(bytes);
        final List<dynamic> jsonList = json.decode(jsonString);
        
        // 필터링 및 매핑
        var filteredList = jsonList;
        if (difficulty != null) {
          filteredList = jsonList.where((q) => q['difficulty'] == difficulty).toList();
        }
        
        var result = filteredList.map((j) => QuizQuestion.fromJson(j)).toList();
        
        // 셔플 및 개수 제한
        result.shuffle();
        if (count != null && count < result.length) {
          result = result.take(count).toList();
        }
        
        return result;
      });
      
      return Result.success(questions);
    } catch (e) {
      return Result.failure('데이터를 처리하는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<Result<bool, String>> submitAnswer(String quizId, int selectedIndex) async {
    // 로컬 환경이므로 항상 성공을 반환하거나 필요 시 정답 기록 가능
    return Result.success(true);
  }
}

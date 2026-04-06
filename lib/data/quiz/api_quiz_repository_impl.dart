import 'dart:math';

import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/data/services/api_service.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';
import 'package:playingkorean/core/utils/korean_romanizer.dart';

class ApiQuizRepositoryImpl implements QuizRepository {
  final ApiService _apiService;

  // 난이도별 대표 동음이의어 매핑 (API에 난이도가 없으므로 수동 매핑 테이블 활용)
  static const Map<String, List<String>> _levelWords = {
    '1': [
      '배',
      '말',
      '눈',
      '다리',
      '밤',
      '김',
      '벌',
      '우리',
      '가사',
      '가공',
      '경기',
      '공',
    ], // 초급
    '2': [
      '수박',
      '전기',
      '사과',
      '이상',
      '연기',
      '기사',
      '의사',
      '소리',
      '구타',
      '기록',
      '기상',
    ], // 중급
    '3': [
      '정상',
      '수도',
      '대기',
      '전시',
      '심사',
      '진술',
      '해결',
      '방향',
      '구축',
      '규명',
      '기정',
    ], // 고급
    '4': [
      '강령',
      '경륜',
      '관면',
      '구축',
      '규명',
      '기정',
      '면모',
      '부응',
      '실체',
      '심화',
      '여력',
    ], // 심화
  };

  // 외국인 학습자를 위한 영어 뜻 매핑 데이터
  static const Map<String, List<String>> _englishMeaningsMap = {
    '배': ['Ship/Boat', 'Pear', 'Belly', 'Times/Double'],
    '말': ['Horse', 'Speech/Language', 'End/Late'],
    '눈': ['Eye', 'Snow'],
    '다리': ['Bridge', 'Leg'],
    '밤': ['Night', 'Chestnut'],
    '김': ['Seaweed', 'Steam', 'Kim (Last Name)'],
    '벌': ['Bee', 'Punishment', 'Set of clothes'],
    '우리': ['We/Us', 'Cage/Pen'],
    '공': ['Ball', 'Zero', 'Public'],
    '사과': ['Apple', 'Apology'],
    '전기': ['Electricity', 'Biography', 'Early period'],
    '의사': ['Doctor', 'Intention', 'Patriot'],
    '기사': ['Knight', 'Article', 'Driver', 'Engineer'],
    '가사': ['Lyrics', 'Chore/Housework'],
    '가공': ['Processing', 'Imagine/Fake'],
    '경기': ['Game/Match', 'Economy'],
    '연기': ['Smoke', 'Acting', 'Postponement'],
    '소리': ['Sound', 'Voice'],
    '이상': ['More than', 'Abnormal', 'Ideal'],
    '정상': ['Top/Summit', 'Normal'],
    '수도': ['Capital city', 'Water supply'],
    '대기': ['Waiting', 'Atmosphere'],
    '전시': ['Exhibition', 'War time'],
    '심사': ['Screening/Judgment', 'Deep thinking'],
    '진술': ['Statement', 'Manifest'],
    '해결': ['Solution/Resolution'],
    '방향': ['Direction', 'Fragrance'],
    '구축': ['Construction', 'Expulsion'],
    '규명': ['Investigation/Clarification'],
    '기정': ['Fixed', 'Already settled'],
    '강령': ['Platform/Creed', 'Principles'],
    '경륜': ['Experience/Management', 'Cycle racing'],
    '관면': ['Dispensation', 'Exemption'],
    '면모': ['Aspect/Appearance'],
    '부응': ['Response/Fulfillment'],
    '실체': ['Substance/Reality'],
    '심화': ['Deepening/Intensification'],
    '여력': ['Surplus energy/Capacity'],
    '구타': ['Beating/Assault'],
    '기록': ['Record/Document'],
    '기상': ['Energy/Spirit', 'Weather', 'Weather condition'],
  };

  ApiQuizRepositoryImpl(this._apiService);

  @override
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions({
    String? difficulty,
    int? count,
  }) async {
    try {
      final level = difficulty ?? '1';
      final targetWords = _levelWords[level] ?? _levelWords['1']!;

      // 퀴즈 생성을 위해 API에서 여러 구간의 데이터를 가져옴 (알파벳 순이므로 골고루 가져와야 함)
      final List<int> pagesToFetch = [
        1,
        5,
        10,
        20,
        50,
        100,
        150,
        200,
        300,
        400,
        500,
      ];
      final List<Map<String, dynamic>> allRawItems = [];

      await Future.wait(
        pagesToFetch.map((page) async {
          try {
            final items = await _apiService.fetchRawDictionaryData(
              pageNo: page,
              numOfRows: 50,
            );
            allRawItems.addAll(items);
          } catch (e) {
            print('Error fetching page $page: $e');
          }
        }),
      );

      if (allRawItems.isEmpty) {
        return const Result.failure('API에서 데이터를 가져오지 못했습니다. 네트워크 연결을 확인해주세요.');
      }

      // 1. 전체 데이터 중에서 동음이의어(중복 title)를 찾고 그룹화
      final Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var item in allRawItems) {
        final title = item['title']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';

        // 필터링: 내용이 비어있거나, 하이픈으로 시작하는 접사/어미, 또는 설명에 특정 키워드 포함 시 제외
        // 주의: '배', '눈', '말' 등 1글자 단어를 포함하기 위해 length < 2 조건 제거
        if (title.isEmpty ||
            title.startsWith('-') ||
            title.endsWith('-') ||
            description.contains('어미') ||
            description.contains('조사') ||
            description.contains('접사')) {
          continue;
        }

        // 정규화 (예: 배(1) -> 배, 배1 -> 배)
        final normalizedTitle = title
            .replaceAll(RegExp(r'\(\d+\)|\d+$'), '')
            .trim();
        groupedItems.putIfAbsent(normalizedTitle, () => []).add(item);
      }

      final List<QuizQuestion> quizPool = [];
      final random = Random();

      // 2. 동음이의어 그룹에서 퀴즈 문항 생성
      for (var entry in groupedItems.entries) {
        final word = entry.key;
        final items = entry.value;

        if (items.length < 2) continue;

        // 현재 난이도의 targetWords에 포함되어 있거나,
        // 혹은 모든 동음이의어를 활용하되 난이도별로 적절히 분배함
        bool isTarget = targetWords.contains(word);
        if (!isTarget && random.nextDouble() > 0.8)
          isTarget = true; // 가끔 다른 단어도 포함

        if (!isTarget) continue;

        for (int i = 0; i < items.length; i++) {
          final targetItem = items[i];
          final List<String> options = items.map((e) => word).toList();

          // 로마자 발음 생성 (KoreanRomanizer 라이브러리 활용)
          final String autoRomaji = KoreanRomanizer.romanize(word);
          final List<String> romajiList = List.filled(items.length, autoRomaji);

          // 영어 뜻 배정
          final List<String> englishMeanings = [];
          for (int j = 0; j < items.length; j++) {
            final meanings = _englishMeaningsMap[word];
            if (meanings != null && j < meanings.length) {
              englishMeanings.add(meanings[j]);
            } else {
              // 중요: 한국어 뜻이 노출되지 않도록 빈 값 또는 Placeholder 제공
              // 외국인 학습자가 한글 뜻을 보고 답을 맞추는 것을 방지
              englishMeanings.add('');
            }
          }

          final List<String> explanations = items
              .map((e) => e['description']?.toString() ?? '')
              .toList();

          final List<int> indices = List.generate(
            items.length,
            (index) => index,
          )..shuffle();
          final newAnswerIndex = indices.indexOf(i);

          quizPool.add(
            QuizQuestion(
              id: 'api_${targetItem['uci'] ?? DateTime.now().millisecondsSinceEpoch}_$i',
              imageUrl: '',
              contextText: '{(      )}',
              options: indices.map((idx) => options[idx]).toList(),
              romaji: indices.map((idx) => romajiList[idx]).toList(),
              englishMeanings: indices
                  .map((idx) => englishMeanings[idx])
                  .toList(),
              optionImages: List.filled(items.length, ''),
              explanations: indices.map((idx) => explanations[idx]).toList(),
              exampleSentences: indices
                  .map((idx) => explanations[idx])
                  .toList(),
              difficulty: level,
              answerIndex: newAnswerIndex,
            ),
          );
        }
      }

      if (quizPool.isEmpty) {
        return const Result.failure(
          '현재 선택한 난이도에서 충분한 동음이의어 문제를 찾지 못했습니다. 다른 난이도를 시도하거나 잠시 후 다시 시도해주세요.',
        );
      }

      quizPool.shuffle();
      final resultList = quizPool.take(count ?? 10).toList();

      return Result.success(resultList);
    } catch (e) {
      return Result.failure('API 퀴즈 생성 중 오류 발생: $e');
    }
  }

  @override
  Future<Result<bool, String>> submitAnswer(
    String quizId,
    int selectedIndex,
  ) async {
    return const Result.success(true);
  }
}

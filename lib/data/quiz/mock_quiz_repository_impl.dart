import 'package:playingkorean/core/domain/result.dart';
import 'package:playingkorean/domain/quiz/quiz_question.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';

class MockQuizRepositoryImpl implements QuizRepository {
  @override
  Future<Result<List<QuizQuestion>, String>> getQuizQuestions() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final questions = [
      const QuizQuestion(
        id: '1',
        imageUrl: 'https://images.unsplash.com/photo-1541819584-60c756fdfcd9', // 배(과일) 이미지
        contextText: '가을에 먹는 달콤하고 시원한 과일이에요.',
        options: ['배', '배', '배', '사과'],
        romaji: ['Bae', 'Bae', 'Bae', 'Sagwa'],
        englishMeanings: ['Pear', 'Boat', 'Belly', 'Apple'],
        optionImages: [
          'https://images.unsplash.com/photo-1541819584-60c756fdfcd9', // Pear
          'https://images.unsplash.com/photo-1498084393753-b411b2d26b34', // Boat
          'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7', // Belly/Health
          'https://images.unsplash.com/photo-1570913149827-d2ac84ab3f9a', // Apple
        ],
        explanations: [
          '먹는 과일 "배"입니다. 한국 배는 크고 둥글고 달아요.',
          '바다를 떠다니는 운송수단인 "배"입니다.',
          '사람이나 동물의 신체 부위인 "배"입니다.',
          '빨갛고 맛있는 다른 과일인 "사과"입니다.',
        ],
        exampleSentences: [
          '추석에는 가족들과 달콤한 배를 깎아 먹어요.',
          '푸른 바다 위에 커다란 배가 떠 있어요.',
          '너무 많이 먹어서 배가 빵빵해졌어요.',
          '아침에 먹는 사과는 건강에 아주 좋아요.',
        ],
        answerIndex: 0,
      ),
      const QuizQuestion(
        id: '2',
        imageUrl: 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a', // 말(동물) 이미지 
        contextText: '이 동물을 타고 들판을 달려요.',
        options: ['말', '말', '소', '개'],
        romaji: ['Mal', 'Mal', 'So', 'Gae'],
        englishMeanings: ['Horse', 'Speech', 'Cow', 'Dog'],
        optionImages: [
          'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a', // Horse
          'https://images.unsplash.com/photo-1522071823991-b5ae72643a51', // Speech/Chat
          'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e', // Cow
          'https://images.unsplash.com/photo-1517841905240-472988babdf9', // Dog
        ],
        explanations: [
          '다리가 4개이고 아주 빨리 달리는 동물 "말"입니다.',
          '사람들이 입으로 내뱉는 언어나 소리인 "말"입니다.',
          '우유를 주는 덩치가 큰 동물 "소"입니다.',
          '사람과 가장 친한 동물인 "개"입니다.',
        ],
        exampleSentences: [
          '제주도에 가서 멋진 말을 타고 달렸어요.',
          '예쁜 말을 쓰면 듣는 사람도 기분이 좋아져요.',
          '농장에서 소가 평화롭게 풀을 뜯고 있어요.',
          '귀여운 강아지가 꼬리를 흔들며 반겨줘요.',
        ],
        answerIndex: 0,
      ),
      const QuizQuestion(
        id: '3',
        imageUrl: 'https://images.unsplash.com/photo-1478131143081-344c2084f708', // 눈(날씨) 이미지
        contextText: '겨울에 하늘에서 하얀 가루가 내려와요.',
        options: ['눈', '눈', '비', '구름'],
        romaji: ['Nun', 'Nun', 'Bi', 'Gureum'],
        englishMeanings: ['Snow', 'Eye', 'Rain', 'Cloud'],
        optionImages: [
          'https://images.unsplash.com/photo-1478131143081-344c2084f708', // Snow
          'https://images.unsplash.com/photo-1544717297-fa15c3902726', // Eye
          'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17', // Rain
          'https://images.unsplash.com/photo-1504608524841-42fe6f032b4b', // Cloud
        ],
        explanations: [
          '겨울에 하늘에서 내리는 하얗고 차가운 "눈"입니다.',
          '얼굴에 있고 사물을 볼 때 사용하는 신체 부위인 "눈"입니다.',
          '하늘에서 떨어지는 물방울인 "비"입니다.',
          '하늘에 둥둥 떠 있는 하얀 솜 같은 "구름"입니다.',
        ],
        exampleSentences: [
          '겨울이 되니 온 세상이 하얀 눈으로 덮였어요.',
          '안경을 썼더니 눈이 훨씬 더 잘 보여요.',
          '우산을 안 가지고 왔는데 비가 오기 시작해요.',
          '맑은 하늘에 하얀 뭉게구름이 떠 있어요.',
        ],
        answerIndex: 0,
      ),
    ];
    
    return Result.success(questions);
  }

  @override
  Future<Result<bool, String>> submitAnswer(String quizId, int selectedIndex) async {
    return const Result.success(true);
  }
}

1. 폴더의 기본구조 : 클린아키텍처 기반의 MVVM
2. 기본구조 : core / data / domain / presentation
3. 폴더 하위 상세구조
    core - data (공통 데이터 처리, DB helper 등)
        di (get_it 의존성 주입)
        domain (공통 모델 및 Result 패턴)
        presentation (공통 테마 및 위젯)
        routing (go_router 설정)
        audio (효과음 및 배경음 관리)
    data - quiz (퀴즈 데이터 소스 및 저장소 구현)
        data_source (local_quiz_source 등)
        repository (local_quiz_repository_impl 등)
    domain - quiz (퀴즈 관련 비즈니스 로직 및 모델)
        model (quiz_question 등)
        repository (quiz_repository 인터페이스)
        use_case (get_quiz_use_case 등)
    presentation - home (홈 화면 및 설정)
                quiz_game (퀴즈 게임 엔진 및 화면)
                widgets (공통 사용 위젯)

4. 상태관리 및 주요 라이브러리
    - rxdart (BehaviorSubject를 이용한 상태 관리)
    - get_it (의존성 주입)
    - go_router (라우팅 관리)
    - sqflite (로컬 퀴즈 데이터 저장 및 검색)
    - audioplayers (게임 음향 효과)
    - freezed & json_annotation (모델 직렬화)

5. 난이도 및 퀴즈 구성 로직
    - 초급 (Level 1): 뜻이 정확히 2개인 동음이의어만 출제
    - 중급 (Level 2~3): 뜻이 3개 이하인 동음이의어 출제
    - 고급 (Level 4): 뜻이 4개 이하인 동음이의어 출제 (일단 보류)
    - 표시 형식: '단어-발음(Romaji)-영어뜻' (예: 밤-bam-night)

6. UI/UX 디자인 원칙
    - Kahoot 스타일의 역동적인 퀴즈 버튼 UI
    - 정답/오답 애니메이션 피드백 (스케일 변화 등)
    - 프리미엄 결과 화면 (점수 분석 및 시각적 효과)
    - 반응형 디자인 (다양한 화면 크기 대응)

7. 에러 처리 전략
    - Result 패턴을 통한 데이터 로딩 및 DB 처리 에러 핸들링
    - 데이터 로딩 실패 시 사용자 친화적인 복구 UI 제공

    
<!-- 1. 폴더의 기본구조 : 클린아키텍처 기반의 MVVM
2. 기본구조 : core / data / domain / presentation
3. 폴더 하위 상세구조 (현재는 레시피를 만드는 앱의 구조로 되어있음 - 프로젝트마다 약간씩 다르게 될 수 있음 saved_recipes 같은것들)
    core - data 
        di
        domain
        presentation
        routing
    data - clipboard
        data_source
        repository
    domain - clipboard
            data_sorce
            error
            filter
            model
            repository
            use_case
    presentation - home
                ingredients
                main
                notification
                profile
                saved_recipes
                search
                sign_in
                sign_up

4.상태관리 라이브러리는 기본 기능으로 구현한다
    cupertino_icons 사용
    go_router 사용
    freezed_anotation 사용
    get_it 사용
    json_annotation 사용
    rxdart 사용

5. 테스트 가능한 UI 설계

예시 ) 
class HomeScreen extends StatelessWidget {
    final HomeState state;
    final void Function(HomeAction action) onAction;

    const HomeScreen({
        super.key,
        required this.state,
        required this.onAction,
    });
}

6. 딥링크 친화적인 라우터 구성

예시 )
static const savedRecipes = '/saved_recipes';
static const notifications = '/notifications';
static const profile = '/profile';

static const search = 'Home/search';
static const ingredient = 'Home/Ingredient/:recipeId';

static const test = '/Test';

7. 더 복합한 에러처리를 위한 에러 핸들링 전략
기존 Result 패턴을 개량하여 복합한 상황에 적절한 에러처리 방법 제시

예시 )

Future<Result<List<Recipe>, NewRecipeError>> execute() async {
  try {
    final recipes = await _recipeRepository.getRecipes();

    if (recipes.isEmpty) {
      return const Result.error(NewRecipeError.noRecipe);
    }

    if (recipes.any((e) => e.category.isEmpty)) {
      return const Result.error(NewRecipeError.invalidCategory);
    }

    return Result.success(recipes.take(5).toList());
  } catch (e) {
    return const Result.error(NewRecipeError.unknown);
  }
}

6. 실무에서 사용할 수 있는 코드 형태를 제시

예 )

//Before
class HomeScreen extends StatefulWidget {
    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

//After
class HomeScreen extends StatelessWidget {
    final HomeState state;
    final void Function(HomeAction action) onAction;

 //테스트 가능하고 재사용성 높은 코드 작성   
} -->


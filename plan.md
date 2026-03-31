1. 폴더의 기본구조 : 클린아키텍처 기반의 MVVM, MVI

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
}
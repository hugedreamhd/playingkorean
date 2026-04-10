## Plan 기준 정합성 점검 결과

기준 문서:
- `plan/plan.md`
- `plan/achitecture.md`
- `plan/implementation_plan.md`

### 1) 폴더 구조 (클린 아키텍처 기반 MVVM)
- **core / data / domain / presentation**: **충족**
  - `lib/core/`, `lib/data/`, `lib/domain/`, `lib/presentation/` 존재
- **세부 구조(권장) 대비**
  - **DI**: `lib/core/di/di_setup.dart` 존재 (**충족**)
  - **routing**: `go_router`는 `lib/main.dart`에 직접 정의 (**부분 충족**: plan의 `core/routing` 폴더는 없음)
  - **data_source/repository 분리**: `lib/data/quiz/` 아래에 구현체가 있으나, 폴더 레벨로 `data_source/` vs `repository/`로 분리되어 있진 않음 (**부분 충족**)

### 2) 데이터 흐름 (오프라인 로컬 DB)
- plan 목표: **assets → SQLite 시딩 → 빠른 조회**
- 현 상태:
  - `assets/data/quizzes.json` 존재
  - `lib/core/data/database_helper.dart`에서 `sqflite` 사용
  - `lib/data/quiz/local_quiz_repository_impl.dart`가 **assets/data/quizzes.json → SQLite 시딩**을 수행
- **주의(핵심)**: DI가 API 저장소로 고정되면 오프라인 플로우가 실행되지 않음 → DI를 Local로 고정 필요

### 3) 난이도 & 퀴즈 구성 로직
기준(plan/plan.md):
- Level 1: 뜻 2개 동음이의어
- Level 2~3: 뜻 3개 이하
- Level 4: 뜻 4개 이하
- 보기 표시는 '단어-발음-영어뜻'

현 상태:
- `LocalQuizRepositoryImpl`에서 동음이의어 그룹을 만들고 문제를 생성 (**부분 충족**)
- 최근 요구사항 반영: 보기 4개 강제 생성 없이 **2 또는 3개만** 보여주도록 설계 (**plan 문구와는 조정 필요**)
  - (의미가 4개 이상인 단어도 2~3개로 샘플링해 출제할지, 레벨 규칙대로 제한할지 정책 결정 필요)
- 표시 형식:
  - 보기 버튼에서 romaji(발음) + meaning(영어뜻/설명) 표시 로직은 구현됨 (**부분 충족**)

### 4) UI/UX
- Kahoot 스타일 보기 버튼: `presentation/quiz_game/widgets/kahoot_choice_button.dart` 존재 (**충족**)
- Shimmer/Skeleton 로더: `presentation/quiz_game/widgets/quiz_skeleton_loader.dart` 존재 (**부분 충족**: 실제 화면 전환 연동 여부는 별도 확인 필요)

### 5) 불필요/중복 자원 후보(삭제 없이 “권고”)
- API 경로: `lib/data/quiz/api_quiz_repository_impl.dart`, `lib/data/services/api_service.dart`
  - 오프라인 고정 시 **백업/개발용으로만 유지** 권고
- Seeder 경로: `lib/data/quiz/vocabulary_seeder.dart`
  - `assets/data/*_5000_20260319.json` 11개 기반. 런타임 경로에서 호출되지 않으면 **죽은 코드 후보**.
- 대용량 개발 데이터: `source_data/` + `scripts/`
  - 앱 런타임과 무관하면 별도 보관(archive) 권고


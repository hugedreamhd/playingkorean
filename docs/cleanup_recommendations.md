## 불필요/중복 파일 및 정리 권고 (삭제 없이)

요청하신 기준: **삭제는 하지 않고** “지금 프로젝트에 꼭 필요한가?” 관점에서 분류합니다.

### A. 앱 런타임에 필요한 핵심(유지)
- `lib/` 전반 (앱 코드)
- `assets/data/quizzes.json` (오프라인 퀴즈 데이터, 현재 Local DB 파이프라인의 공식 소스)
- `assets/data/` 폴더 자체 (`pubspec.yaml`에서 `assets/data/` 전체를 assets로 포함)
- `plan/` (요구사항/아키텍처 기준 문서)

### B. 현재 플로우에서 “죽은 코드” 후보(유지하되 역할 명확화 필요)
오프라인(Local DB: `quizzes.json`)로 고정했을 때, 아래는 실행 경로에서 빠질 가능성이 큽니다.
- `lib/data/quiz/api_quiz_repository_impl.dart`
  - **상태**: DI에서 더 이상 기본 저장소로 쓰지 않는다면 “백업/실험용”으로만 의미가 있음
- `lib/data/services/api_service.dart`
  - **상태**: 위 API repository와 세트. 사용하지 않으면 유지 이유가 없음
- `lib/data/quiz/mock_quiz_repository_impl.dart`
  - **상태**: 테스트/데모용으로만 사용. 실제 앱 플로우에서 호출 없으면 “개발용”으로 표시 권고

권고:
- 위 3개는 삭제 대신 `dev_only/` 네임스페이스로 분리하거나, DI 전환 옵션(플래그) 도입 전까지는 “보관” 처리 권고.

### C. Plan 문서(implementation_plan) 계열의 Seeder/최소대립어 엔진 후보
현재 프로젝트에는 두 가지 데이터 파이프라인이 공존합니다.
- 파이프라인 1(현재 공식): `assets/data/quizzes.json` → `quizzes` 테이블 → 동음이의어 퀴즈
- 파이프라인 2(확장/실험): 11개 `*_5000_20260319.json` → `vocabulary` 테이블 → 최소대립어/학습자 사전 엔진

아래는 파이프라인 2에 해당하며, 공식 플로우에서 호출되지 않으면 “보관/실험용”이 됩니다.
- `lib/data/quiz/vocabulary_seeder.dart`
- `assets/data/*_5000_20260319.json` 11개

권고:
- 파이프라인 2를 당장 쓰지 않으면, **앱 번들 크기**에 크게 영향이 있으니(assets로 포함됨) 향후 다음 중 하나를 선택 권고
  - (추천) 별도 저장소/아카이브로 이동 후, 필요할 때만 다시 포함
  - 또는 assets include를 개별 파일로 좁혀서(필요한 것만) 번들 축소

### D. 개발용 원본 데이터/전처리 스크립트(보관 권고)
앱 런타임에는 필요 없고, 데이터 생성/검증에만 필요할 가능성이 큼.
- `source_data/` (대용량 원본 JSON 조각들)
- `scripts/` (전처리/분석 스크립트들)

권고:
- 삭제 대신 별도 아카이브(예: `tools/` 또는 외부 저장소)로 분리하는 게 일반적입니다.

### E. 자동 생성/빌드 산출물(레포에 커밋하지 않기 권고)
- `build/`, `.dart_tool/`, `android/.gradle` 등

권고:
- 이미 `.gitignore`가 있긴 하지만(레포로 관리할 경우) 포함 여부를 재점검 권고.


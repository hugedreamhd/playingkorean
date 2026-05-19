

<!-- # 학습자 중심 하이브리드 엔진 구축 계획 (Phase 4)

제공된 대용량 사전 데이터를 활용하여 외국인 학습자(특히 초급)에게 최적화된 동음이의어 및 최소 대립어(밤/밥/발) 퀴즈 환경을 구축합니다.

## 1. 목적
- **데이터 경량화**: 1GB 규모의 JSON에서 초급/중급용 핵심 데이터(영어 뜻 포함)만 추출하여 앱 용량 최적화.
- **반응성 개선**: SQLite 로컬 캐싱을 이용한 즉각적인 문제 생성.
- **시각적 완성도**: Shimmer(Skeleton UI)를 도입하여 로딩 중 깜빡임 제거 및 프리미엄 느낌 부여.

## 2. 주요 아키텍처 및 변경 사항

### 데이터 계층 (Data Layer)
- **[NEW] `QuizDatabaseHelper`**: 
  - `sqflite`를 통한 데이터 영구 저장 및 단어 자소 분석(조성/중성/종성) 기능.
- **[NEW] `VocabularySeeder`**: 
  - 대용량 JSON에서 필요한 데이터만 선별하여 SQLite로 옮겨주는 마이그레이션 유틸리티.
- **[REFAC] `LocalQuizRepositoryImpl`**: 
  - 신규 DB를 소스로 사용하며, Level 1에서 자소 분석 기반의 '헷갈리기 쉬운 보기'를 자동 생성.

### UI/UX 폴리싱
- **[NEW] `QuizShimmerScreen`**: 
  - `shimmer` 패키지를 적용하여 데이터 로딩 중 세련된 로딩 화면 노출.
- **[MODIFY] `QuizScreen`**: 
  - 실제 퀴즈와 Shimmer 화면을 매끄럽게 교체하는 상태 관리 로직 추가.

## 3. 세부 작업 로드맵

### 1단계: 개발 환경 구축 및 DB 설계
- `pubspec.yaml` 업데이트 및 기본 DB 스키마 정의.
- 자소 분리 라이브러리 또는 유틸리티 작성.

### 2단계: 데이터 마이그레이션 및 Seeding
- JSON 파일에서 초급 단어 필터링 실습.
- 첫 실행 시 데이터를 SQLite로 안전하게 옮기는 Seeder 구현.

### 3단계: 퀴즈 생성 로직 (Minimal Pairs)
- '종성(받침)'만 다른 단어를 찾는 쿼리 등을 활용한 최소 대립어 생성 알고리즘 구현.
- 사용자가 보고한 '딱딱한 문제'를 방지하기 위해 `vocabularyLevel` 필터링 강제 적용.

### 4단계: UX 개선
- Shimmer UI 적용 및 문제 간 부드러운 전환 효과 추가.

## 4. 참고 사항
- **데이터 범위**: 초기에는 사용자 설치 편의를 위해 `1_5000_...json` 중 **초급** 데이터만 우선적으로 색인합니다.
- **성능**: 1회 색인이 완료되면 이후에는 API 연동 없이 매우 빠른 속도로 동작합니다. -->
plan.md (개정판)
⚙️ 학습자 중심 하이브리드 엔진 구축 계획 (Phase 4 - Core Logic)
국립국어원 사전 데이터를 플러터 내부 환경에 최적화하여 캡슐화하고, 네트워크 독립적인 문맥 기반 한-영 동음이의어 퀴즈 핵심 구동 엔진을 구축합니다.

1. 데이터 아키텍처 및 코어 로직 변경 사항
🗄️ 데이터 계층 (Data Layer)
QuizDatabaseHelper (sqflite 연동)

데이터 가공 에이전트로부터 정제 완료된 고품질 JSON/CSV 원본을 기기 로컬 저장소에 영구 적재.

퀴즈의 반응성(Response Time) 확보를 위해 word 및 level 컬럼에 인덱스(Index) 생성.

VocabularySeeder [MIGRATION]

앱 최초 구동 시 단 1회 실행. Assets 영역에 패키징된 정제 사전 자원을 SQLite 내부로 마이그레이션하는 유틸리티 클래스.

LocalQuizRepositoryImpl [BUSINESS LOGIC]

UI Layer의 요청 난이도(Level 1, 2, 3)에 따라 매칭되는 레코드셋을 동적 쿼리로 패치.

조사(Particle) 처리 로직: 예문 문장 가공 시 정답 단어와 조사("밤이", "연기를")를 식별하여, 형태소 분석 혹은 규칙 기반 분리를 통해 정답 외 영역만 괄호 ( ) 시스템으로 치환하는 텍스트 가공 수행.

2. 세부 작업 로드맵
1단계: 개발 환경 구축 및 로컬 DB 스키마 설계
pubspec.yaml에 sqflite, path 라이브러리 종속성 추가.

SQLite 스키마 정의:

SQL
CREATE TABLE quiz_vocabulary (
  quiz_id INTEGER PRIMARY KEY AUTOINCREMENT,
  level TEXT NOT NULL,                -- Beginner, Intermediate, Advanced
  word TEXT NOT NULL,                 -- 표제어 (예: 밤)
  romanization TEXT NOT NULL,         -- 영어 발음 표기 (예: Bam)
  question_sentence TEXT NOT NULL,    -- 가공 전 예문
  correct_meaning_en TEXT NOT NULL,   -- 정답 영어 뜻풀이
  wrong_meanings_json TEXT NOT NULL   -- 오답 리스트 (JSON Array String 형태)
);
2단계: 데이터 세팅 (Migration & Seeding)
에이전트가 가공한 '초급/중급(A, B 등급) 중심 한 글자 및 두 글자 한자어 혼합 데이터셋' 검증.

VocabularySeeder를 구현하여 앱 최초 구동 시 에러 없이 완벽하게 로컬 SQLite 테이블에 Bulk Insert 처리 완료.

3단계: 난이도(Level)별 동적 퀴즈 생성 엔진 구현
UI에서 선택된 난이도 주입(Dependency Injection)에 따라 쿼리 및 보기 바인딩 로직을 분기 처리:

초급 (Level 1): 글자와 발음이 같고 뜻이 2개로 갈리는 동음이의어 전용 쿼리 실행. UI단에 전달할 정답 1개 + 오답 1개 총 2개의 보기 배열 반환.

중급 (Level 2): 두 글자 한자어를 포함하여 뜻이 3개인 다의어/동음이의어 세트 쿼리 실행. 정답 1개 + 오답 2개 총 3개의 보기 배열 반환.

고급 (Level 3 - 최소 대립어 활용): 정답 단어와 종성(받침) 또는 모음 구조만 다른 가짜 보기(Distractor, 예: 밤/밥/뱀)를 데이터 세트 안에서 실시간으로 역추적 결합. 정답 1개 + 오답 3개 총 4개의 보기 배열 반환.

4단계: 상태 관리 및 코어 컨트롤러 구현
15초 타임아웃 메커니즘: dart:async 패키지의 Timer.periodic을 사용하여 각 문항당 15초 카운트다운 구현. 0초 도달 시 자동으로 다음 문항 이동 또는 오답 처리 상태(State) 트리거.

비동기 상태 전이 관리: 로컬 DB에서 Future 형태로 퀴즈 데이터셋을 패치해 오는 동안의 런타임 지연을 전담 마킹하는 비조작 바인딩 상태 제어 로직 구현.

3. 참고 사항
데이터 모델 정형화: SQLite에 직렬화되어 문자열로 저장된 오답 리스트(wrong_meanings_json)를 Dart 내에서 다루기 편하도록 jsonDecode를 수행하는 Factory 생성자 패턴을 릴레이션 모델에 내장할 것.

안정성 예외 처리: 사용자가 홈 화면 도중 백버튼을 누르거나 앱이 백그라운드로 전환될 때 구동 중인 Timer 인스턴스가 메모리 누수(Memory Leak)를 일으키지 않도록 반드시 cancel() 메서드를 실행할 것.
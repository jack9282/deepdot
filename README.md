# 🍀 DeepDot (딥닷)

**ADHD 당사자를 위한 올인원 자기관리 앱**

'DeepDot'은 지속 가능한 루틴과 습관 형성을 목표로, ADHD 당사자들에게 꼭 필요한 기능들을 부담 없이 제공하는 자기관리 앱입니다.

## 📝 프로젝트 소개 (Project Overview)

이 프로젝트는 'ADHD는 관리도 돈 내고 받아야 하나?'라는 고민에서 시작되었습니다. 5주의 개발 기간 동안 사용자가 가장 필요로 하는 핵심 기능들을 중심으로 MVP(Minimum Viable Product)를 구현하는 것을 목표로 합니다.

**핵심 기능 (1차 MVP)**

  * **아이젠하워 매트릭스** 기반 일정 관리
  * **포모도로 타이머**를 통한 집중력 관리
  * **복약 체크리스트** 및 내역 관리
  * **루틴 생성** 및 오늘의 루틴 체크리스트
  * 핵심 기능에 대한 **푸시 알림** 연동

## 🛠️ 기술 스택 및 아키텍처 (Tech Stack & Architecture)

### 기술 스택 (Tech Stack)

  * **Framework**: Flutter
  * **State Management**: Provider (또는 Bloc)
  * **Routing**: GoRouter
  * **API Client**: Dio
  * **Local DB**: Hive (또는 sqflite)

### 📂 폴더 구조 (Folder Structure)

본 프로젝트는 빠른 MVP 개발에 최적화된 **실용적인 기능 중심(Feature-First) 구조**를 따릅니다.

```bash
lib/
├── main.dart             # 앱 시작점

#==============================================================================
# 📁 1. Data (모델 및 데이터 통신)
#==============================================================================
├── data/
│   ├── models/           # 서버나 DB와 주고받을 데이터 모델 (예: schedule_model.dart)
│   └── repositories/     # 데이터 로직 처리 (API 호출, DB 접근 등)
│       ├── auth_repository.dart
│       └── schedule_repository.dart


#==============================================================================
# 📁 2. Features (화면 및 상태 관리)
#==============================================================================
├── features/
│   # ✨ 기능별 폴더 구조는 동일하게 유지합니다. 이게 핵심입니다! ✨
│   ├── auth/
│   │   ├── screens/              # 로그인, 회원가입 UI
│   │   │   └── login_screen.dart
│   │   └── view_models/          # UI의 상태와 로직 관리 (Provider, Bloc 등)
│   │       └── auth_view_model.dart
│   │
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── view_models/
│   │   │   └── home_view_model.dart
│   │   └── widgets/              # Home 기능에서만 사용하는 위젯
│   │
│   ├── schedule/
│   │   ├── screens/
│   │   │   └── schedule_edit_screen.dart
│   │   └── view_models/
│   │       └── schedule_view_model.dart
│   │
│   └── # (pomodoro, medication 등 다른 기능들도 동일한 구조로 추가)


#==============================================================================
# 📁 3. Common (공용 리소스)
#==============================================================================
└── common/
    ├── services/                 # 알림, 권한 등 공용 서비스
    │   └── notification_service.dart
    ├── theme/                    # 앱 테마 (색상, 폰트)
    │   └── app_theme.dart
    ├── router/                   # 화면 이동 라우터
    │   └── app_router.dart
    └── widgets/                  # 앱 전체에서 사용하는 공용 위젯
        ├── custom_button.dart
        └── loading_indicator.dart
```

## 🚀 시작하기 (Getting Started)

프로젝트를 로컬 환경에서 실행하기 위한 절차입니다.

**1. 프로젝트 클론 (Clone Repository)**

```shell
git clone https://github.com/jack9282/deepdot.git
cd deepdot
```

**2. 패키지 설치 (Install Dependencies)**

```shell
flutter pub get
```

**3. 코드 생성 실행 (Run Code Generation)**
*모델 등 자동 생성이 필요한 코드가 있는 경우 아래 명령어를 실행합니다.*

```shell
flutter pub run build_runner build --delete-conflicting-outputs
```

**4. 앱 실행 (Run App)**

```shell
flutter run
```

## ✨ 협업 규칙 (Collaboration Rules)

원활한 협업을 위해 아래 규칙을 반드시 준수해 주세요.

### 🌱 브랜치 전략 (Branch Strategy)

  * `main`: 최종 배포 버전이 위치하는 브랜치
  * `develop`: 개발의 중심이 되는 브랜치
  * `feature/{기능이름}`: 새로운 기능 개발 브랜치 (예: `feature/login`)
  * `fix/{수정이름}`: 버그 수정 브랜치 (예: `fix/feed-bug`)

**작업 순서:** `develop` 브랜치에서 새로운 `feature` 브랜치를 생성하여 작업을 시작합니다.

### 💬 커밋 메시지 (Commit Message)

`type(scope): subject` 형식으로 작성합니다.

  * **type**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  * **예시**:
      * `feat(login): 소셜 로그인 기능 추가`
      * `fix(home): 피드 새로고침 오류 수정`

### ✅ Pull Request (PR)

`develop` 브랜치로 PR을 보낼 때 아래 템플릿을 사용해 주세요.

```markdown
## 📝 요약 (Summary)

> 이 PR에서 어떤 작업을 했는지 간략하게 설명해주세요.

## ✅ 작업 상세 내용 (Task Details)

> - [ ] 로그인 UI 구현
> - [ ] API 연동 및 테스트
> - [ ] 예외 처리 로직 추가

## 🔗 관련 이슈 (Related Issues)

> - Close #[이슈번호]
```

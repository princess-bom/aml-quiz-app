# AML Quiz App

TPAC 시험 대비를 위한 자금세탁방지(AML) 퀴즈 웹 애플리케이션

## 프로젝트 개요

이 프로젝트는 자금세탁방지(AML) 관련 지식 습득 및 평가를 위한 모바일 최적화 퀴즈 웹앱입니다. TPAC 시험 대비를 목적으로 하며, 사용자가 웹브라우저를 통해 퀴즈를 풀고 학습할 수 있는 핵심 기능을 제공합니다.

## 기술 스택

- **백엔드**: Ruby on Rails 8.0.2
- **프론트엔드**: HTML, CSS (Tailwind CSS 4.0), JavaScript (Stimulus)
- **컴포넌트**: ViewComponent 3.0
- **아이콘**: rails_icons
- **데이터베이스**: Firebase Firestore
- **인증**: Firebase Authentication
- **에셋 파이프라인**: Propshaft

## 주요 기능

### 핵심 기능
- 📝 **퀴즈 풀이**: 5지 선다형 문제 풀이
- ✅ **즉시 피드백**: 답변 제출 후 즉시 정답 확인 및 해설 제공
- 📊 **실시간 진행률**: 퀴즈 진행 상황 추적
- 🏆 **결과 분석**: 상세한 점수 및 성과 분석

### 사용자 인증
- 🔐 **Firebase Authentication**: 안전한 사용자 인증
- 🛠️ **개발 모드**: 개발 환경에서 간편한 로그인 지원

### 학습 관리
- 📈 **진행률 추적**: 세션별 학습 진행 상황 모니터링
- 📋 **답안 검토**: 각 문제에 대한 상세한 답안 분석
- 💯 **점수 계산**: 문제별 배점(5점, 10점, 15점)에 따른 점수 산출

## 설치 및 실행

### 1. 프로젝트 클론
```bash
git clone <repository-url>
cd aml_quiz_app
```

### 2. 의존성 설치
```bash
bundle install
```

### 3. Firebase 설정
1. Firebase 프로젝트 생성
2. Service Account 키 생성 후 `config/firebase/service_account.json`에 저장
3. 환경 변수 설정:
   ```bash
   cp .env.example .env
   # .env 파일에서 Firebase 프로젝트 ID 설정
   ```

### 4. 개발 서버 실행
```bash
bin/dev
```

또는 개별 서버 실행:
```bash
bin/rails server
bin/rails tailwindcss:watch
```

### 5. 브라우저에서 확인
http://localhost:3000 접속

## 개발 모드 사용법

개발 환경에서는 Firebase 인증 없이 간편하게 로그인할 수 있습니다:

1. 로그인 페이지에서 "개발 모드 로그인" 버튼 클릭
2. 또는 URL에 `?dev_auth=true` 파라미터 추가

## 프로젝트 구조

```
app/
├── components/              # ViewComponent 컴포넌트
│   ├── quiz_question_component.rb
│   ├── quiz_result_component.rb
│   └── ...
├── controllers/            # Rails 컨트롤러
│   ├── application_controller.rb
│   ├── home_controller.rb
│   ├── sessions_controller.rb
│   ├── quizzes_controller.rb
│   └── quiz_results_controller.rb
├── models/                 # 데이터 모델
│   ├── quiz.rb
│   ├── quiz_session.rb
│   └── concerns/
│       ├── firebase_auth.rb
│       └── authentication.rb
├── views/                  # 뷰 템플릿
│   ├── layouts/
│   ├── home/
│   ├── sessions/
│   ├── quizzes/
│   └── quiz_results/
└── javascript/             # Stimulus 컨트롤러
    └── controllers/
        └── quiz_form_controller.js
```

## 데이터 모델

### Quiz (퀴즈)
- `question`: 문제 내용
- `score`: 문제 배점 (5, 10, 15점)
- `choices`: 5개의 선택지
- `correct_answer`: 정답
- `explanation`: 해설
- `reference`: 참고 자료
- `difficulty`: 난이도 (easy, medium, hard)
- `category`: 문제 카테고리

### QuizSession (퀴즈 세션)
- `user_id`: 사용자 ID
- `quiz_ids`: 문제 ID 배열
- `current_quiz_index`: 현재 문제 인덱스
- `answers`: 답변 기록
- `score`: 총 점수
- `correct_answers`: 정답 수
- `status`: 세션 상태 (active, completed)

## 배포

### Firebase 설정
1. Firebase 프로젝트에서 Firestore 활성화
2. 보안 규칙 설정
3. Service Account 키 생성

### 프로덕션 환경 변수
```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
```

## 개발 가이드

### 새로운 컴포넌트 추가
```bash
rails generate component ComponentName
```

### 퀴즈 데이터 추가
Firebase Firestore의 `quizzes` 컬렉션에 직접 데이터 추가하거나 Rails 콘솔 사용:

```ruby
Quiz.create(
  question: "문제 내용",
  score: 10,
  choices: ["선택지1", "선택지2", "선택지3", "선택지4", "선택지5"],
  correct_answer: "선택지1",
  explanation: "해설 내용",
  reference: "참고 자료",
  difficulty: "medium",
  category: "AML"
)
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

## 기여

1. Fork 프로젝트
2. Feature 브랜치 생성 (`git checkout -b feature/AmazingFeature`)
3. 변경 사항 커밋 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 Push (`git push origin feature/AmazingFeature`)
5. Pull Request 생성

## 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해 주세요.

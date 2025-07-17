# AML Quiz App 설정 가이드

이 문서는 AML Quiz App의 개발 환경 설정과 Firebase 연동을 위한 상세한 가이드입니다.

## 1. 개발 환경 설정

### 필수 요구사항
- Ruby 3.4.0 이상
- Rails 8.0.2
- Node.js (Tailwind CSS 컴파일용)
- Firebase 프로젝트

### 의존성 설치
```bash
# 프로젝트 디렉토리로 이동
cd aml_quiz_app

# Ruby 의존성 설치
bundle install

# 필요한 경우 Node.js 의존성 설치
npm install
```

## 2. Firebase 프로젝트 설정

### 2.1 Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: `aml-quiz-app`)
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

### 2.2 Firestore 설정
1. Firebase 콘솔에서 "Firestore Database" 선택
2. "데이터베이스 만들기" 클릭
3. 보안 규칙 모드 선택:
   - 개발 시: "테스트 모드에서 시작"
   - 운영 시: "프로덕션 모드에서 시작"
4. 데이터베이스 위치 선택 (권장: asia-northeast1)

### 2.3 Service Account 키 생성
1. Firebase 콘솔에서 "프로젝트 설정" → "서비스 계정" 탭
2. "새 비공개 키 생성" 클릭
3. JSON 파일 다운로드
4. 파일명을 `service_account.json`으로 변경
5. `config/firebase/` 디렉토리에 저장

### 2.4 Firebase Authentication 설정 (선택사항)
1. Firebase 콘솔에서 "Authentication" 선택
2. "시작하기" 클릭
3. "Sign-in method" 탭에서 원하는 인증 방법 활성화:
   - 이메일/비밀번호
   - Google
   - 기타 소셜 로그인

## 3. 환경 변수 설정

### 3.1 환경 변수 파일 생성
```bash
cp .env.example .env
```

### 3.2 .env 파일 수정
```bash
# Firebase 프로젝트 ID (Firebase 콘솔에서 확인)
FIREBASE_PROJECT_ID=your-firebase-project-id

# 프로덕션 환경에서만 사용 (로컬 개발 시 주석 처리)
# FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"your-project-id",...}'
```

### 3.3 Firebase 프로젝트 ID 확인 방법
1. Firebase 콘솔에서 프로젝트 설정 클릭
2. "일반" 탭에서 "프로젝트 ID" 확인
3. `.env` 파일에 정확히 입력

## 4. 데이터베이스 초기화

### 4.1 샘플 퀴즈 데이터 추가
Rails 콘솔을 사용하여 초기 데이터 추가:

```bash
bin/rails console
```

```ruby
# 샘플 퀴즈 데이터 생성
Quiz.create(
  question: "자금세탁방지법(AML)에서 규정하는 고객확인의무(CDD)에 대한 설명으로 옳은 것은?",
  score: 10,
  choices: [
    "고객확인은 계좌개설 시에만 수행하면 된다",
    "고객확인은 거래 금액에 관계없이 항상 동일한 수준으로 수행한다",
    "고객의 위험도에 따라 차등적으로 고객확인을 수행해야 한다",
    "고객확인은 법인 고객에게만 적용된다",
    "고객확인의무는 권고사항이므로 선택적으로 수행할 수 있다"
  ],
  correct_answer: "고객의 위험도에 따라 차등적으로 고객확인을 수행해야 한다",
  explanation: "자금세탁방지법에서는 위험기반접근법(RBA)을 채택하여 고객의 위험도에 따라 차등적으로 고객확인을 수행하도록 규정하고 있습니다. 고위험 고객에게는 강화된 고객확인(EDD)을, 저위험 고객에게는 간소화된 고객확인(SDD)을 적용할 수 있습니다.",
  reference: "자금세탁방지법 제4조, 제5조",
  difficulty: "medium",
  category: "AML"
)

Quiz.create(
  question: "의심거래보고(STR)에 대한 설명으로 옳지 않은 것은?",
  score: 15,
  choices: [
    "의심거래보고는 즉시 또는 지체없이 금융정보분석원(FIU)에 보고해야 한다",
    "의심거래보고 사실을 고객에게 통지해야 한다",
    "의심거래보고는 금융기관의 의무사항이다",
    "의심거래보고 대상은 자금세탁 의심거래와 테러자금조달 의심거래를 포함한다",
    "의심거래보고는 거래 금액에 관계없이 의심스러우면 보고해야 한다"
  ],
  correct_answer: "의심거래보고 사실을 고객에게 통지해야 한다",
  explanation: "의심거래보고 사실을 고객에게 통지하는 것은 금지되어 있습니다(티핑오프 금지). 이는 수사기관의 조사를 방해하고 증거인멸 등의 위험을 초래할 수 있기 때문입니다.",
  reference: "자금세탁방지법 제8조, 제9조",
  difficulty: "hard",
  category: "AML"
)

Quiz.create(
  question: "FATF(Financial Action Task Force)에 대한 설명으로 옳은 것은?",
  score: 5,
  choices: [
    "FATF는 UN의 하위기관이다",
    "FATF는 자금세탁방지 국제기준을 제정하는 정부간 기구이다",
    "FATF는 각국의 금융감독기관을 총괄하는 기관이다",
    "FATF는 국제은행연합회의 별칭이다",
    "FATF는 미국의 금융정보분석원이다"
  ],
  correct_answer: "FATF는 자금세탁방지 국제기준을 제정하는 정부간 기구이다",
  explanation: "FATF(Financial Action Task Force)는 1989년 G7 정상회의에서 설립된 정부간 기구로, 자금세탁방지 및 테러자금조달 방지를 위한 국제기준을 제정하고 각국의 이행상황을 평가하는 역할을 합니다.",
  reference: "FATF 40 권고사항",
  difficulty: "easy",
  category: "AML"
)

puts "샘플 퀴즈 데이터가 성공적으로 생성되었습니다."
```

## 5. 개발 서버 실행

### 5.1 통합 개발 서버 실행
```bash
bin/dev
```

이 명령어는 다음을 동시에 실행합니다:
- Rails 서버 (포트 3000)
- Tailwind CSS 컴파일러 (감시 모드)

### 5.2 개별 서버 실행
```bash
# 터미널 1: Rails 서버
bin/rails server

# 터미널 2: Tailwind CSS 컴파일러
bin/rails tailwindcss:watch
```

## 6. 개발 모드 사용

### 6.1 개발 모드 로그인
Firebase 인증 설정 전에 개발 모드로 앱을 테스트할 수 있습니다:

1. 브라우저에서 `http://localhost:3000` 접속
2. 로그인 페이지에서 "개발 모드 로그인" 버튼 클릭
3. 또는 URL에 `?dev_auth=true` 파라미터 추가

## 7. 트러블슈팅

### 7.1 Firebase 연결 오류
```
Error: Could not load the default credentials
```
**해결방법**: 
1. `config/firebase/service_account.json` 파일 존재 확인
2. `.env` 파일의 `FIREBASE_PROJECT_ID` 값 확인
3. Firebase 프로젝트 ID가 정확한지 확인

### 7.2 Tailwind CSS 스타일 적용 안됨
**해결방법**:
1. `bin/rails tailwindcss:build` 실행
2. `bin/rails tailwindcss:watch` 실행
3. 브라우저 캐시 삭제

### 7.3 Quiz 데이터 로드 오류
**해결방법**:
1. Firestore 보안 규칙 확인
2. Service Account 권한 확인
3. 네트워크 연결 상태 확인

## 8. 운영 환경 배포

### 8.1 환경 변수 설정
```bash
# 운영 환경에서는 환경 변수로 설정
export FIREBASE_PROJECT_ID=your-project-id
export FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
```

### 8.2 에셋 프리컴파일
```bash
RAILS_ENV=production bundle exec rails assets:precompile
```

### 8.3 Firestore 보안 규칙 (운영 환경)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 퀴즈 데이터는 읽기 전용
    match /quizzes/{document} {
      allow read: if true;
      allow write: if false;
    }
    
    // 퀴즈 세션은 해당 사용자만 접근 가능
    match /quiz_sessions/{document} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.user_id;
    }
  }
}
```

## 9. 추가 설정

### 9.1 관리자 기능 (선택사항)
관리자가 퀴즈 데이터를 직접 추가할 수 있는 간단한 인터페이스를 원한다면:

```ruby
# config/routes.rb에 추가
namespace :admin do
  resources :quizzes, only: [:index, :new, :create, :edit, :update, :destroy]
end
```

### 9.2 모니터링 설정
애플리케이션 성능 모니터링을 위해 다음 도구들을 고려:
- Firebase Performance Monitoring
- Google Analytics
- Rails 로깅 시스템 활용

이 가이드를 따라하면 AML Quiz App을 성공적으로 설정하고 실행할 수 있습니다.
# AML Quiz App - Claude Memory

## 🎯 프로젝트 개요
- **이름**: AML Quiz App (Anti-Money Laundering Quiz Application)
- **목적**: TPAC 시험 준비를 위한 모바일 퍼스트 퀴즈 애플리케이션
- **기술 스택**: Rails 8.0.2, CSS Custom Properties, Propshaft
- **GitHub**: https://github.com/princess-bom/aml-quiz-app

## 🏗️ 아키텍처 및 구조

### 디렉토리 구조
```
app/
├── assets/
│   └── stylesheets/
│       ├── application.css (메인 매니페스트)
│       └── design/
│           ├── tokens/ (디자인 토큰)
│           ├── components/ (18개 컴포넌트)
│           ├── responsive/ (반응형 시스템)
│           └── optimizations/ (성능 최적화)
├── controllers/
│   ├── home_controller.rb (대시보드)
│   ├── quiz_selection_controller.rb
│   ├── quizzes_controller.rb
│   ├── quiz_results_controller.rb
│   ├── wrong_answers_controller.rb
│   └── analytics_controller.rb
└── views/
    ├── layouts/application.html.erb (모바일 최적화 레이아웃)
    ├── home/index.html.erb (대시보드)
    ├── quiz_selection/index.html.erb
    ├── quizzes/ (show.html.erb, answer.html.erb)
    ├── quiz_results/show.html.erb
    ├── wrong_answers/index.html.erb
    └── analytics/index.html.erb
```

## 🎨 디자인 시스템

### CSS 컴포넌트 라이브러리 (18개)
1. **tokens/** - 디자인 토큰
   - colors.css (6과목 색상 시스템)
   - typography.css (폰트 스케일)
   - spacing.css (간격 시스템)

2. **components/** - UI 컴포넌트
   - navigation.css (모바일 네비게이션)
   - dashboard.css (대시보드 스타일)
   - button.css, card.css, badge.css
   - accordion.css, collapsible.css
   - alert.css, dialog.css
   - form.css, input.css, checkbox.css
   - 기타 12개 컴포넌트

3. **responsive/** - 반응형 시스템
   - breakpoints.css (320px-1536px)

4. **optimizations/** - 성능 최적화
   - performance.css (GPU 가속, contain 속성)

### 6과목 색상 시스템
- 자금세탁방지법: Blue (#3b82f6)
- 고객확인제도: Purple (#8b5cf6)
- 의심거래신고: Green (#10b981)
- 고객관리: Orange (#f59e0b)
- 내부통제: Red (#ef4444)
- 금융감독: Cyan (#06b6d4)

## 📱 뷰 템플릿 구조

### 1. 대시보드 (home/index.html.erb)
- 사용자 환영 메시지
- 학습 통계 (총 세션, 평균 점수)
- 연속 학습 달성 알림
- 전체 진도율 표시
- 최근 활동 리스트
- 과목별 진도 카드

### 2. 퀴즈 선택 (quiz_selection/index.html.erb)
- 추천 퀴즈 섹션
- 6과목 네비게이션 카드
- 과목별 모달 (기초/응용/심화 레벨)
- 검색 및 필터 기능

### 3. 퀴즈 실행 (quizzes/show.html.erb)
- 진행률 바 및 네비게이션
- 20문제 객관식 (A-E 선택)
- 북마크 및 타이머 기능
- 인터랙티브 답안 선택

### 4. 답안 확인 (quizzes/answer.html.erb)
- 정답/오답 알림
- 상세 해설 및 법조문 참조
- 북마크 및 메모 기능
- 다음 문제/결과 보기 버튼

### 5. 퀴즈 결과 (quiz_results/show.html.erb)
- 최종 점수 및 등급 표시
- 상세 통계 (정답/오답/소요시간)
- 문제별 결과 검토 (접을 수 있는)
- 개선 제안 알림
- 액션 버튼 (다시풀기, 다른퀴즈, 홈)

### 6. 오답노트 (wrong_answers/index.html.erb)
- 오답 통계 및 복습 현황
- 필터링 (과목별, 상태별)
- 오답 문제 리스트 (해설 포함)
- 북마크 및 복습 완료 기능

### 7. 학습 분석 (analytics/index.html.erb)
- 전체 성과 통계
- 과목별 성과 차트
- 주간 학습 현황 그래프
- 강점/약점 분석
- 맞춤 학습 제안
- 목표 달성률

## 🚀 핵심 기능

### 모바일 네비게이션
- 4개 탭: 홈/퀴즈/오답노트/분석
- 햅틱 피드백 지원
- 배지 알림 (오답 개수, 활성 세션)
- 부드러운 애니메이션

### 퀴즈 시스템
- 6과목 × 3레벨 × 3난이도 = 54개 퀴즈
- 20문제 객관식 형태
- 실시간 진행률 추적
- 북마크 및 메모 기능

### 성능 최적화
- GPU 하드웨어 가속
- CSS contain 속성 활용
- Progressive Enhancement
- 60fps 부드러운 애니메이션

## ⚙️ 설정 및 라우팅

### 주요 라우트
```ruby
root "home#index"
get "dashboard" => "home#index"
get "quiz_selection" => "quiz_selection#index"
get "wrong_answers" => "wrong_answers#index"
get "analytics" => "analytics#index"
resources :quizzes, :quiz_results, :wrong_answers
```

### 에셋 설정
- Propshaft 에셋 파이프라인
- .propshaftignore로 개별 CSS 파일 제외
- 프로덕션 최적화 설정

## 📊 프로젝트 성과

### 코드 통계
- **총 파일**: 37개 추가/수정
- **코드 라인**: 12,521 라인 추가
- **CSS 컴포넌트**: 18개
- **뷰 템플릿**: 7개 완성
- **디자인 시스템**: 430% 확장 (1,980 → 8,505 라인)

### 기술적 달성
- ✅ 완전한 모바일 퍼스트 반응형 디자인
- ✅ PWA 지원 메타태그
- ✅ 접근성 지원 (고대비, 모션 감소, 다크모드)
- ✅ 성능 최적화 및 GPU 가속
- ✅ 완전한 라우팅 시스템

## 🔥 Firebase 백엔드 시스템

### Firebase 설정
- **프로젝트**: tpac-8c41e
- **데이터베이스**: https://tpac-8c41e-default-rtdb.firebaseio.com/
- **업로드된 데이터**: 448개 문제 + 해설

### 과목 구성 (PRD 기준)
1. **자금세탁방지 글로벌 기준** - 140문제 ✅
2. **국내 자금세탁방지 제도** - 128문제 ✅  
3. **고객확인의무** - 140문제 ✅
4. **고액현금거래·의심거래보고** - 40문제 ✅
5. **위험평가** - 미준비 ⏳
6. **자금세탁방지 실무** - 미준비 ⏳

### Firebase 명령어
```bash
# 텍스트 파일 업로드
bundle exec rails firebase:upload_text_files

# Firebase 데이터 초기화 후 업로드  
bundle exec rails firebase:clear_and_upload_text

# 단일 파일 테스트
bundle exec rails firebase:test_single_upload
```

## 🔧 개발 및 배포

### 개발 환경
```bash
bin/rails server  # 개발 서버 실행
curl http://localhost:3000  # 상태 확인
```

### Git 정보
- **리포지토리**: https://github.com/princess-bom/aml-quiz-app
- **최신 커밋**: adaac86 (백엔드 완성)
- **브랜치**: main

### 사용 명령어
```bash
# 서버 실행
bin/rails server

# Firebase 퀴즈 선택 테스트
curl http://localhost:3000/firebase_quiz_selection

# 라우트 확인
bundle exec rails routes | grep firebase
```

## 💡 향후 개선사항
1. ✅ Firebase 백엔드 연동 완료
2. ✅ 퀴즈 데이터 업로드 완료 (448문제)
3. ✅ 프론트엔드-Firebase 연동 완료
4. 🔄 과목 5,6 문제 추가 (준비 중)
5. 🔄 PWA 설치 및 오프라인 지원
6. 🔄 사용자 인증 시스템 완성
7. 🔄 실제 테스트 및 버그 수정

## 📝 중요 참고사항
- **데이터 소스**: `/Users/cooljean/Desktop/AML/aml_quiz_app/quiz/` 폴더의 텍스트 파일
- **Firebase 구조**: questions/{id}, explanations/{question_id}
- **과목 매핑**: 폴더명 기준으로 자동 분류
- **난이도**: 상(high), 중상(medium_high), 최상(highest)
- **타입**: A, B, C 타입별 분리

## 🎉 완료된 작업 (2025-07-19)

### Firebase 통합 완료
1. **Firebase 뷰 템플릿 생성**
   - firebase_quiz_selection/index.html.erb
   - firebase_quiz_selection/show_subject.html.erb
   - firebase_quizzes/show.html.erb
   - firebase_quizzes/result.html.erb

2. **Stimulus 컨트롤러 추가**
   - quiz_answer_controller.js (AJAX 답안 제출)

3. **라우트 통합**
   - Legacy 라우트 제거
   - Firebase 컨트롤러를 메인으로 사용
   - 리다이렉트 설정

4. **i18n 설정**
   - config/locales/quiz.ko.yml 추가
   - 과목명과 난이도 매핑 통일

### 현재 작동 흐름
1. 홈 → 퀴즈 선택 → 과목 선택 → 난이도 선택
2. 퀴즈 시작 → 20문제 진행 (AJAX 답안 제출)
3. 실시간 정답 확인 및 해설 표시
4. 결과 페이지에서 상세 리뷰

---
**마지막 업데이트**: 2025-07-19 (Firebase 프론트엔드 연동 완료)
**총 개발 기간**: 집중 개발 세션
**상태**: 프론트엔드-백엔드 통합 완료, 테스트 필요
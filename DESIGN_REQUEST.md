# AML Quiz App - Figma Design Request

## 🎯 Project Overview

**AML Quiz App - TPAC 시험 대비 퀴즈 학습 도구**

- **Purpose**: 한국의 자금세탁방지(AML) 시험 준비를 위한 모바일 최적화 퀴즈 앱
- **Target Users**: 금융업계 종사자 및 TPAC 시험 응시자
- **Platform**: 웹 기반 (모바일 우선, 반응형)
- **Tech Stack**: Rails 8, Tailwind CSS, Firebase
- **Repository**: [GitHub - aml-quiz-app](https://github.com/princess-bom/aml-quiz-app)

### Quiz Structure
- **총 6과목**: 각 과목별 전문 영역 구분
- **유형별 구분**: 각 과목마다 3가지 문제 유형
- **난이도 구분**: 각 유형마다 3가지 난이도 (초급, 중급, 고급)
- **문항 수**: 각 퀴즈당 20문항
- **총 퀴즈 수**: 6과목 × 3유형 × 3난이도 = 54개 퀴즈

## 📱 Design Requirements

### 1. Overall Design Direction

- **Color Theme**: 신뢰감 있는 블루 계열
  - Primary: `#3B82F6` (Blue-500)
  - Secondary: `#1E40AF` (Blue-700)
  - Success: `#10B981` (Green-500)
  - Error: `#EF4444` (Red-500)
  - Warning: `#F59E0B` (Yellow-500)
  - Neutral: `#6B7280` (Gray-500)

- **Style**: 모던, 클린, 전문적
- **Typography**: 한글 가독성 우수한 폰트 (Noto Sans KR 또는 유사)
- **Layout**: 모바일 우선 반응형 디자인

### 2. Required Screens (Priority Order)

#### 🔥 Essential Screens

##### 1. Login Screen (`/login`)
- Firebase 인증 UI 통합
- 개발 모드 간편 로그인 옵션
- 앱 로고 및 타이틀 "AML Quiz App"
- 서브 타이틀 "TPAC 시험 대비 퀴즈 학습 도구"
- 깔끔하고 전문적인 로그인 폼

##### 2. Home Dashboard (`/`)
- 사용자 환영 메시지
- 진행 중인 퀴즈 세션 카드 (있는 경우)
- "퀴즈 선택하기" 버튼 (Primary CTA)
- 학습 현황 통계 섹션:
  - 총 세션 수
  - 평균 점수
  - 최고 점수
  - 과목별 진도율
- 퀴즈 정보 박스:
  - 6과목 × 3유형 × 3난이도 = 54개 퀴즈
  - 각 퀴즈당 20문항
  - 5지선다 객관식
- 빠른 접근 섹션:
  - 최근 학습한 과목
  - 취약한 영역 (오답률 높은 과목/유형)
  - 오답 노트 바로가기

##### 3. Quiz Selection Screen (`/quizzes/select`)
- 과목 선택 섹션 (6개 과목 카드)
- 각 과목 카드에 포함될 정보:
  - 과목명
  - 전체 진도율
  - 평균 점수
  - 최근 학습일
- 유형 및 난이도 선택 모달/페이지:
  - 3×3 그리드 (3유형 × 3난이도)
  - 각 셀에 완료 상태 표시
  - 추천 퀴즈 하이라이트
- 필터링 옵션:
  - 미완료 퀴즈만 보기
  - 취약한 영역 우선 보기
  - 최근 학습 순서

##### 4. Quiz Screen (`/quizzes/:id`)
- 상단 진행률 바 (Progress Bar)
- 현재 과목/유형/난이도 표시
- 문제 번호 및 배점 표시
- 문제 텍스트 (명확하고 읽기 쉬운 폰트)
- 객관식 선택지 (5개, 라디오 버튼 스타일)
- "답안 제출" 버튼 (비활성화 → 활성화 상태)
- 하단 안내 정보 (남은 문제 수, 제한 시간 없음 등)
- 북마크 기능 (어려운 문제 표시)

##### 5. Answer Result Screen (`/quizzes/:id/answer`)
- 정답/오답 결과 표시 (시각적 피드백)
- 선택한 답안 vs 정답 비교
- 해설 및 참고 자료 섹션
- 오답 노트 추가 버튼 (오답인 경우)
- "다음 문제" 버튼 또는 "결과 보기" 버튼

##### 6. Quiz Results Screen (`/quiz_results/:id`)
- 최종 점수 및 정답률 (큰 숫자로 강조)
- 과목/유형/난이도별 성과 분석
- 문제별 답안 검토 리스트
- 취약 영역 분석 (오답률 높은 유형)
- 액션 버튼:
  - "오답 노트 보기"
  - "관련 퀴즈 다시 풀기"
  - "다른 퀴즈 선택"
  - "홈으로 돌아가기"

#### 📚 Additional Screens (오답 노트 & 분석)

##### 7. Wrong Answer Note (`/wrong_answers`)
- 오답 노트 메인 화면
- 과목별 오답 통계 카드
- 최근 추가된 오답 문제 리스트
- 필터링 옵션:
  - 과목별 필터
  - 유형별 필터
  - 난이도별 필터
  - 날짜별 필터
- 검색 기능 (키워드 검색)
- 오답 문제 즐겨찾기 기능

##### 8. Wrong Answer Detail (`/wrong_answers/:id`)
- 오답 문제 상세 보기
- 원본 문제 및 선택지
- 사용자가 선택한 답안 (오답) 하이라이트
- 정답 및 해설
- 오답 노트 (사용자 메모)
- 관련 문제 추천
- 액션 버튼:
  - "다시 풀어보기"
  - "메모 수정"
  - "즐겨찾기 추가/제거"

##### 9. Learning Analytics (`/analytics`)
- 종합 학습 분석 대시보드
- 과목별 성과 분석:
  - 정답률 차트
  - 학습 시간 통계
  - 진도율 현황
- 유형별 취약점 분석:
  - 히트맵 형태의 시각화
  - 오답률 높은 유형 Top 5
- 학습 패턴 분석:
  - 시간대별 학습 효율
  - 주간/월간 학습 트렌드
- 개선 제안:
  - 추천 학습 경로
  - 집중 학습 영역

##### 10. Subject Analytics (`/analytics/subjects/:id`)
- 특정 과목 상세 분석
- 유형별 성과 비교 차트
- 난이도별 정답률 분석
- 시간 경과에 따른 개선도 추적
- 자주 틀리는 문제 패턴 분석
- 해당 과목 오답 노트 바로가기

### 3. UI Components

#### 📋 Component Library
- **Progress Bar**: 진행률 표시
- **Card Components**: 그림자 효과가 있는 카드
- **Buttons**: 
  - Primary (Blue)
  - Secondary (Gray)
  - Success (Green)
  - Danger (Red)
- **Badges**: 정답/오답 상태 표시
- **Statistics Cards**: 숫자 강조 카드
- **Radio Buttons**: 커스텀 스타일링
- **Icons**: 학습, 시계, 차트, 체크마크 등
- **Subject Cards**: 과목 선택 카드
- **Quiz Selection Grid**: 3×3 유형/난이도 선택 그리드
- **Analytics Charts**: 
  - 도넛 차트 (정답률)
  - 바 차트 (과목별 성과)
  - 히트맵 (취약점 분석)
  - 라인 차트 (학습 트렌드)
- **Filter Components**: 
  - 드롭다운 필터
  - 태그 형태 필터
  - 검색 바
- **Wrong Answer Cards**: 오답 노트 카드
- **Bookmark Button**: 즐겨찾기 토글 버튼
- **Difficulty Indicators**: 난이도 표시 (색상 코딩)
- **Subject Progress Ring**: 과목별 진도율 원형 표시

#### 🎨 Color Usage Guide
```css
/* Primary Colors */
--primary-blue: #3B82F6;
--primary-blue-dark: #1E40AF;

/* Status Colors */
--success-green: #10B981;
--error-red: #EF4444;
--warning-yellow: #F59E0B;

/* Difficulty Colors */
--difficulty-easy: #10B981;    /* Green - 중급 */
--difficulty-medium: #F59E0B;  /* Yellow - 상급 */
--difficulty-hard: #EF4444;    /* Red - 최상급 */

/* Subject Colors (6가지 과목 구분) */
--subject-1: #3B82F6;  /* Blue */
--subject-2: #8B5CF6;  /* Purple */
--subject-3: #10B981;  /* Green */
--subject-4: #F59E0B;  /* Orange */
--subject-5: #EF4444;  /* Red */
--subject-6: #6366F1;  /* Indigo */

/* Analytics Colors */
--chart-primary: #3B82F6;
--chart-secondary: #8B5CF6;
--chart-success: #10B981;
--chart-warning: #F59E0B;
--chart-error: #EF4444;

/* Neutral Colors */
--gray-100: #F3F4F6;
--gray-500: #6B7280;
--gray-900: #111827;
```

### 4. Mobile Optimization Requirements

- **Screen Sizes**: 320px ~ 768px 모바일 화면 대응
- **Touch Targets**: 최소 44px 크기 버튼
- **Interface**: 스크롤 최소화된 인터페이스
- **Performance**: 빠른 로딩을 위한 경량 디자인
- **Gestures**: 터치 친화적 인터랙션

### 5. User Experience (UX) Considerations

- **Navigation**: 직관적인 네비게이션 플로우
- **Feedback**: 명확한 피드백 (정답/오답 즉시 확인)
- **Motivation**: 학습 동기 부여 (진행률, 점수, 성취감)
- **Accessibility**: 
  - 색상 대비 준수 (WCAG 2.1 AA)
  - 적절한 폰트 크기 (최소 16px)
  - 키보드 네비게이션 고려

### 6. Current Implementation Reference

현재 구현된 기능을 바탕으로 디자인해주세요:

- **Authentication**: Firebase Auth 연동
- **Quiz Management**: 세션 기반 퀴즈 관리
- **Score Tracking**: 실시간 점수 및 통계
- **Responsive Design**: Tailwind CSS 기반

## 🛠️ Technical Specifications

### Framework Integration
- **CSS Framework**: Tailwind CSS 호환
- **JavaScript**: Stimulus 컨트롤러 고려
- **Icons**: Inline SVG 사용
- **Fonts**: 웹 폰트 최적화

### Browser Support
- **Mobile**: iOS Safari, Android Chrome
- **Desktop**: Chrome, Firefox, Safari, Edge
- **PWA**: Progressive Web App 고려

## 📋 Deliverables

### 1. Wireframes
- [ ] 10개 주요 화면 와이어프레임 (로그인, 대시보드, 퀴즈 선택, 퀴즈, 정답 확인, 결과, 오답 노트, 오답 상세, 분석, 과목별 분석)
- [ ] 사용자 플로우 다이어그램
- [ ] 정보 구조 (Information Architecture)
- [ ] 퀴즈 선택 플로우 (과목 → 유형 → 난이도)
- [ ] 오답 노트 관리 플로우

### 2. Visual Design
- [ ] 고해상도 모바일 디자인 (375px × 812px 기준)
- [ ] 데스크톱 반응형 버전 (1200px 기준)
- [ ] 태블릿 버전 (768px 기준)
- [ ] 다크 모드 고려 (선택사항)

### 3. Component System
- [ ] 기본 컴포넌트 라이브러리 (Buttons, Cards, Icons)
- [ ] 퀴즈 전용 컴포넌트 (Subject Cards, Quiz Grid, Analytics Charts)
- [ ] 오답 노트 컴포넌트 (Wrong Answer Cards, Bookmark Button)
- [ ] 색상 팔레트 및 타이포그래피 가이드
- [ ] 스타일 가이드 문서

### 4. Interactive Prototype
- [ ] 전체 사용자 플로우 연결된 프로토타입
- [ ] 퀴즈 선택 인터랙션 (3×3 그리드 선택)
- [ ] 오답 노트 관리 인터랙션
- [ ] 분석 차트 인터랙션
- [ ] 마이크로 인터랙션 (hover, focus, active states)
- [ ] 트랜지션 및 애니메이션 가이드

### 5. Assets & Specifications
- [ ] 이미지 에셋 (PNG, SVG)
- [ ] 아이콘 세트 (과목별, 유형별, 기능별)
- [ ] 차트 및 그래프 에셋
- [ ] 개발자 핸드오프 사양서
- [ ] Figma 파일 (개발팀 접근 권한 포함)

## 💡 Additional Notes

### Cultural Context
- **Language**: 한국어 텍스트 및 문화적 맥락 고려
- **Tone**: 시험 준비 앱의 진지하고 전문적인 분위기 유지
- **Motivation**: 사용자의 학습 성과를 시각적으로 표현

### Business Requirements
- **Branding**: 신뢰할 수 있는 금융 교육 플랫폼 이미지
- **Scalability**: 향후 기능 확장 가능한 디자인 시스템
- **Maintenance**: 유지보수 용이한 컴포넌트 구조

### Success Metrics
- **User Engagement**: 퀴즈 완료율 및 학습 세션 지속 시간 증가
- **Learning Effectiveness**: 
  - 사용자 점수 향상 (재시도 시 정답률 증가)
  - 오답 노트 활용도 (오답 문제 재학습 후 정답률)
- **User Satisfaction**: 직관적이고 사용하기 쉬운 인터페이스
- **Analytics Usage**: 
  - 분석 화면 방문율
  - 취약점 분석 기반 학습 개선
- **Feature Adoption**: 
  - 오답 노트 사용률
  - 과목별 선택 학습 활용도

---

## 📞 Contact & Questions

프로젝트 관련 질문이나 추가 정보가 필요하시면 언제든지 연락주세요.

**Project Repository**: https://github.com/princess-bom/aml-quiz-app
**Design System**: Tailwind CSS 기반
**Target Launch**: 2024년 내 베타 버전 출시 예정

---

*이 문서는 AML Quiz App의 디자인 요구사항을 담고 있으며, 피그마 디자이너와의 협업을 위한 가이드라인입니다.*
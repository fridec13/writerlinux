# UI/UX 설계 및 개선 계획

WriterOS는 글쓰기에 최적화된 사용자 경험을 제공해야 합니다.

## 현재 상황 분석

### qutebrowser 장단점 분석

**장점:**
- 키보드 중심 워크플로우 (글쓰기 집중도 향상)
- 경량성 (배터리 절약)
- 방해 요소 없는 미니멀 UI
- 빠른 실행 속도

**단점:**
- 일반 사용자에게는 진입 장벽이 높음
- 시각적 피드백 부족
- 복잡한 웹 사이트 사용 시 불편
- 한글 입력 시 UI 깨짐 가능성

## UI/UX 개선 방향

### 1. 글쓰기 집중 최우선

#### 기본 UI에서 제외할 요소들
- **웹브라우저**: 기본 UI에서 완전히 숨김
- **게임**: 설치하지 않음
- **소셜 미디어**: 접근 불가
- **동영상 플레이어**: 최소한으로만 제공
- **알림**: 글쓰기 중 모든 알림 차단

#### 집중 모드 강화
```bash
# 집중 모드 활성화
writer-focus-mode() {
    # 네트워크 차단 (클라우드 동기화만 허용)
    sudo iptables -A OUTPUT -p tcp --dport 80 -j DROP
    sudo iptables -A OUTPUT -p tcp --dport 443 -j DROP
    
    # 알림 차단
    systemctl --user stop notification-daemon
    
    # 시간 숨기기 (시간 확인으로 인한 집중력 저하 방지)
    sway-msg "bar hidden_bar toggle"
}
```

### 2. 브라우저 접근 제한

#### 터미널 전용 접근
```bash
# 웹브라우저 실행 시 경고 메시지
qutebrowser() {
    echo "⚠️  글쓰기 집중을 위해 웹브라우징은 권장하지 않습니다."
    echo "정말 계속하시겠습니까? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        /usr/bin/qutebrowser "$@"
    else
        echo "글쓰기로 돌아갑니다."
    fi
}
```

#### 시간 제한 기능
```bash
# 웹브라우저 사용 시간 제한 (30분)
browser-with-timer() {
    timeout 1800 qutebrowser "$@"
    echo "웹브라우징 시간이 종료되었습니다. 글쓰기로 돌아가세요."
}
```

### 3. 대체 자료 검색 방법

#### AI 기반 정보 검색
```bash
# 터미널에서 직접 정보 검색
ask-ai() {
    echo "질문: $1"
    curl -s "https://api.openai.com/v1/chat/completions" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $OPENAI_API_KEY" \
         -d "{
             \"model\": \"gpt-4\",
             \"messages\": [{\"role\": \"user\", \"content\": \"$1\"}],
             \"max_tokens\": 500
         }" | jq -r '.choices[0].message.content'
}
```

#### 오프라인 참고 자료
```bash
# 로컬 위키피디아 다운로드
kiwix-serve wikipedia_ko.zim

# 로컬 사전
dict-lookup() {
    echo "$1" | aspell -a -l ko
}

# 로컬 백과사전
info-search() {
    grep -r "$1" /usr/share/info/
}
```

#### 명령어 기반 간단 검색
```bash
# 간단한 사실 확인
fact-check() {
    echo "사실 확인: $1"
    # 로컬 AI 모델을 통한 팩트 체크
    ollama run llama3 "다음 내용의 사실성을 확인해주세요: $1"
}
```

### 4. 사용자 경험 개선

#### 글쓰기 특화 UI 요소
```css
/* 글쓰기 집중 모드 CSS */
.writer-mode {
    /* 배경: 종이 질감 */
    background: #fefef8;
    background-image: url('paper-texture.png');
    
    /* 텍스트: 높은 대비 */
    color: #2c3e50;
    font-family: "Noto Sans CJK KR", sans-serif;
    
    /* 여백: 책과 같은 느낌 */
    max-width: 800px;
    margin: 0 auto;
    padding: 60px 80px;
    
    /* 줄 간격: 가독성 최적화 */
    line-height: 1.8;
    font-size: 16px;
}
```

#### 한글 타이핑 최적화
```javascript
// 한글 입력 시 UI 반응성 개선
document.addEventListener('compositionstart', function() {
    document.body.classList.add('composing-korean');
});

document.addEventListener('compositionend', function() {
    document.body.classList.remove('composing-korean');
});
```

## 4. 통합 사용자 인터페이스 설계

### 메인 대시보드 (글쓰기 집중 모드)
```
┌─────────────────────────────────────────────────────┐
│ WriterOS - 글쓰기 집중 모드    [배터리: 87%] [🔥]   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📝 새 글 쓰기                                       │
│  📚 최근 문서                                       │
│  🤖 AI 어시스턴트                                    │
│  📖 오프라인 자료                                    │
│  💾 클라우드 동기화                                  │
│  ⚙️  설정                                           │
│                                                     │
│  ───────────────────────────────────────────────    │
│                                                     │
│  오늘 작성: 1,247자 (목표: 2,000자)                 │
│  이번 주: 8,392자                                   │
│  연속 작성일: 5일 🔥                                │
│                                                     │
│  💡 집중 모드 활성화 중 - 웹브라우징 차단            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 글쓰기 인터페이스
```
┌─────────────────────────────────────────────────────┐
│ [파일명: 소설_1장.md]        [글자수: 1,247/10,000] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  # 첫 번째 장                                       │
│                                                     │
│  ┌─ 문단 1 ─────────────────────────────────────┐   │
│  │ 새벽 공기는 차갑고 깨끗했다. 주인공은...    │   │
│  │                                           │   │
│  └───────────────────────────────────────────┘   │
│                                                     │
│  ┌─ AI 제안 ─────────────────────────────────────┐  │
│  │ 💡 "분위기 묘사를 더 구체적으로 해보세요"    │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 5. 접근성 및 사용성

### 키보드 단축키 개선
```bash
# 글쓰기 특화 단축키
Super+N      # 새 문서
Super+O      # 문서 열기
Super+S      # 저장
Super+F      # 검색
Super+R      # 자료 검색 (웹)
Super+T      # AI 어시스턴트 토글
Super+W      # 단어 수 표시
Super+Space  # 집중 모드 토글
```

### 시각적 피드백 개선
```css
/* 상태 표시 */
.status-bar {
    background: rgba(0,0,0,0.05);
    border-top: 1px solid #e1e8ed;
    padding: 8px 16px;
    font-size: 14px;
    color: #657786;
}

/* 진행률 표시 */
.progress-indicator {
    width: 100%;
    height: 4px;
    background: #e1e8ed;
    border-radius: 2px;
}

.progress-bar {
    height: 100%;
    background: linear-gradient(to right, #1da1f2, #17bf63);
    border-radius: 2px;
    transition: width 0.3s ease;
}
```

## 6. 다크 모드 지원

### 글쓰기 친화적 다크 테마
```css
/* 다크 모드 - 눈의 피로 최소화 */
.dark-mode {
    background: #1a1a1a;
    color: #e1e8ed;
    
    /* 따뜻한 색온도 */
    filter: sepia(10%) hue-rotate(15deg);
}

.dark-mode .editor {
    background: #2d3748;
    color: #e2e8f0;
    border: 1px solid #4a5568;
}
```

### 자동 다크 모드 전환
```bash
# 시간에 따른 테마 전환
if [ $(date +%H) -ge 18 -o $(date +%H) -lt 6 ]; then
    export THEME="dark"
else
    export THEME="light"
fi
```

## 7. 반응형 디자인

### 다양한 화면 크기 지원
```css
/* 데스크톱 */
@media (min-width: 1024px) {
    .container {
        max-width: 1200px;
        margin: 0 auto;
    }
}

/* 태블릿 */
@media (max-width: 1023px) {
    .container {
        padding: 20px;
    }
}

/* 모바일 */
@media (max-width: 767px) {
    .container {
        padding: 10px;
    }
}
```

## 8. 성능 최적화

### 렌더링 최적화
```javascript
// 가상 스크롤링으로 긴 문서 최적화
const VirtualScroll = {
    init() {
        this.visibleStart = 0;
        this.visibleEnd = 50;
        this.itemHeight = 24;
    },
    
    updateVisibleItems() {
        const scrollTop = window.scrollY;
        const viewportHeight = window.innerHeight;
        
        this.visibleStart = Math.floor(scrollTop / this.itemHeight);
        this.visibleEnd = Math.min(
            this.visibleStart + Math.ceil(viewportHeight / this.itemHeight) + 5,
            this.totalItems
        );
    }
};
```

## 9. 사용자 테스트 계획

### A/B 테스트 항목
- qutebrowser vs Firefox 선호도
- 미니멀 UI vs 풍부한 UI
- 키보드 vs 마우스 사용 패턴
- 다크 모드 vs 라이트 모드 사용률

### 메트릭 수집
```bash
# 사용자 행동 로그
echo "$(date): 글쓰기 시작" >> ~/.writeros/usage.log
echo "$(date): 브라우저 열기" >> ~/.writeros/usage.log
echo "$(date): AI 도움 요청" >> ~/.writeros/usage.log
```

## 10. 최종 권장사항

### 단계적 접근
1. **1단계**: 글쓰기 집중 환경 구축 (웹브라우저 숨김)
2. **2단계**: 한글 지원 완성
3. **3단계**: AI 기반 대체 자료 검색
4. **4단계**: 오프라인 참고 자료 구축
5. **5단계**: 웹브라우저 접근 제한 및 경고 시스템

### 구현 우선순위
1. **글쓰기 집중 모드** (최우선)
2. **한글 입력 완벽 지원**
3. **AI 어시스턴트 통합**
4. **오프라인 자료 시스템**
5. **웹브라우저 접근 제한**
6. **시각적 피드백 개선**
7. **다크 모드 지원**

### 철학
- **"글쓰기만 하는 OS"**: 다른 모든 것은 방해 요소
- **"오프라인 우선"**: 인터넷 연결 없이도 완전한 기능
- **"AI 협업"**: 웹검색 대신 AI가 정보 제공
- **"단순함"**: 복잡한 기능은 숨기고, 글쓰기만 부각 
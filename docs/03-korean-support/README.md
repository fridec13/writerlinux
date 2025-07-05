# 한글 지원 계획

WriterOS는 한국어 글쓰기에 최적화된 OS로서, 완벽한 한글 지원이 필수입니다.

## 목표

- **완벽한 한글 입력**: 빠르고 정확한 한글 입력 환경
- **아름다운 타이포그래피**: 가독성 높은 한글 글꼴과 조판
- **지능형 교정**: AI 기반 한글 맞춤법 및 문법 검사
- **다양한 포맷 지원**: 한글 문서의 다양한 형태 처리

## 1. 한글 입력 시스템

### 입력기 선택: fcitx5
```bash
# 핵심 패키지
fcitx5
fcitx5-hangul
fcitx5-configtool
fcitx5-qt
fcitx5-gtk
```

**선택 이유:**
- 빠른 입력 속도와 낮은 지연시간
- 한자 변환 지원
- 다양한 한글 입력 방식 지원 (두벌식, 세벌식)
- Wayland 완벽 지원

### 한글 입력 설정
```bash
# 환경 변수 설정
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
```

### 지원 입력 방식
- **두벌식**: 표준 한글 입력
- **세벌식**: 고급 사용자용 효율적 입력
- **로마자 변환**: 영어 키보드 사용자 지원

## 2. 한글 폰트 시스템

### 기본 폰트 패키지
```bash
# 시스템 폰트
noto-fonts-cjk
noto-fonts-emoji

# 추가 한글 폰트
ttf-baekmuk
ttf-nanum
ttf-nanum-coding
ttf-d2coding
```

### 폰트 우선순위 설정
```xml
<!-- /etc/fonts/conf.d/65-korean.conf -->
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif CJK KR</family>
      <family>Noto Serif</family>
    </prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans CJK KR</family>
      <family>Noto Sans</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>D2Coding</family>
      <family>Noto Sans Mono CJK KR</family>
    </prefer>
  </alias>
</fontconfig>
```

### 글쓰기 전용 폰트
- **본문용**: Noto Sans CJK KR (가독성 우수)
- **제목용**: 본고딕 (임팩트 있는 제목)
- **코드용**: D2Coding (프로그래밍 글쓰기)
- **손글씨**: 나눔손글씨 (개성 있는 글쓰기)

## 3. 한글 맞춤법 검사

### hunspell-ko 설치 및 설정
```bash
# 맞춤법 검사 패키지
pacman -S hunspell-ko

# 에디터별 통합
# Neovim: vim-grammarous 플러그인
# Zed: 내장 맞춤법 검사 활용
```

### 맞춤법 검사 기능
- **실시간 검사**: 타이핑 중 즉시 오류 표시
- **문맥 기반 교정**: AI를 활용한 문맥 맞춤법 검사
- **사용자 사전**: 개인 단어 추가 및 관리

## 4. 한글 타이포그래피

### 조판 최적화
```css
/* 한글 최적화 CSS */
.korean-text {
    font-family: "Noto Sans CJK KR", sans-serif;
    line-height: 1.6;
    letter-spacing: -0.02em;
    word-break: keep-all;
    overflow-wrap: break-word;
}

.korean-paragraph {
    text-align: justify;
    text-justify: inter-ideograph;
}
```

### 한글 조판 규칙
- **줄 간격**: 1.5-1.8 권장
- **자간**: 한글 특성에 맞는 미세 조정
- **문단 정렬**: 양쪽 정렬 + 한글 특화 알고리즘
- **금칙어 처리**: 행 시작/끝 금칙어 자동 처리

## 5. 한글 문서 포맷 지원

### Pandoc 한글 확장
```bash
# 한글 문서 변환 예시
pandoc -f markdown -t docx \
  --reference-doc=korean-template.docx \
  --lua-filter=korean-typography.lua \
  input.md -o output.docx
```

### 지원 포맷
- **입력**: Markdown (한글 확장), 한글 (HWP), MS Word
- **출력**: PDF (한글 최적화), ePub, HTML, 한글 (HWP)
- **웹**: 한글 웹 폰트 최적화

## 6. AI 기반 한글 지원

### 한글 언어 모델 통합
```python
# 한국어 특화 AI 모델
models = {
    "grammar": "klue/bert-base-korean",
    "generation": "kakaobrain/kogpt",
    "translation": "facebook/mbart-large-50-many-to-many-mmt"
}
```

### AI 지원 기능
- **문법 검사**: 한국어 문법 오류 자동 감지
- **문체 교정**: 높임말, 경어, 문체 일관성 검사
- **번역**: 영한/한영 번역 지원
- **요약**: 긴 글의 핵심 내용 요약

## 7. 개발 우선순위

### 1단계: 기본 한글 지원
- [ ] fcitx5 설치 및 설정
- [ ] 기본 한글 폰트 설치
- [ ] 한글 입력 테스트

### 2단계: 고급 기능
- [ ] 맞춤법 검사 통합
- [ ] 타이포그래피 최적화
- [ ] 다양한 입력 방식 지원

### 3단계: AI 통합
- [ ] 한국어 AI 모델 통합
- [ ] 실시간 문법 검사
- [ ] 문체 교정 기능

## 8. 테스트 계획

### 한글 입력 테스트
```bash
# 기본 입력 테스트
echo "안녕하세요. 한글 입력 테스트입니다."

# 복합 자모 테스트
echo "ㅄ ㅆ ㅀ ㅃ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ"

# 특수 문자 테스트
echo "「한글」 『인용부호』 ・ 가운데점"
```

### 성능 테스트
- 입력 지연시간: < 10ms
- 메모리 사용량: < 50MB
- 맞춤법 검사 속도: < 1초/1000자

## 9. 추가 고려사항

### 접근성
- 시각 장애인을 위한 한글 TTS 지원
- 색맹 사용자를 위한 UI 대비 조정
- 키보드 전용 사용자 지원

### 국제화
- 다국어 환경에서 한글 우선순위 설정
- 한영 전환 최적화
- 외국어 혼용 문서 지원

### 호환성
- 기존 한글 문서 형식 지원
- Windows/Mac 폰트 렌더링 호환
- 웹 기반 한글 입력 지원 
프리라이트 트래블러나 writerDeck 등의 것을 찾다가 어떤 것이 좋은가.
dm250 dm200 등의 포메라는 리눅스 기반이긴 하나 한글이 외부 키보드를 끼워야만 동작하고,

vaio p 시리즈 같이 풀사이즈 키보드에 화면만 달린 제품은 없음.

노트북 자체를 라이트덱에 목적에 맞게 바꿀 수 있는 os가 있다면 좋을 것 같다는 생각이 들어 ai를 써서 개발을 해보고 싶어짐.

아이디어만 일단 적어놓음.

---

# WriterOS 개발 프로젝트

글쓰기에만 집중할 수 있는 커스텀 리눅스 배포판 개발 프로젝트입니다.

## 목표

- **퀵리줌 지원**: 빠른 suspend/resume으로 즉시 작업 재개
- **극한 절전**: 배터리 수명 최대화
- **글쓰기 특화**: 방해 요소 없는 글쓰기 환경
- **AI 통합**: 로컬 AI 및 API를 통한 글쓰기 지원
- **멀티 아키텍처**: AMD64 + ARM64 지원

## 타겟 하드웨어

- **🎮 ASUS 제피로스 G14 (2021)**: AMD64 고성능 최적화
- **📱 Surface Pro X (SQ1)**: ARM64 모빌리티 최적화
- **🛠️ ASUS PX13**: Windows 11 + WSL2 개발 환경

## 영감

- reMarkable: 글쓰기에 특화된 전자잉크 기기
- steamOS: 게임에 특화된 리눅스 배포판
- Pomera: 일본의 글쓰기 전용 기기들

## 문서 구조

```
docs/
├── 01-system-design/          # 시스템 설계
├── 02-power-management/       # 전력 관리
├── 03-korean-support/         # 한글 지원 계획
├── 04-ui-ux/                 # UI/UX 설계
├── 05-writing-features/       # 글쓰기 기능
├── 06-development/            # 개발 가이드
├── 07-research/              # 조사 자료
├── 08-development-start/      # 개발 시작 가이드
└── 09-development-setup/      # 실제 개발 환경 구축
```

## 빠른 시작

### 📖 문서 읽기
개발 문서는 `docs/` 디렉토리에서 확인할 수 있습니다.

1. [시스템 설계 개요](docs/01-system-design/README.md)
2. [전력 관리 전략](docs/02-power-management/README.md)
3. [한글 지원 계획](docs/03-korean-support/README.md)
4. [UI/UX 설계](docs/04-ui-ux/README.md)
5. [글쓰기 특화 기능](docs/05-writing-features/README.md)
6. [배포판 선택 분석](docs/07-research/distro-comparison.md)

### 🚀 개발 시작하기
실제 개발을 시작하려면:

7. **[개발 시작 가이드](docs/08-development-start/README.md)** - 체크리스트와 전략
8. **[WSL2 + Debian 환경 구축](docs/09-development-setup/01-wsl2-setup.md)** ← 실제 시작!

단계별 가이드를 따라 안전하고 체계적으로 개발 환경을 구축할 수 있습니다.

## 🎉 **현재 진행 상황** (2025-07-06)

### ✅ **완성된 작업들**
- **🏗️ Live Build 환경 구축** - WSL2 + Debian 12 기반 개발 환경 완료
- **📦 WriterOS 첫 번째 빌드 성공** - 한글 지원 포함 (716MB ISO)
- **⚡ 부팅 최적화** - systemd, preload, bootlogd 적용
- **💾 메모리 최적화** - zram, earlyoom으로 효율성 극대화
- **🇰🇷 한글 지원 완료** - fcitx5 입력기 + Noto CJK 폰트
- **🔧 WriterOS 전용 명령어** - `writeros-performance`, `writeros-powersave`, `writeros-suspend`
- **📊 성능 테스트 가이드** - 체계적인 검증 절차 문서화

### 📋 **개발 문서**
9. **[Live Build 환경 구축](docs/09-development-setup/02-live-build-setup.md)** - 단계별 빌드 가이드
10. **[첫 번째 프로토타입](docs/09-development-setup/03-first-prototype-amd64.md)** - 최적화 적용 과정  
11. **[빌드 명령어 가이드](docs/09-development-setup/live-build-commands-guide.md)** - 문제 해결 및 명령어 정리
12. **[테스트 가이드](docs/09-development-setup/05-writeros-testing-guide.md)** - 기능 검증 체크리스트

### 🎯 **성능 달성 현황**
| 목표 | 현재 상태 | 달성율 |
|------|-----------|--------|
| **ISO 크기** < 800MB | 716MB | ✅ 89% |
| **메모리 사용량** < 400MB | 테스트 예정 | 🔄 |
| **부팅 시간** 최적화 | 서비스 마스킹 완료 | ✅ |
| **한글 지원** | fcitx5 통합 완료 | ✅ |

### 🔜 **다음 단계**
- [ ] QEMU 환경에서 성능 벤치마크 측정
- [ ] 실제 하드웨어 테스트 (ASUS G14)
- [ ] 글쓰기 앱 통합 (Neovim 고도화)
- [ ] AI 기능 통합 계획

### 🛠️ **기술 스택**
- **베이스**: Debian 12 (Bookworm)
- **빌드 도구**: Live Build 20230502
- **최적화**: systemd, zram, earlyoom, preload
- **한글 지원**: fcitx5-hangul, fonts-noto-cjk
- **에디터**: Neovim
- **테스트**: QEMU (실제 하드웨어 대기)

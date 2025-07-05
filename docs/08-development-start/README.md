# WriterOS 개발 시작 가이드

## 개발 진입 전 체크리스트

### 1. 🎯 목표 하드웨어 명확화

**실제 타겟 기기**:
- [x] **ASUS 제피로스 G14 (2021)**: AMD Ryzen 5900HS/4900HS + RTX 3060/3070
- [x] **Surface Pro X (SQ1)**: ARM64 Microsoft SQ1 (Snapdragon 8cx 기반)
- [x] **ASUS PX13**: Windows 11 + WSL2 (개발 환경)

**아키텍처 지원 범위**:
- **AMD64**: ASUS 제피로스 G14 대응
- **ARM64**: Surface Pro X 대응
- **멀티 아키텍처**: Debian은 공식적으로 ARM64 지원 우수

### 2. 🛠️ 개발 환경 구성

**WSL2 기반 개발 환경**:
- [x] **메인 개발 머신**: ASUS PX13 (Windows 11 + WSL2)
- [x] **AMD64 테스트 머신**: ASUS 제피로스 G14
- [x] **ARM64 테스트 머신**: Surface Pro X
- [ ] **가상머신**: QEMU 크로스 아키텍처 에뮬레이션

**WSL2 전용 개발 환경 구축**:
```bash
# WSL2에서 Debian 개발 환경 설치
# Windows PowerShell에서 실행
wsl --install -d Debian

# WSL2 Debian 내에서 개발 도구 설치
sudo apt update
sudo apt install -y debootstrap live-build git build-essential
sudo apt install -y qemu-user-static binfmt-support  # ARM64 크로스 빌드용
```

### 3. 📋 개발 방법론 선택

**멀티 아키텍처 지원 전략**:
- **AMD64 우선 개발**: 제피로스 G14에서 기본 기능 구현
- **ARM64 포팅**: Surface Pro X 특화 최적화
- **통합 이미지**: 두 아키텍처 모두 지원하는 ISO 생성

**크로스 컴파일 환경**:
```bash
# WSL2에서 ARM64 크로스 빌드 설정
sudo apt install crossbuild-essential-arm64
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
```

### 4. 🚀 개발 우선순위 정하기

**Phase 1: 기본 환경 구축 (2-3주)**
- [ ] Debian AMD64 최소 설치 + 필수 패키지
- [ ] 한글 입력 시스템 (fcitx5) - 멀티 아키텍처
- [ ] 기본 글쓰기 도구 (Neovim/Helix)
- [ ] 전력 관리 기본 설정
- [ ] **ARM64 포팅 시작**: Surface Pro X 호환성 확인

**Phase 2: 글쓰기 환경 완성 (2-3주)**
- [ ] 집중 모드 구현 (네트워크 차단, 알림 차단)
- [ ] 글쓰기 UI 개발
- [ ] 파일 관리 시스템
- [ ] 자동 저장 및 백업
- [ ] **ARM64 최적화**: Surface Pro X 터치/펜 지원

**Phase 3: 전력 최적화 (2-3주)**
- [ ] 퀵리줌 최적화 (AMD64/ARM64 각각)
- [ ] 배터리 수명 최적화
- [ ] **하드웨어별 튜닝**: 
  - 제피로스 G14: GPU 전력 관리, 고성능 CPU 최적화
  - Surface Pro X: ARM64 절전 모드, 팬리스 운영

**Phase 4: AI 통합 (2-3주, AI 활용으로 단축 예상)**
- [ ] 로컬 AI 모델 통합 (ARM64 호환 모델 포함)
- [ ] API 기반 AI 서비스
- [ ] 글쓰기 도우미 기능
- [ ] **ARM64 AI 최적화**: Neural Processing Unit 활용

### 5. 📊 테스트 및 측정 계획

**하드웨어별 성능 목표**:

**ASUS 제피로스 G14 (AMD64)**:
- 부팅 시간: 8초 이내 (고성능 하드웨어)
- 퀵리줌 시간: 1초 이내 (NVMe SSD + 고성능 CPU)
- 배터리 수명: 6-8시간 (게이밍 노트북 특성상)
- 메모리 사용량: 800MB 이하

**Surface Pro X (ARM64)**:
- 부팅 시간: 10초 이내
- 퀵리줌 시간: 2초 이내 (절전 설계)
- 배터리 수명: 10-12시간 (ARM64 최적화)
- 메모리 사용량: 600MB 이하

**성능 측정 도구**:
```bash
# 멀티 아키텍처 지원 측정
# AMD64에서
systemd-analyze
powertop

# ARM64에서 (Surface Pro X)
systemd-analyze
upower -i /org/freedesktop/UPower/devices/battery_BAT0
```

### 6. 🛡️ 백업 및 안전 계획

**하드웨어별 백업 전략**:
- **제피로스 G14**: 전체 시스템 이미지 백업
- **Surface Pro X**: Windows 복구 드라이브 + 시스템 백업
- **PX13 (개발환경)**: WSL2 배포판 백업

**안전 개발 절차**:
- [ ] WSL2에서 먼저 테스트
- [ ] 가상머신에서 크로스 아키텍처 테스트
- [ ] 단계별 스냅샷 생성
- [ ] 매일 개발 진행사항 커밋

### 7. 📦 필요한 도구 및 패키지

**WSL2 개발 도구**:
```bash
# WSL2 Debian에서 실행
sudo apt install -y debootstrap live-build git build-essential

# 크로스 아키텍처 지원
sudo apt install -y qemu-user-static binfmt-support
sudo apt install -y crossbuild-essential-arm64

# 개발 환경
sudo apt install -y vim code

# 테스트 도구
sudo apt install -y qemu-system-x86-64 qemu-system-aarch64
```

**멀티 아키텍처 Debian 패키지**:
```bash
# AMD64 + ARM64 공통 패키지
linux-image-amd64  # AMD64용
linux-image-arm64  # ARM64용
systemd

# 한글 지원 (멀티 아키텍처)
fcitx5 fcitx5-hangul fonts-noto-cjk

# 글쓰기 도구
neovim pandoc zathura

# 전력 관리
tlp powertop acpi-support
```

### 8. 🔧 개발 환경 즉시 구축

**WSL2 기반 빠른 시작 스크립트**:
```bash
#!/bin/bash
# WriterOS 멀티 아키텍처 개발 환경 구축

# 1. WSL2 Debian 확인
if ! command -v wsl &> /dev/null; then
    echo "WSL2 설치 필요: wsl --install -d Debian"
    exit 1
fi

# 2. 개발 도구 설치
sudo apt update
sudo apt install -y debootstrap live-build git build-essential
sudo apt install -y qemu-user-static binfmt-support crossbuild-essential-arm64

# 3. 작업 디렉토리 생성
mkdir -p ~/writeros-dev/{amd64,arm64}
cd ~/writeros-dev

# 4. AMD64 라이브 이미지 구성
cd amd64
lb config --distribution bookworm --architectures amd64

# 5. ARM64 라이브 이미지 구성
cd ../arm64
lb config --distribution bookworm --architectures arm64

# 6. 개발 브랜치 생성
git init
git remote add origin <repository>
git checkout -b multiarch-prototype

echo "WriterOS 멀티 아키텍처 개발 환경 구축 완료!"
echo "테스트 하드웨어: ASUS 제피로스 G14 (AMD64), Surface Pro X (ARM64)"
```

## 🚨 주의사항

### ARM64 특별 고려사항
1. **Surface Pro X 호환성**: 
   - SQ1 프로세서는 일부 x86 에뮬레이션 한계 존재
   - 네이티브 ARM64 패키지 우선 사용
   - 터치스크린, 펜 입력 지원 추가 필요

2. **크로스 컴파일 복잡성**:
   - 일부 패키지는 ARM64에서 별도 빌드 필요
   - 에뮬레이션 환경에서의 성능 제한

### WSL2 개발 환경 한계
1. **실제 하드웨어 테스트 필수**: suspend/resume은 WSL2에서 테스트 불가
2. **USB 장치 접근 제한**: 일부 하드웨어 기능 테스트 어려움
3. **성능 측정 정확도**: 실제 환경과 차이 발생 가능

### 첫 번째 마일스톤 (수정)
**목표**: 멀티 아키텍처 지원 기본 WriterOS 이미지 생성
**기간**: 1-2주 (ARM64 포팅 추가로 연장)
**결과물**: 
- AMD64 Live ISO (제피로스 G14용)
- ARM64 Live ISO (Surface Pro X용)
- 한글 입력 가능한 최소 기능

---

## 하드웨어별 특화 개발 전략

### 🎮 ASUS 제피로스 G14 (고성능 최적화)
- **장점**: 고성능 CPU/GPU, 빠른 스토리지
- **전략**: 성능 최적화 우선, 배터리 수명은 타협 가능
- **특화 기능**: GPU 가속 AI 추론, 고해상도 글쓰기

### 📱 Surface Pro X (모빌리티 최적화)
- **장점**: 극한 배터리 수명, 팬리스 운영
- **전략**: 절전 최적화 우선, 터치/펜 지원
- **특화 기능**: 항상 켜져 있는 글쓰기 기기

이제 시스템 설계 문서도 업데이트하겠습니다! 🚀 
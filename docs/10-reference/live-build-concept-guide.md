# Live Build 개념 이해 가이드

WriterOS 개발에서 사용하는 Live Build의 핵심 개념들을 ROS2 colcon build와 비교하여 설명합니다.

## 🔨 Live Build란 무엇인가?

### ROS2 colcon build와 비교
```bash
# ROS2에서
colcon build  # 소스코드 → 실행가능한 바이너리

# Live Build에서  
lb build      # 패키지 목록 + 설정 → 부팅가능한 ISO 이미지
```

**colcon build**는 소스코드를 컴파일해서 실행 가능한 프로그램을 만드는 것이고,
**lb build**는 여러 패키지들을 조합해서 완전한 운영체제 이미지를 만드는 것입니다.

### Live Build의 역할
Live Build는 **Debian 기반 라이브 시스템**을 만드는 도구입니다:
- 📦 **패키지 선택**: 어떤 프로그램들을 포함할지
- ⚙️ **설정 적용**: 시스템이 어떻게 동작할지  
- 💿 **이미지 생성**: USB나 CD로 부팅 가능한 ISO 파일 생성

## 🛠️ 각 빌드 도구들의 역할

### 1. debootstrap - 기본 시스템 생성기
```bash
# 역할: 최소한의 Debian 시스템을 다운로드하고 설치
debootstrap bookworm /tmp/debian http://deb.debian.org/debian
```
- 🏗️ **기초 공사**: 빈 디렉토리에 기본 Linux 시스템 설치
- 📦 **패키지 매니저**: apt, dpkg 등 기본 도구들 설치
- 🔧 **부트스트랩**: 자기 자신을 관리할 수 있는 최소 시스템 구축

### 2. live-build - 전체 빌드 오케스트레이터
```bash
# 역할: 전체 빌드 과정을 관리하는 마에스트로
lb build
```
- 📋 **빌드 매니저**: 4단계 빌드 과정 조율
- 🎯 **설정 해석**: config/ 디렉토리의 모든 설정 적용
- 🔄 **상태 관리**: 빌드 진행 상황 추적

### 3. squashfs-tools - 파일 시스템 압축기
```bash
# 역할: 라이브 시스템용 압축 파일시스템 생성
mksquashfs /chroot filesystem.squashfs
```
- 🗜️ **압축**: 설치된 시스템을 압축해서 CD/USB에 저장
- 📀 **읽기 전용**: 라이브 시스템의 기본 파일시스템

### 4. genisoimage + isolinux - 부팅 가능한 ISO 생성
```bash
# 역할: 실제 부팅 가능한 ISO 이미지 생성
genisoimage -o writeros.iso -b isolinux/isolinux.bin ...
```
- 💿 **ISO 생성**: 파일들을 CD/DVD 형태로 패키징
- 🚀 **부트로더**: 컴퓨터가 켜질 때 시스템 로딩

## 🎯 Live Build 4단계 빌드 과정

### 1단계: Bootstrap (기초 공사)
```bash
# 비어있는 디렉토리에 기본 Debian 시스템 설치
debootstrap bookworm chroot/ http://deb.debian.org/debian
```
- 📁 **빈 폴더** → 🏠 **기본 Linux 시스템**
- apt, bash, coreutils 등 필수 도구들 설치
- 약 200MB 정도의 최소 시스템 구축

### 2단계: Chroot (내부 꾸미기)
```bash
# 설치된 시스템 안에서 추가 작업
chroot chroot/ /bin/bash
apt install neovim git curl  # 패키지 목록의 프로그램들 설치
# Hook 스크립트들 실행 (사용자 생성, 설정 등)
```
- 🏠 **기본 시스템** → 🏡 **완전한 WriterOS**
- 패키지 목록(.list.chroot)의 모든 프로그램 설치
- Hook 스크립트 실행으로 사용자 정의 설정 적용

### 3단계: Binary (포장하기)
```bash
# 완성된 시스템을 ISO 이미지로 포장
mksquashfs chroot/ filesystem.squashfs
genisoimage -o writeros.iso ...
```
- 🏡 **완전한 시스템** → 💿 **부팅 가능한 ISO**
- 파일시스템 압축 및 부트로더 설정
- 최종 ISO 파일 생성

### 4단계: Source (소스 패키지 생성)
```bash
# 소스 코드 패키지 생성 (선택사항)
```
- 📦 **소스 아카이브**: 빌드에 사용된 모든 소스 패키지 수집
- 🔄 **재현 가능**: 나중에 동일한 시스템 재빌드 가능

## 🔧 빌드 환경 초기화 옵션 해석

```bash
lb config \
    --architectures amd64 \           # CPU 아키텍처 (Intel/AMD 64비트)
    --distribution bookworm \         # Debian 버전 (Debian 12)
    --archive-areas "main contrib non-free non-free-firmware" \  # 패키지 저장소 영역
    --linux-flavours amd64 \         # 커널 종류
    --bootappend-live "boot=live components quiet splash" \     # 부팅 옵션
    --bootloader syslinux \           # 부트로더 종류
    --binary-images iso-hybrid \      # 출력 이미지 형태
    --cache-packages true \           # 패키지 캐시 사용
    --cache-stages true               # 빌드 단계별 캐시 사용
```

### 주요 옵션들 상세 설명

#### `--archive-areas`
```bash
main              # 자유 소프트웨어 (완전 오픈소스)
contrib           # 자유 소프트웨어지만 비자유 소프트웨어에 의존
non-free          # 비자유 소프트웨어 (상용 드라이버 등)
non-free-firmware # 비자유 펌웨어 (Wi-Fi 칩셋 등)
```

#### `--bootappend-live`
```bash
boot=live         # 라이브 시스템으로 부팅
components        # 라이브 시스템 구성 요소 사용
quiet             # 부팅 메시지 최소화
splash            # 부팅 화면 표시
```

## 📦 패키지 목록과 Hook 스크립트

### 패키지 목록 (.list.chroot)
```bash
# writeros-base.list.chroot 파일
live-boot         # 라이브 시스템 부팅 지원
network-manager   # 네트워크 관리
fonts-noto-cjk    # 한글 폰트
neovim            # 텍스트 에디터
```

**ROS2 package.xml과 비교**:
```xml
<!-- ROS2 package.xml -->
<depend>rclcpp</depend>
<depend>std_msgs</depend>
```

**공통점**: 둘 다 의존성을 미리 선언해서 빌드 시 자동 설치
**차이점**: 
- ROS2는 **라이브러리 의존성**
- Live Build는 **시스템 프로그램 목록**

### Hook 스크립트
**Hook**은 빌드 과정 중 특정 시점에 실행되는 **사용자 정의 스크립트**입니다.

```bash
# 0010-writeros-config.hook.chroot
#!/bin/bash
# 이 스크립트는 chroot 환경에서 실행됩니다

useradd -m -s /bin/bash -G sudo writeros  # 사용자 생성
echo "writeros:writeros" | chpasswd       # 비밀번호 설정
```

#### Hook 실행 시점
```
1. bootstrap (기본 시스템 설치)
2. chroot    (패키지 설치 + Hook 실행) ← 여기서 Hook 실행!
3. binary    (ISO 이미지 생성)  
4. source    (소스 패키지 생성)
```

## 🏗️ 카페 비유로 이해하기

WriterOS를 **카페**로 비유하면:

1. **debootstrap** = 🏗️ 건물 기초 공사 (벽, 바닥, 전기)
2. **패키지 목록** = 📋 구입할 장비 목록 (커피머신, 의자, 테이블)
3. **Hook 스크립트** = 👨‍🔧 인테리어 업체 (간판 설치, 메뉴판 제작)
4. **ISO 생성** = 📦 완성된 카페를 통째로 포장해서 배송

## 🎯 ROS2와 Live Build 비교표

| 구분 | ROS2 colcon build | Live Build |
|------|-------------------|------------|
| **입력** | 소스코드 (.cpp, .py) | 패키지 목록 + 설정 |
| **과정** | 컴파일 + 링크 | 다운로드 + 설치 + 설정 |
| **출력** | 실행 파일 | 부팅 가능한 ISO |
| **목적** | 로봇 프로그램 실행 | 운영체제 배포 |
| **캐시** | build/ 디렉토리 | cache/ 디렉토리 |
| **설정** | package.xml | config/ 디렉토리 |
| **의존성** | 라이브러리 | 시스템 패키지 |

## 🔍 주요 명령어 요약

### 빌드 관련
```bash
lb config      # 빌드 환경 설정
lb build       # 실제 빌드 실행
lb clean       # 빌드 결과 정리
lb clean --purge  # 완전 정리 (캐시 포함)
```

### 모니터링
```bash
# 빌드 진행 상황 모니터링
watch -n 5 'du -sh . && ls -la *.iso 2>/dev/null || echo "빌드 진행 중..."'

# 빌드 로그 확인
tail -f .build/log
```

### 테스트
```bash
# QEMU로 테스트
qemu-system-x86_64 -m 2048 -cdrom live-image-amd64.hybrid.iso -boot d
```

---
*이 가이드는 Live Build의 핵심 개념들을 정리한 레퍼런스 문서입니다.* 
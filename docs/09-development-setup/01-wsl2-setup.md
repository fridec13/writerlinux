# WSL2 + Debian 개발 환경 구축 가이드

WriterOS 개발을 위한 WSL2 기반 개발 환경을 단계별로 구축합니다.

## 📋 사전 준비사항

### 시스템 요구사항
- Windows 10 버전 2004 (빌드 19041) 이상 또는 Windows 11
- x64 시스템 (ASUS PX13)
- 관리자 권한
- 인터넷 연결

### 하드웨어 가상화 확인
1. **작업 관리자** 열기 (`Ctrl + Shift + Esc`)
2. **성능** 탭 → **CPU** 클릭
3. **가상화** 항목이 **사용** 상태인지 확인

```
✅ 가상화: 사용
❌ 가상화: 사용 안 함 → BIOS에서 Intel VT-x/AMD-V 활성화 필요
```

## Step 1: WSL 기능 활성화

### PowerShell 관리자 권한으로 실행
1. `Windows + X` → **Windows PowerShell (관리자)** 선택
2. 다음 명령어 실행:

```powershell
# WSL 기능 활성화
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# 가상 머신 플랫폼 기능 활성화
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### 시스템 재시작
```powershell
# 재시작 필요
Restart-Computer
```

## Step 2: WSL2 Linux 커널 업데이트

### 커널 업데이트 패키지 다운로드
1. [WSL2 Linux 커널 업데이트 패키지](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi) 다운로드
2. `wsl_update_x64.msi` 실행하여 설치

### WSL2를 기본 버전으로 설정
```powershell
# PowerShell 관리자 권한에서 실행
wsl --set-default-version 2
```

## Step 3: Debian 설치

### Microsoft Store에서 설치 (권장)
1. **Microsoft Store** 앱 열기
2. **Debian** 검색
3. **Debian GNU/Linux** 설치 클릭

### 또는 PowerShell로 설치
```powershell
# PowerShell에서 직접 설치
wsl --install -d Debian
```

## Step 4: Debian 초기 설정

### 첫 실행 및 사용자 계정 생성
1. 시작 메뉴에서 **Debian** 실행
2. 사용자명 입력 (예: `writeros`)
3. 비밀번호 설정

```bash
# 초기 실행 시 나타나는 프롬프트
Installing, this may take a few minutes...
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username: writeros
New password: [패스워드 입력]
Retype new password: [패스워드 재입력]
```

### WSL2 버전 확인
```bash
# Windows PowerShell에서 확인
wsl --list --verbose
```

**예상 출력**:
```
  NAME      STATE           VERSION
* Debian    Running         2
```

### Debian 시스템 정보 확인
```bash
# Debian 터미널에서 실행
# 배포판 정보 확인
lsb_release -a

# 커널 정보 확인
uname -a

# 메모리 정보 확인
free -h

# 디스크 공간 확인
df -h
```

**예상 출력 예시**:
```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID: Debian
Description:    Debian GNU/Linux 12 (bookworm)
Release:        12
Codename:       bookworm

$ uname -a
Linux PX13-WSL 5.15.90.1-microsoft-standard-WSL2 #1 SMP x86_64 GNU/Linux

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       0.5Gi       7.0Gi        0.0Ki       0.2Gi       7.0Gi
Swap:          2.0Gi          0B       2.0Gi
```

## Step 5: Debian 시스템 업데이트

### 패키지 목록 업데이트
```bash
# 관리자 권한 확인
sudo whoami  # root가 출력되어야 함

# 패키지 목록 업데이트
sudo apt update
```

### 시스템 패키지 업그레이드
```bash
# 전체 시스템 업그레이드
sudo apt upgrade -y

# 추가 패키지 정리
sudo apt autoremove -y
```

## Step 6: 개발 도구 설치

### 필수 개발 도구
```bash
# 빌드 도구 설치
sudo apt install -y build-essential git curl wget

# 버전 확인
gcc --version
git --version
```

### WriterOS 개발용 도구
```bash
# 시스템 빌드 도구
sudo apt install -y debootstrap live-build

# 크로스 컴파일 도구 (ARM64 지원)
sudo apt install -y qemu-user-static binfmt-support
sudo apt install -y crossbuild-essential-arm64

# 편집기
sudo apt install -y vim neovim

# 유틸리티
sudo apt install -y htop tree unzip
```

## Step 7: 작업 디렉토리 설정

### WriterOS 개발 디렉토리 생성
```bash
# 홈 디렉토리로 이동
cd ~

# 개발 디렉토리 구조 생성
mkdir -p writeros-dev/{amd64,arm64,docs,scripts}

# 디렉토리 구조 확인
tree writeros-dev
```

**예상 출력**:
```
writeros-dev/
├── amd64/
├── arm64/
├── docs/
└── scripts/
```

### Git 설정
```bash
# Git 사용자 정보 설정
git config --global user.name "WriterOS Developer"
git config --global user.email "developer@writeros.dev"

# 설정 확인
git config --list
```

## Step 8: 멀티 아키텍처 지원 확인

### QEMU 에뮬레이션 확인
```bash
# ARM64 에뮬레이션 확인
update-binfmts --display qemu-aarch64

# 정상 출력 예시:
# qemu-aarch64 (enabled):
#      package = qemu-user-static
#      type = magic
#      ...
```

### 크로스 컴파일 환경 테스트
```bash
# ARM64 크로스 컴파일러 확인
aarch64-linux-gnu-gcc --version

# 예상 출력:
# aarch64-linux-gnu-gcc (Debian 12.2.0-14) 12.2.0
```

## Step 9: 첫 번째 테스트

### 간단한 Hello World 테스트
```bash
# 테스트 파일 생성
cat > ~/writeros-dev/test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("WriterOS Development Environment Ready!\n");
    printf("Architecture: %s\n", 
    #ifdef __aarch64__
        "ARM64"
    #else
        "AMD64"
    #endif
    );
    return 0;
}
EOF

# AMD64용 컴파일 및 실행
gcc ~/writeros-dev/test.c -o ~/writeros-dev/test-amd64
~/writeros-dev/test-amd64

# ARM64용 크로스 컴파일
aarch64-linux-gnu-gcc ~/writeros-dev/test.c -o ~/writeros-dev/test-arm64
echo "ARM64 바이너리 생성 완료"
```

## Step 10: 환경 확인 체크리스트

### ✅ 필수 확인사항
```bash
# 1. WSL2 버전 확인
wsl --list --verbose | grep Debian

# 2. Debian 버전 확인
cat /etc/debian_version

# 3. 개발 도구 확인
which gcc git debootstrap live-build

# 4. 크로스 컴파일 확인
which aarch64-linux-gnu-gcc

# 5. 작업 디렉토리 확인
ls -la ~/writeros-dev/

# 6. 권한 확인
sudo -l
```

## 🎉 완료!

모든 단계가 성공적으로 완료되었다면 다음과 같은 환경이 구축되었습니다:

- ✅ WSL2 + Debian 12 "Bookworm"
- ✅ AMD64/ARM64 멀티 아키텍처 지원
- ✅ WriterOS 개발 도구 설치 완료
- ✅ 크로스 컴파일 환경 구축
- ✅ 작업 디렉토리 설정

## 🔧 문제 해결

### WSL2 설치 실패 시
```powershell
# WSL 상태 확인
wsl --status

# WSL 재설치
wsl --unregister Debian
wsl --install -d Debian
```

### 네트워크 연결 문제 시
```bash
# DNS 설정 확인
cat /etc/resolv.conf

# DNS 재설정 (필요시)
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### 권한 문제 시
```bash
# sudo 권한 확인
groups $USER

# sudoers 그룹에 추가 (필요시)
sudo usermod -aG sudo $USER
```

## 📝 다음 단계

환경 구축이 완료되었으니 이제 다음 단계로 진행할 수 있습니다:

1. **[Live Build 환경 구축](02-live-build-setup.md)**
2. **[첫 번째 AMD64 프로토타입 빌드](03-first-prototype-amd64.md)**
3. **[ARM64 크로스 컴파일 테스트](04-arm64-cross-compile.md)**

---
**🏗️ WriterOS 개발 환경 구축 완료!** 

이제 실제 OS 개발을 시작할 준비가 되었습니다! 🚀 
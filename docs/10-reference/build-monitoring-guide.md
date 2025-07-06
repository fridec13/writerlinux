# Live Build 진행 상태 모니터링 가이드

Live Build가 실제로 진행 중인지, 아니면 멈춘 것인지 확인하는 방법들을 설명합니다.

## 🤔 사용자의 고민

> **"터미널에 그냥 빌드진행중만 떠있으면 빌드 중인거지? 모르겠어서"**

**답변**: 여러 방법으로 확인할 수 있습니다! 단순히 "빌드 진행중" 메시지만으로는 부족해요.

## 🔍 빌드 진행 상태 확인 방법들

### 1. 터미널 출력 상세 관찰
```bash
# 빌드 실행 (상세 출력)
sudo lb build --verbose

# 또는 디버그 모드
sudo lb build --debug
```

**정상 진행 시 보이는 것들:**
```
P: Begin bootstrapping system...
P: Configuring file /etc/hosts
P: Configuring file /etc/resolv.conf
P: Configuring package management
P: Updating packages
P: Installing packages
P: Configuring packages
```

**멈춘 것 같다면:**
- 같은 줄이 5분 이상 변화 없음
- 네트워크 다운로드 중 속도가 0
- 에러 메시지 후 멈춤

### 2. 별도 터미널에서 실시간 모니터링
```bash
# 새 터미널 창을 열고 실행
# 방법 1: 파일 크기 변화 확인
watch -n 5 'du -sh ~/writeros-build/amd64 && echo "=== 최근 변경된 파일 ===" && find ~/writeros-build/amd64 -type f -mmin -5 | head -10'

# 방법 2: 프로세스 상태 확인
watch -n 2 'ps aux | grep -E "(debootstrap|apt|dpkg|mksquashfs)" | grep -v grep'

# 방법 3: ISO 파일 생성 확인
watch -n 10 'ls -lah ~/writeros-build/amd64/*.iso 2>/dev/null || echo "ISO 파일 아직 생성되지 않음"'
```

### 3. 빌드 로그 실시간 확인
```bash
# 빌드 로그 실시간 추적
tail -f ~/writeros-build/amd64/.build/log

# 또는 여러 로그 파일 동시 확인
find ~/writeros-build/amd64 -name "*.log" -exec tail -f {} +
```

### 4. 네트워크 활동 확인
```bash
# 네트워크 사용량 확인 (패키지 다운로드 중인지)
sudo netstat -i
# 또는
ip -s link show

# 특정 프로세스의 네트워크 활동
sudo nethogs
```

### 5. 디스크 I/O 활동 확인
```bash
# 디스크 사용량 실시간 확인
iostat -x 1

# 또는 간단히
watch -n 1 'df -h | grep -E "(/$|/tmp)"'
```

## 📊 단계별 진행 상황 이해

### Bootstrap 단계 (1단계)
```bash
# 이런 메시지들이 나타남:
P: Begin bootstrapping system...
P: Retrieving Release
P: Retrieving Packages
P: Extracting base-files
P: Extracting base-passwd
```

**확인 방법:**
```bash
# debootstrap 프로세스 확인
ps aux | grep debootstrap

# 다운로드 중인 패키지 확인
ls -la ~/writeros-build/amd64/cache/packages/
```

### Chroot 단계 (2단계)
```bash
# 이런 메시지들이 나타남:
P: Configuring file /etc/apt/sources.list
P: Installing packages
P: Configuring packages
P: Running hooks
```

**확인 방법:**
```bash
# 설치 중인 패키지 확인
ps aux | grep -E "(apt|dpkg)"

# chroot 환경 확인
ls -la ~/writeros-build/amd64/chroot/
```

### Binary 단계 (3단계)
```bash
# 이런 메시지들이 나타남:
P: Creating squashfs image
P: Creating disk image
P: Creating ISO image
```

**확인 방법:**
```bash
# 압축 진행 확인
ps aux | grep mksquashfs

# 임시 파일 생성 확인
ls -la ~/writeros-build/amd64/binary/
```

## 🚨 문제 상황 식별

### 1. 완전히 멈춘 경우
**증상:**
- 터미널 출력이 5분 이상 변화 없음
- CPU 사용률 0%
- 네트워크 활동 없음

**확인 방법:**
```bash
# 빌드 프로세스 확인
ps aux | grep -E "(lb|live-build|debootstrap)" | grep -v grep

# 만약 아무것도 안 나오면 빌드가 멈춘 것
```

**해결책:**
```bash
# 빌드 중단 후 재시작
sudo pkill -f "lb build"
sudo lb clean
sudo lb build
```

### 2. 네트워크 문제로 멈춘 경우
**증상:**
- "Retrieving" 메시지 후 멈춤
- 다운로드 속도 0

**확인 방법:**
```bash
# 네트워크 연결 테스트
ping -c 3 deb.debian.org
ping -c 3 8.8.8.8
```

**해결책:**
```bash
# 네트워크 재연결 후 재시작
sudo systemctl restart networking
sudo lb build
```

### 3. 디스크 공간 부족
**증상:**
- "No space left on device" 에러
- 빌드 중간에 멈춤

**확인 방법:**
```bash
# 디스크 공간 확인
df -h
du -sh ~/writeros-build/amd64/
```

**해결책:**
```bash
# 캐시 정리
sudo lb clean --cache
sudo apt autoremove
sudo apt autoclean
```

## 📈 정상 진행 상황 예시

### 정상적인 터미널 출력
```bash
$ sudo lb build

P: Begin bootstrapping system...
P: Retrieving Release                     ← 네트워크 다운로드 중
P: Retrieving Packages                    ← 패키지 목록 받는 중
P: Extracting base-files                  ← 기본 파일 설치 중
P: Extracting base-passwd                 ← 계속 진행됨
P: Extracting bash                        ← 패키지들이 계속 설치됨
...
P: Configuring file /etc/hosts           ← 설정 파일 생성 중
P: Configuring file /etc/resolv.conf     ← 네트워크 설정 중
P: Installing packages                    ← 추가 패키지 설치 중
...
P: Creating squashfs image               ← 압축 파일 생성 중
P: Creating disk image                   ← 디스크 이미지 생성 중
P: Creating ISO image                    ← 최종 ISO 생성 중
```

### 정상적인 모니터링 출력
```bash
# watch 명령어 출력
Every 5.0s: du -sh ~/writeros-build/amd64

256M    ~/writeros-build/amd64    ← 크기가 계속 증가
312M    ~/writeros-build/amd64    ← 5초 후
389M    ~/writeros-build/amd64    ← 또 5초 후
```

## 🔧 유용한 모니터링 스크립트

### 종합 모니터링 스크립트
```bash
#!/bin/bash
# build-monitor.sh

echo "=== WriterOS 빌드 모니터링 시작 ==="

while true; do
    clear
    echo "📊 $(date)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 빌드 디렉토리 크기
    echo "📁 빌드 디렉토리 크기:"
    du -sh ~/writeros-build/amd64/ 2>/dev/null || echo "디렉토리 없음"
    
    # 활성 프로세스
    echo -e "\n🔄 활성 빌드 프로세스:"
    ps aux | grep -E "(lb|debootstrap|apt|dpkg|mksquashfs)" | grep -v grep || echo "빌드 프로세스 없음"
    
    # ISO 파일 상태
    echo -e "\n💿 ISO 파일 상태:"
    ls -lah ~/writeros-build/amd64/*.iso 2>/dev/null || echo "ISO 파일 아직 생성되지 않음"
    
    # 최근 변경된 파일
    echo -e "\n📝 최근 변경된 파일 (최근 1분):"
    find ~/writeros-build/amd64 -type f -mmin -1 2>/dev/null | head -5 || echo "변경된 파일 없음"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 5초마다 자동 새로고침 (Ctrl+C로 종료)"
    
    sleep 5
done
```

**사용법:**
```bash
# 스크립트 실행 권한 부여
chmod +x build-monitor.sh

# 빌드 모니터링 시작
./build-monitor.sh
```

## 📋 빌드 상태 체크리스트

### ✅ 정상 진행 중
- [ ] 터미널에 새로운 메시지가 계속 나타남
- [ ] 빌드 디렉토리 크기가 계속 증가
- [ ] 관련 프로세스가 활성 상태 (ps aux로 확인)
- [ ] 네트워크 활동 있음 (다운로드 중일 때)
- [ ] 디스크 공간 충분함

### ❌ 문제 상황
- [ ] 5분 이상 터미널 출력 변화 없음
- [ ] 빌드 프로세스가 보이지 않음
- [ ] 디스크 공간 부족 에러
- [ ] 네트워크 연결 에러
- [ ] 권한 관련 에러

## 🎯 요약

**빌드가 정말 진행 중인지 확인하는 가장 쉬운 방법:**

1. **새 터미널 열고 실행:**
   ```bash
   watch -n 5 'du -sh ~/writeros-build/amd64 && ps aux | grep lb'
   ```

2. **크기가 계속 증가하고 lb 프로세스가 보이면 정상 진행 중**

3. **5분 이상 변화 없으면 문제 상황**

**기억하세요**: Live Build는 시간이 오래 걸리는 작업이므로 (30분-1시간), 인내심을 가지고 모니터링하는 것이 중요합니다! 🕐

---
*이 가이드는 Live Build 진행 상태를 정확히 파악하기 위한 모니터링 방법들을 정리한 레퍼런스입니다.* 
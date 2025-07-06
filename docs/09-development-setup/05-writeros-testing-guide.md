# WriterOS 기능 테스트 가이드

## 📋 **테스트 개요**

이 가이드는 WriterOS 빌드 후 **기능 검증**을 위한 체계적인 테스트 절차와 명령어들을 제공합니다.

### **테스트 환경**
- **QEMU 실행**: `qemu-system-x86_64 -m 2048 -smp 2 -cdrom live-image-amd64.hybrid.iso -boot d -display gtk -accel tcg`
- **메모리**: 2GB 할당
- **부팅 모드**: Live USB 모드

## 🎯 **성능 목표 기준**

| 항목 | 목표값 | 측정 방법 |
|------|--------|-----------|
| **메모리 사용량** | < 400MB | `free -h` |
| **ISO 크기** | < 800MB | `ls -lah *.iso` |
| **부팅 시간** | 실제 하드웨어 기준 | `systemd-analyze` |
| **패키지 수** | 최소화 | `dpkg -l \| wc -l` |

---

## 🚀 **1. 부팅 성능 테스트**

### **부팅 시간 분석**
```bash
# 전체 부팅 시간 확인
systemd-analyze

# 서비스별 부팅 시간 (느린 순서)
systemd-analyze blame

# 부팅 병목 지점 확인
systemd-analyze critical-chain

# 부팅 과정 그래프 생성 (선택사항)
systemd-analyze plot > boot-analysis.svg
```

### **예상 결과**
- **QEMU**: 50-60초 (가상화 오버헤드)
- **실제 하드웨어**: 15-30초 예상
- **Kernel**: 15-20초
- **Userspace**: 나머지 시간

---

## 💾 **2. 메모리 효율성 테스트**

### **메모리 사용량 확인**
```bash
# 기본 메모리 정보 (목표: used < 400MB)
free -h

# 메모리 상세 정보
cat /proc/meminfo | head -10

# 메모리 사용률 계산
echo "Memory usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"

# 프로세스별 메모리 사용량 (상위 10개)
ps aux --sort=-%mem | head -10

# 시스템 리소스 실시간 모니터링
htop
```

### **zram 스왑 확인**
```bash
# zram 디바이스 확인
cat /proc/swaps
lsblk | grep zram

# zram 압축률 확인
cat /sys/block/zram*/mm_stat 2>/dev/null || echo "zram 정보 없음"
```

---

## 🔧 **3. WriterOS 전용 명령어 테스트**

### **명령어 존재 확인**
```bash
# WriterOS 커스텀 명령어들 확인
which writeros-suspend writeros-performance writeros-powersave
ls -la /usr/local/bin/writeros-*
```

### **성능 모드 테스트**
```bash
# 현재 CPU 주파수 거버너 확인
echo "현재 CPU 거버너:"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | head -1

# 성능 모드로 전환
writeros-performance

# 성능 모드 적용 확인
echo "성능 모드 후:"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | head -1
```

### **절전 모드 테스트**
```bash
# 절전 모드로 전환
writeros-powersave

# 절전 모드 적용 확인
echo "절전 모드 후:"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | head -1

# CPU 주파수 정보
cat /proc/cpuinfo | grep "cpu MHz" | head -4
```

### **빠른 절전 테스트** ⚠️ **주의: 실제로 절전됩니다**
```bash
# 절전 기능 테스트 (선택사항)
# writeros-suspend
```

---

## 🇰🇷 **4. 한글 지원 테스트**

### **한글 폰트 출력 확인**
```bash
# 한글 테스트 파일 확인
ls -la ~/korean-test.txt
echo "=== 한글 테스트 파일 내용 ==="
cat ~/korean-test.txt

# 터미널에서 한글 출력 테스트
echo "안녕하세요! WriterOS 한글 테스트입니다."
echo "글쓰기 최적화 리눅스 배포판"
echo "🇰🇷 한국어 지원 완벽 작동!"

# 설치된 한글 폰트 확인
fc-list | grep -i noto | head -5
fc-list | grep -i korean
```

### **한글 입력기 (fcitx5) 테스트**
```bash
# fcitx5 버전 및 상태 확인
fcitx5 --version
ps aux | grep fcitx5

# 입력기 시작 (백그라운드)
fcitx5 &

# 입력기 설정 확인
im-config -l

# fcitx5 프로세스 확인
pgrep -f fcitx5
```

### **한글 입력 실제 테스트** (GUI 필요)
```bash
# nano로 한글 입력 테스트
nano ~/korean-input-test.txt
# 1. Ctrl+Space로 한글 입력 전환
# 2. 한글 문장 입력
# 3. Ctrl+X로 저장 후 종료

# 입력된 한글 확인
cat ~/korean-input-test.txt
```

---

## 📝 **5. Neovim 한글 편집 테스트**

### **Neovim 설치 확인**
```bash
# Neovim 버전 확인
nvim --version

# Neovim 설정 디렉토리 확인
ls -la ~/.config/nvim/ 2>/dev/null || echo "기본 설정 사용"
```

### **한글 편집 테스트**
```bash
# 한글 테스트 파일 편집
nvim ~/korean-test.txt

# Neovim 내에서 테스트 순서:
# 1. i (입력 모드 진입)
# 2. Ctrl+Space (한글 입력 전환)
# 3. 한글 문장 작성
# 4. ESC (명령 모드)
# 5. :wq (저장 후 종료)
```

### **편집 결과 확인**
```bash
# 편집된 파일 확인
echo "=== 편집된 한글 파일 ==="
cat ~/korean-test.txt
wc -l ~/korean-test.txt
```

---

## 📦 **6. 설치된 패키지 확인**

### **최적화 패키지 확인**
```bash
# 부팅 최적화 패키지
dpkg -l | grep -E "(systemd|preload|bootlogd)"

# 메모리 최적화 패키지  
dpkg -l | grep -E "(zram|earlyoom)"

# 파일시스템 최적화 패키지
dpkg -l | grep -E "(btrfs|f2fs)"

# 한글 입력기 패키지
dpkg -l | grep -E "(fcitx5|hangul|im-config)"

# 기본 패키지
dpkg -l | grep -E "(neovim|git|curl|network-manager)"
```

### **패키지 통계**
```bash
# 전체 설치된 패키지 수
echo "총 설치된 패키지 수:"
dpkg -l | grep "^ii" | wc -l

# 패키지 크기 정보
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -10
```

---

## 🛠️ **7. 시스템 서비스 최적화 확인**

### **마스킹된 서비스 확인**
```bash
# 부팅 시간 단축을 위해 마스킹된 서비스들
echo "=== 마스킹된 서비스 ==="
systemctl list-unit-files | grep masked

# 특정 서비스 상태 확인
echo "=== 주요 서비스 상태 ==="
systemctl is-enabled apt-daily.service
systemctl is-enabled apt-daily-upgrade.service  
systemctl is-enabled NetworkManager-wait-online.service
systemctl is-enabled systemd-networkd-wait-online.service
```

### **활성 서비스 확인**
```bash
# 현재 실행 중인 서비스
systemctl list-units --type=service --state=running | wc -l

# 메모리 최적화 서비스 상태
systemctl status preload --no-pager
systemctl status earlyoom --no-pager
```

---

## 🗂️ **8. 파일시스템 도구 확인**

### **파일시스템 도구 설치 확인**
```bash
# btrfs 도구
which mkfs.btrfs btrfs
btrfs --version

# f2fs 도구  
which mkfs.f2fs fsck.f2fs
mkfs.f2fs -V

# 기본 파일시스템 확인
df -T
mount | grep "^/"
```

---

## 💻 **9. 시스템 정보 종합**

### **시스템 정보 출력**
```bash
# 시스템 정보 요약 (neofetch 설치된 경우)
neofetch 2>/dev/null || {
    echo "=== WriterOS 시스템 정보 ==="
    cat /etc/os-release
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime -p)"
}

# 디스크 사용량
df -h

# CPU 정보
lscpu | grep -E "(Model name|CPU\(s\)|Architecture)"

# 메모리 정보  
free -h
```

---

## 🎯 **10. 빠른 종합 테스트 스크립트**

### **한 번에 실행할 수 있는 테스트**
```bash
#!/bin/bash
echo "======================================"
echo "     WriterOS 종합 테스트 리포트"
echo "======================================"
echo ""

echo "📊 1. 메모리 사용량:"
free -h | grep "^Mem"

echo ""
echo "🚀 2. 부팅 시간:"
systemd-analyze 2>/dev/null || echo "부팅 분석 도구 사용 불가"

echo ""
echo "🔧 3. WriterOS 명령어:"
ls -la /usr/local/bin/writeros-* 2>/dev/null || echo "WriterOS 명령어 없음"

echo ""
echo "🇰🇷 4. 한글 지원:"
ls -la ~/korean-test.txt 2>/dev/null && echo "한글 테스트 파일 존재" || echo "한글 테스트 파일 없음"
fc-list | grep -i noto | wc -l | xargs echo "Noto 폰트 개수:"

echo ""
echo "📦 5. 설치된 패키지 수:"
dpkg -l | grep "^ii" | wc -l

echo ""
echo "🚫 6. 마스킹된 서비스 수:"
systemctl list-unit-files | grep masked | wc -l

echo ""
echo "💾 7. 디스크 사용량:"
df -h | grep "^/dev"

echo ""
echo "======================================"
echo "        테스트 완료"
echo "======================================"
```

---

## 📋 **테스트 체크리스트**

### **기본 기능 ✓**
- [ ] 부팅 완료 (Live USB 모드)
- [ ] 네트워크 연결 작동
- [ ] 터미널 정상 동작
- [ ] 기본 명령어 사용 가능

### **성능 최적화 ✓**
- [ ] 메모리 사용량 < 400MB (`free -h`)
- [ ] 부팅 시간 확인 (`systemd-analyze`)
- [ ] zram 스왑 활성화 (`cat /proc/swaps`)
- [ ] 마스킹된 서비스 확인 (`systemctl list-unit-files | grep masked`)

### **한글 지원 ✓**
- [ ] 한글 폰트 출력 (`cat ~/korean-test.txt`)
- [ ] fcitx5 입력기 설치 (`fcitx5 --version`)
- [ ] 한글 입력 가능 (Ctrl+Space 테스트)
- [ ] Neovim 한글 편집 가능

### **WriterOS 전용 기능 ✓**
- [ ] `writeros-performance` 명령어 작동
- [ ] `writeros-powersave` 명령어 작동
- [ ] `writeros-suspend` 명령어 존재
- [ ] CPU 거버너 전환 확인

### **개발 도구 ✓**
- [ ] Neovim 설치 및 동작
- [ ] Git 사용 가능
- [ ] curl 네트워크 도구 사용 가능
- [ ] 파일시스템 도구 (btrfs, f2fs) 설치

---

## 🔄 **트러블슈팅**

### **자주 발생하는 문제들**

#### **한글 입력이 안 될 때**
```bash
# fcitx5 재시작
pkill fcitx5
fcitx5 &

# 환경 변수 설정
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

#### **메모리 사용량이 높을 때**
```bash
# 메모리 사용량 상위 프로세스
ps aux --sort=-%mem | head -10

# 캐시 정리
sync && echo 3 > /proc/sys/vm/drop_caches
```

#### **부팅이 느릴 때**
```bash
# 부팅 병목 확인
systemd-analyze blame | head -10
systemd-analyze critical-chain
```

---

## 📚 **추가 참고 자료**

- **Live Build 공식 문서**: https://live-team.pages.debian.net/live-manual/
- **fcitx5 설정 가이드**: https://fcitx-im.org/wiki/Fcitx_5
- **systemd 부팅 분석**: https://www.freedesktop.org/software/systemd/man/systemd-analyze.html
- **Debian 패키지 관리**: https://www.debian.org/doc/manuals/debian-reference/

---

**WriterOS 테스트를 완료하면 이 체크리스트를 참고하여 모든 기능이 정상 작동하는지 확인하세요!** ✅ 
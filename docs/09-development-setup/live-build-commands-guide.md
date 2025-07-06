# Live Build 명령어 및 이슈 해결 가이드

## 🚨 **주요 이슈: `lb clean` 후 config 초기화 문제**

### **문제 상황**
```bash
sudo lb clean          # 빌드 정리
sudo lb build          # 빌드 시도
# 결과: E: the following stage is required to be done first: config
```

### **원인**
- `lb clean`이 `.build` 디렉토리뿐만 아니라 내부 빌드 상태도 초기화
- Live Build가 config 단계가 완료되지 않았다고 판단

### **해결책**
1. **config 재설정 필요**
2. **올바른 빌드 순서 준수**

## 🔧 **올바른 WriterOS 빌드 절차**

### **1단계: 초기 설정 (최초 한 번만)**
```bash
# 빌드 디렉토리 생성
mkdir -p ~/writeros-build/amd64
cd ~/writeros-build/amd64

# Live Build 초기 설정
lb config --debian-installer true --debian-installer-gui true --architectures amd64 --distribution bookworm
```

### **2단계: WriterOS 커스터마이징**
```bash
# 기본 패키지 목록 (최소 버전)
cat > config/package-lists/writeros-minimal.list.chroot << 'EOF'
live-boot
live-config
live-config-systemd
network-manager
fonts-noto-cjk
neovim
git
curl
EOF

# 최적화 패키지 목록
cat > config/package-lists/writeros-base.list.chroot << 'EOF'
# Boot optimization
systemd
systemd-bootchart
bootlogd
preload

# Memory optimization  
zram-tools
earlyoom

# File system optimization
btrfs-progs
f2fs-tools

# Korean input method
fcitx5
fcitx5-hangul
fcitx5-config-qt
im-config
EOF

# Hook 스크립트들 설정 (별도 과정)
```

### **3단계: 정상 빌드 절차**
```bash
# ❌ 잘못된 방법
sudo lb clean && sudo lb build    # config 날아감!

# ✅ 올바른 방법
sudo lb clean                     # 빌드만 정리
lb config --debian-installer true --debian-installer-gui true --architectures amd64 --distribution bookworm    # config 재설정
sudo lb build                     # 빌드 실행
```

### **4단계: 빌드 모니터링**
```bash
# 빌드 시간 측정
time sudo lb build

# 백그라운드 빌드 (선택사항)
nohup sudo lb build > build.log 2>&1 &
tail -f build.log
```

## 🔄 **빌드 과정에서 자주 사용하는 명령어들**

### **빌드 정리 명령어들**
```bash
# 부분 정리 (cache 유지)
sudo lb clean

# 완전 정리 (cache 포함)
sudo lb clean --purge

# 특정 단계만 정리
sudo lb clean --stage chroot
sudo lb clean --stage binary
```

### **빌드 상태 확인**
```bash
# 현재 빌드 설정 확인
ls -la .build/

# 패키지 목록 확인
ls -la config/package-lists/

# Hook 스크립트 확인
ls -la config/hooks/live/

# ISO 크기 확인
ls -lah *.iso
du -h *.iso
```

### **문제 해결용 명령어들**
```bash
# Live Build 버전 확인
lb --version

# 설정 파일 검증
lb config --help

# 빌드 로그 확인
tail -f /var/log/live-build.log    # 있는 경우
```

## 🛠️ **WriterOS 전용 빌드 스크립트**

### **자동 빌드 스크립트 (build-writeros.sh)**
```bash
#!/bin/bash

echo "=== WriterOS 자동 빌드 스크립트 ==="
echo "시작 시간: $(date)"

# 빌드 디렉토리 이동
cd ~/writeros-build/amd64

# 이전 빌드 정리
echo "이전 빌드 정리 중..."
sudo lb clean

# ✅ 핵심: config 재설정
echo "Live Build config 재설정 중..."
lb config --debian-installer true \
          --debian-installer-gui true \
          --architectures amd64 \
          --distribution bookworm

# Hook 스크립트 실행 권한 확인
chmod +x config/hooks/live/*.hook.chroot 2>/dev/null || true

# 빌드 시작
echo "WriterOS 빌드 시작..."
echo "예상 시간: 25-45분"
time sudo lb build

# 결과 확인
if [ -f "live-image-amd64.hybrid.iso" ]; then
    echo "✅ 빌드 성공!"
    ls -lah live-image-amd64.hybrid.iso
    du -h live-image-amd64.hybrid.iso
else
    echo "❌ 빌드 실패!"
    exit 1
fi

echo "완료 시간: $(date)"
```

## ⚠️ **자주 발생하는 오류들**

### **1. Config 단계 오류**
```bash
# 증상
E: the following stage is required to be done first: config

# 해결
lb config --debian-installer true --debian-installer-gui true --architectures amd64 --distribution bookworm
```

### **2. 권한 오류**
```bash
# 증상
Permission denied

# 해결
sudo chown -R $USER:$USER ~/writeros-build/
chmod +x config/hooks/live/*.hook.chroot
```

### **3. 디스크 공간 부족**
```bash
# 확인
df -h ~/

# 해결
sudo lb clean --purge    # 캐시 포함 완전 정리
```

### **4. 네트워크 오류**
```bash
# 증상
Package download failed

# 해결
# 미러 서버 변경 또는 네트워크 확인
```

## 📊 **빌드 시간 및 리소스 예상치**

| 빌드 유형 | 예상 시간 | 디스크 사용량 | 메모리 권장 |
|-----------|-----------|---------------|-------------|
| **최소 빌드** | 15-25분 | 3-5GB | 2GB+ |
| **최적화 빌드** | 20-35분 | 4-6GB | 4GB+ |
| **한글 지원 빌드** | 25-45분 | 5-7GB | 4GB+ |
| **완전 빌드** | 30-60분 | 6-8GB | 6GB+ |

## 🎯 **빌드 성공 체크리스트**

### **빌드 전 확인사항**
- [ ] 디스크 여유 공간 15GB+
- [ ] 메모리 4GB+
- [ ] 네트워크 연결 안정
- [ ] sudo 권한 확인

### **빌드 후 확인사항**
- [ ] ISO 파일 생성됨
- [ ] ISO 크기 800MB 이하
- [ ] QEMU 부팅 테스트 성공
- [ ] 기본 기능 정상 작동

## 🔄 **트러블슈팅 빠른 참조**

```bash
# 문제: config 오류
lb config --debian-installer true --debian-installer-gui true --architectures amd64 --distribution bookworm

# 문제: 권한 오류  
sudo chown -R $USER:$USER .
chmod +x config/hooks/live/*.hook.chroot

# 문제: 빌드 실패
sudo lb clean --purge
# 위 config 명령어 재실행 후 빌드

# 문제: 디스크 부족
sudo lb clean --purge
sudo apt clean
```

---

**이 가이드를 따르면 `lb clean` 후 config 문제를 피할 수 있습니다!** 🚀 
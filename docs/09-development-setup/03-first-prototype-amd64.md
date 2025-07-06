# WriterOS AMD64 프로토타입 빌드

Live Build 환경에서 실제 WriterOS의 첫 번째 프로토타입을 빌드하고 최적화하는 과정을 다룹니다.

## 📋 사전 준비사항

### 확인해야 할 것들
- ✅ Live Build 환경 구축 완료 ([02-live-build-setup.md](02-live-build-setup.md) 참고)
- ✅ 기본 빌드 테스트 성공
- ✅ 디스크 여유 공간 15GB+ (다중 빌드용)
- ✅ 네트워크 연결 안정

### 빌드 환경 확인
```bash
# 기본 빌드 환경 점검
cd ~/writeros-build/amd64
ls -la live-image-amd64.hybrid.iso  # 기본 빌드 완료 확인

# 시스템 리소스 확인
free -h && df -h ~ && nproc
```

## Step 1: WriterOS 최적화 설정

### Boot Time Optimization Settings
```bash
# Add boot optimization packages
cat >> config/package-lists/writeros-base.list.chroot << 'EOF'

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
EOF
```

### Remove Unnecessary Packages
```bash
# Create package removal list
cat > config/package-lists/writeros-remove.list.chroot << 'EOF'
# Multimedia (unnecessary for writing OS)
pulseaudio-
alsa-utils-
sound-theme-freedesktop-

# Games
gnome-games-
games-*

# Development tools (remove from minimal version)
gcc-
g++-
make-
libc6-dev-

# Large documentation
doc-base-
man-db-
manpages-
info-
EOF
```

### Kernel Optimization Settings
```bash
# Optimize kernel boot parameters
vim config/bootloaders/syslinux/live.cfg.in

# Replace existing content with:
cat > config/bootloaders/syslinux/live.cfg.in << 'EOF'
label live-@FLAVOUR@
	menu label ^WriterOS (@FLAVOUR@)
	menu default
	linux @KERNEL@
	initrd @INITRD@
	append @APPEND_LIVE@ boot=live components nosplash quiet loglevel=0 rd.systemd.show_status=0 rd.udev.log-priority=0 vt.global_cursor_default=0 mitigations=off intel_idle.max_cstate=1 processor.max_cstate=1 intel_pstate=active

label live-@FLAVOUR@-failsafe
	menu label ^WriterOS (@FLAVOUR@ failsafe)
	linux @KERNEL@
	initrd @INITRD@
	append @APPEND_LIVE@ boot=live components memtest noapic noapm nodma nomce nolapic nomodeset nosmp nosplash vga=normal
EOF
```

## Step 2: WriterOS 전용 기능 구현

### Power Management Optimization Hook
```bash
# Create power management hook
cat > config/hooks/live/0030-power-optimization.hook.chroot << 'EOF'
#!/bin/bash

echo "=== WriterOS Power Management Optimization Started ==="

# TLP advanced settings
cat > /etc/tlp.conf << 'TLP_CONF'
# WriterOS Power Optimization Settings

# CPU
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=30

# Disk
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
DISK_SPINDOWN_TIMEOUT_ON_AC="0 0"
DISK_SPINDOWN_TIMEOUT_ON_BAT="60 60"

# WiFi power saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# USB auto suspend
USB_AUTOSUSPEND=1
USB_BLACKLIST_PHONE=1

# PCIe ASPM
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave
TLP_CONF

# Zram swap settings (memory optimization)
cat > /etc/systemd/system/zram-swap.service << 'ZRAM_SERVICE'
[Unit]
Description=Enable compressed swap in memory using zram
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStartPre=/sbin/modprobe zram num_devices=1
ExecStart=/bin/sh -c 'echo lz4 > /sys/block/zram0/comp_algorithm'
ExecStart=/bin/sh -c 'echo 1G > /sys/block/zram0/disksize'
ExecStart=/sbin/mkswap --label zram0 /dev/zram0
ExecStart=/sbin/swapon -p 100 /dev/zram0
ExecStop=/sbin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target
ZRAM_SERVICE

systemctl enable zram-swap

# Service optimization for faster boot
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
systemctl mask apt-daily.service
systemctl mask apt-daily.timer
systemctl mask apt-daily-upgrade.timer
systemctl mask apt-daily-upgrade.service

echo "=== WriterOS Power Management Optimization Completed ==="
EOF

chmod +x config/hooks/live/0030-power-optimization.hook.chroot
```

### Writing Environment Optimization Hook
```bash
# Create writing environment optimization hook
cat > config/hooks/live/0040-writing-environment.hook.chroot << 'EOF'
#!/bin/bash

echo "=== WriterOS Writing Environment Setup Started ==="

# Font optimization settings
cat > /etc/fonts/local.conf << 'FONT_CONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Korean font priority -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif CJK KR</family>
      <family>Liberation Serif</family>
    </prefer>
  </alias>
  
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans CJK KR</family>
      <family>Liberation Sans</family>
    </prefer>
  </alias>
  
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Noto Sans Mono CJK KR</family>
      <family>Liberation Mono</family>
    </prefer>
  </alias>

  <!-- Writing optimized rendering -->
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
</fontconfig>
FONT_CONF

# Input method auto-start setup
mkdir -p /home/writeros/.config/autostart
cat > /home/writeros/.config/autostart/fcitx5.desktop << 'FCITX5_AUTOSTART'
[Desktop Entry]
Type=Application
Name=Fcitx 5
Exec=fcitx5
Icon=fcitx
Terminal=false
Categories=System;Utility;
StartupNotify=false
NoDisplay=true
FCITX5_AUTOSTART

# Openbox window manager setup (writing focused environment)
mkdir -p /home/writeros/.config/openbox
cat > /home/writeros/.config/openbox/rc.xml << 'OPENBOX_CONF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  
  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>
  
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>no</animateIconify>
    <font place="ActiveWindow">
      <name>sans</name>
      <size>8</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>sans</name>
      <size>8</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
  </theme>
  
  <desktops>
    <number>1</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>WriterOS</name>
    </names>
    <popupTime>875</popupTime>
  </desktops>
  
  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
    <popupFixedPosition>
      <x>10</x>
      <y>10</y>
    </popupFixedPosition>
  </resize>
  
  <applications>
    <!-- Neovim window optimization -->
    <application name="nvim">
      <decor>yes</decor>
      <shade>no</shade>
      <position force="no">
        <x>center</x>
        <y>center</y>
      </position>
      <size>
        <width>80%</width>
        <height>80%</height>
      </size>
      <focus>yes</focus>
      <desktop>1</desktop>
      <layer>normal</layer>
      <iconic>no</iconic>
      <skip_pager>no</skip_pager>
      <skip_taskbar>no</skip_taskbar>
      <fullscreen>no</fullscreen>
      <maximized>no</maximized>
    </application>
  </applications>
</openbox_config>
OPENBOX_CONF

# Set file ownership
chown -R writeros:writeros /home/writeros/.config

echo "=== WriterOS Writing Environment Setup Completed ==="
EOF

chmod +x config/hooks/live/0040-writing-environment.hook.chroot
```

### WriterOS Shell Scripts
```bash
# Add WriterOS specific commands
cat > config/hooks/live/0050-writeros-commands.hook.chroot << 'EOF'
#!/bin/bash

echo "=== WriterOS Custom Commands Installation Started ==="

# Create WriterOS commands directory
mkdir -p /usr/local/bin

# Quick suspend command
cat > /usr/local/bin/writeros-suspend << 'SUSPEND_CMD'
#!/bin/bash
# WriterOS quick suspend

echo "WriterOS: Entering suspend mode..."
sync
echo mem > /proc/sys/vm/drop_caches
systemctl suspend
SUSPEND_CMD

# Performance mode command
cat > /usr/local/bin/writeros-performance << 'PERF_CMD'
#!/bin/bash
# WriterOS performance mode

echo "WriterOS: Activating performance mode..."
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo 0 > /proc/sys/kernel/nmi_watchdog
echo "Performance mode activated"
PERF_CMD

# Power saving mode command
cat > /usr/local/bin/writeros-powersave << 'POWER_CMD'
#!/bin/bash
# WriterOS power saving mode

echo "WriterOS: Activating power saving mode..."
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo 1 > /proc/sys/kernel/nmi_watchdog
echo "Power saving mode activated"
POWER_CMD

# Writing focus mode (distraction-free environment)
cat > /usr/local/bin/writeros-focus << 'FOCUS_CMD'
#!/bin/bash
# WriterOS writing focus mode

echo "WriterOS: Activating writing focus mode..."

# Stop unnecessary services
systemctl stop NetworkManager 2>/dev/null
systemctl stop bluetooth 2>/dev/null

# CPU power saving mode
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Adjust screen brightness (battery saving)
if [ -f /sys/class/backlight/*/brightness ]; then
    current=$(cat /sys/class/backlight/*/brightness)
    max=$(cat /sys/class/backlight/*/max_brightness)
    target=$((max * 60 / 100))  # Set to 60%
    echo $target > /sys/class/backlight/*/brightness
fi

# Launch Neovim
cd /home/writeros
su - writeros -c "DISPLAY=:0 nvim"
FOCUS_CMD

# Set execution permissions
chmod +x /usr/local/bin/writeros-*

# Add sudoers permissions (password-free power management)
cat >> /etc/sudoers << 'SUDOERS_APPEND'

# WriterOS custom commands permissions
writeros ALL=(ALL) NOPASSWD: /usr/local/bin/writeros-*
writeros ALL=(ALL) NOPASSWD: /bin/systemctl suspend
writeros ALL=(ALL) NOPASSWD: /bin/systemctl poweroff
writeros ALL=(ALL) NOPASSWD: /bin/systemctl reboot
SUDOERS_APPEND

echo "=== WriterOS Custom Commands Installation Completed ==="
EOF

chmod +x config/hooks/live/0050-writeros-commands.hook.chroot
```

## Step 3: Optimized Build Execution

### Final Configuration Check Before Build
```bash
# Check configuration files
cd ~/writeros-build/amd64

# Check package lists
cat config/package-lists/writeros-base.list.chroot

# Check hook scripts
ls -la config/hooks/live/

# Check bootloader configuration
cat config/bootloaders/syslinux/live.cfg.in
```

### Execute Optimized Build
```bash
# Clean previous build
sudo lb clean

# New build while keeping cache
echo "=== WriterOS Optimized Build Started ==="
time sudo lb build

# Monitor build progress while measuring time
```

**Expected Build Time**: 20-40 minutes (with cache)

### Build Result Analysis
```bash
# Analyze after build completion
ls -lah *.iso

# Compare ISO size (with previous version)
du -h live-image-amd64.hybrid.iso

# Target: Under 800MB
# Expected: 700-900MB

# Check ISO contents
mkdir -p /tmp/iso-mount
sudo mount -o loop live-image-amd64.hybrid.iso /tmp/iso-mount
ls -la /tmp/iso-mount/
sudo umount /tmp/iso-mount
```

## Step 4: 성능 테스트 및 벤치마크

### QEMU 부팅 시간 테스트
```bash
# 부팅 시간 측정 스크립트 생성
cat > test-boot-time.sh << 'BOOT_TEST'
#!/bin/bash

echo "WriterOS 부팅 시간 테스트..."

# QEMU에서 부팅 시간 측정
start_time=$(date +%s.%N)

timeout 180 qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom live-image-amd64.hybrid.iso \
    -boot d \
    -nographic \
    -serial mon:stdio \
    -append "console=ttyS0 boot=live components quiet loglevel=0" &

qemu_pid=$!

# 로그인 프롬프트 대기
while true; do
    sleep 1
    if kill -0 $qemu_pid 2>/dev/null; then
        if timeout 1 echo "" | nc localhost 1234 2>/dev/null; then
            end_time=$(date +%s.%N)
            boot_time=$(echo "$end_time - $start_time" | bc)
            echo "부팅 시간: $boot_time 초"
            kill $qemu_pid
            break
        fi
    else
        echo "QEMU 프로세스 종료됨"
        break
    fi
done
BOOT_TEST

chmod +x test-boot-time.sh
./test-boot-time.sh
```

### 메모리 사용량 테스트
```bash
# 메모리 사용량 프로파일링
qemu-system-x86_64 \
    -m 1024 \
    -cdrom live-image-amd64.hybrid.iso \
    -boot d \
    -nographic \
    -monitor telnet::4444,server,nowait \
    -append "console=ttyS0 boot=live components"

# 다른 터미널에서 모니터링
echo "info memory" | nc localhost 4444
```

### 디스크 I/O 성능 테스트
```bash
# QEMU에서 가상 하드디스크 생성하여 I/O 테스트
qemu-img create -f qcow2 test-disk.qcow2 1G

qemu-system-x86_64 \
    -m 2048 \
    -cdrom live-image-amd64.hybrid.iso \
    -hda test-disk.qcow2 \
    -boot d \
    -nographic \
    -append "console=ttyS0 boot=live components"

# 부팅 후 hdparm으로 성능 테스트
# hdparm -tT /dev/sda
```

## Step 5: 실제 하드웨어 테스트 준비

### USB 부팅 이미지 생성 (Windows에서)
```bash
# WSL2에서 Windows 파일 시스템으로 ISO 복사
cp live-image-amd64.hybrid.iso /mnt/c/Users/$USER/Desktop/WriterOS-v1.0-amd64.iso

echo "ISO 파일이 Windows 데스크톱에 복사됨"
echo "다음 단계:"
echo "1. Rufus 또는 Balena Etcher 다운로드"
echo "2. 8GB+ USB 드라이브 준비"
echo "3. ISO를 USB에 굽기"
echo "4. ASUS 제피로스 G14에서 부팅 테스트"
```

### 실제 하드웨어 테스트 체크리스트
```bash
# 테스트할 항목들
cat > hardware-test-checklist.md << 'TEST_LIST'
# WriterOS AMD64 하드웨어 테스트 체크리스트

## ASUS 제피로스 G14 (2021) 테스트

### 부팅 테스트
- [ ] USB 부팅 성공
- [ ] 부팅 시간 8초 이하 달성
- [ ] 자동 로그인 작동
- [ ] Neovim 자동 실행

### 하드웨어 인식
- [ ] AMD Ryzen CPU 인식
- [ ] RTX 3060/3070 GPU 인식 (nouveau 드라이버)
- [ ] WiFi 연결 가능
- [ ] 키보드 백라이트 제어
- [ ] 터치패드 작동
- [ ] USB 포트 인식

### 한글 지원
- [ ] fcitx5 입력기 활성화
- [ ] 한글 입력 정상 작동
- [ ] 한글 폰트 렌더링 확인
- [ ] Neovim에서 한글 편집 가능

### 전력 관리
- [ ] 배터리 상태 표시
- [ ] CPU 클럭 조절 작동
- [ ] 서스펜드/리줌 기능
- [ ] TLP 전력 최적화 적용

### 성능 테스트
- [ ] 부팅 시간: ___초
- [ ] 메모리 사용량: ___MB (idle)
- [ ] CPU 사용률: ___%
- [ ] 배터리 지속 시간: ___시간

### 글쓰기 환경
- [ ] Neovim 정상 실행
- [ ] 글꼴 렌더링 최적화
- [ ] writeros-focus 명령어 작동
- [ ] 집중 모드 환경 확인

## 추가 테스트 (다른 하드웨어)
- [ ] ASUS PX13에서 테스트
- [ ] 일반 데스크톱에서 테스트
- [ ] 다른 노트북에서 호환성 확인
TEST_LIST

echo "하드웨어 테스트 체크리스트 생성 완료"
```

## Step 6: 문제 해결 및 디버깅

### 부팅 문제 해결
```bash
# 부팅 로그 확인을 위한 디버그 버전 빌드
sed -i 's/quiet loglevel=0/debug loglevel=7/g' config/bootloaders/syslinux/live.cfg.in

# 디버그 모드로 재빌드
sudo lb clean
sudo lb build

# 부팅 문제 발생 시 로그 수집 방법
```

### 성능 이슈 진단
```bash
# 시스템 분석 도구 추가
cat >> config/package-lists/writeros-debug.list.chroot << 'EOF'
# 디버깅 도구 (개발 버전에만 포함)
htop
iotop
nethogs
systemd-bootchart
bootchart2
powertop
cpufrequtils
EOF
```

### 로그 수집 스크립트
```bash
# 시스템 정보 수집 스크립트
cat > collect-system-info.sh << 'COLLECT_INFO'
#!/bin/bash

echo "WriterOS 시스템 정보 수집..."

mkdir -p ~/writeros-logs

# 기본 시스템 정보
uname -a > ~/writeros-logs/kernel.txt
lscpu > ~/writeros-logs/cpu.txt
lsmem > ~/writeros-logs/memory.txt
lsblk > ~/writeros-logs/storage.txt
lspci > ~/writeros-logs/pci.txt
lsusb > ~/writeros-logs/usb.txt

# 부팅 분석
systemd-analyze > ~/writeros-logs/boot-analyze.txt
systemd-analyze blame > ~/writeros-logs/boot-blame.txt
systemd-analyze critical-chain > ~/writeros-logs/boot-chain.txt

# 전력 관리
powertop --html=~/writeros-logs/powertop.html --time=30 &
tlp-stat > ~/writeros-logs/tlp-status.txt

# 메모리 사용량
free -h > ~/writeros-logs/memory-usage.txt
ps aux --sort=-%mem | head -20 > ~/writeros-logs/memory-top.txt

echo "로그 수집 완료: ~/writeros-logs/"
COLLECT_INFO

chmod +x collect-system-info.sh
```

## 📊 성능 목표 및 달성 확인

### 목표 성능 지표
```
🎯 WriterOS AMD64 성능 목표:

부팅 시간: 8초 이하
메모리 사용: 400MB 이하 (idle)
배터리 지속: 6-8시간 (글쓰기 작업)
서스펜드/리줌: 1-2초
ISO 크기: 800MB 이하
```

### 성능 측정 스크립트
```bash
# 성능 벤치마크 스크립트
cat > benchmark-writeros.sh << 'BENCHMARK'
#!/bin/bash

echo "=== WriterOS 성능 벤치마크 ==="

# 부팅 시간 (systemd-analyze 사용)
boot_time=$(systemd-analyze | grep "Startup finished" | grep -o '[0-9.]*s' | tail -1)
echo "부팅 시간: $boot_time"

# 메모리 사용량
memory_used=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
memory_mb=$(free -m | awk 'NR==2{print $3}')
echo "메모리 사용량: ${memory_mb}MB ($memory_used)"

# CPU 사용률 (1분 평균)
cpu_usage=$(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
echo "CPU 사용률: $cpu_usage"

# 디스크 사용량
disk_usage=$(df -h / | awk 'NR==2{print $5}')
echo "디스크 사용량: $disk_usage"

# Neovim 시작 시간
nvim_start=$(time (nvim --headless -c 'quit' 2>&1) 2>&1 | grep real | awk '{print $2}')
echo "Neovim 시작 시간: $nvim_start"

echo "=== 벤치마크 완료 ==="
BENCHMARK

chmod +x benchmark-writeros.sh
```

## 📚 다음 단계

AMD64 프로토타입이 성공적으로 완료되면:

1. **[ARM64 크로스 컴파일 테스트](04-arm64-cross-compile.md)** - Surface Pro X 지원
2. **고급 최적화** - 부트 시간 단축, 메모리 최적화
3. **GUI 환경 개발** - 글쓰기 전용 인터페이스
4. **패키지 관리자** - WriterOS 전용 앱 스토어

## 🎉 완료 확인

다음이 모두 성공하면 AMD64 프로토타입 완료:

```bash
# 1. 빌드 성공 확인
ls -lah ~/writeros-build/amd64/*.iso

# 2. 크기 확인 (800MB 이하)
du -h ~/writeros-build/amd64/*.iso

# 3. QEMU 부팅 테스트
./test-boot-time.sh

# 4. 성능 벤치마크
./benchmark-writeros.sh

# 5. 시스템 정보 수집
./collect-system-info.sh
```

**WriterOS AMD64 프로토타입이 완성되었습니다! 이제 실제 하드웨어에서 테스트해보세요! 🚀**

---
*이 문서는 WriterOS AMD64 프로토타입 빌드를 위한 상세 가이드입니다.* 
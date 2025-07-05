# ARM64 크로스 컴파일 테스트

Surface Pro X(ARM64) 타겟을 위한 WriterOS ARM64 버전 빌드와 크로스 컴파일 환경을 구축합니다.

## 📋 사전 준비사항

### 확인해야 할 것들
- ✅ AMD64 프로토타입 빌드 완료 ([03-first-prototype-amd64.md](03-first-prototype-amd64.md) 참고)
- ✅ ARM64 크로스 컴파일 도구 설치 완료
- ✅ QEMU ARM64 에뮬레이션 활성화 확인
- ✅ 디스크 여유 공간 20GB+ (ARM64 빌드용)

### 크로스 컴파일 환경 확인
```bash
# ARM64 크로스 컴파일러 확인
aarch64-linux-gnu-gcc --version

# QEMU ARM64 에뮬레이션 확인
update-binfmts --display qemu-aarch64

# 빌드 디렉토리 구조 확인
ls -la ~/writeros-build/
# amd64/ arm64/ common/ 디렉토리가 있어야 함
```

## Step 1: ARM64 빌드 환경 초기화

### ARM64 Live Build 프로젝트 생성
```bash
# ARM64 빌드 디렉토리로 이동
cd ~/writeros-build/arm64

# Live Build ARM64 프로젝트 초기화
lb config \
    --architectures arm64 \
    --distribution bookworm \
    --archive-areas "main contrib non-free non-free-firmware" \
    --linux-flavours arm64 \
    --bootappend-live "boot=live components quiet splash" \
    --bootloader grub-efi \
    --binary-images iso-hybrid \
    --firmware-chroot true \
    --firmware-binary true \
    --cache-packages true \
    --cache-stages true

# 생성된 설정 확인
ls -la
```

**ARM64 vs AMD64 차이점**:
```diff
- --linux-flavours amd64        + --linux-flavours arm64
- --bootloader syslinux          + --bootloader grub-efi
                                 + --firmware-chroot true
                                 + --firmware-binary true
```

### ARM64 전용 커널 설정
```bash
# ARM64 커널 부트 파라미터 설정
cat > config/bootloaders/grub-efi/grub.cfg << 'GRUB_ARM64'
if loadfont $prefix/fonts/unicode.pf2 ; then
  set gfxmode=auto
  set locale_dir=$prefix/locale
  set lang=en_US
  insmod gfxterm
  insmod vbe
  insmod vga
  terminal_output gfxterm
fi

set default="0"
set timeout=5

menuentry "WriterOS ARM64 (Live)" {
    set gfxpayload=keep
    linux   /live/vmlinuz boot=live components nosplash quiet loglevel=0 rd.systemd.show_status=0 acpi=force
    initrd  /live/initrd.img
}

menuentry "WriterOS ARM64 (Safe Mode)" {
    linux   /live/vmlinuz boot=live components nosplash nomodeset acpi=off
    initrd  /live/initrd.img
}
GRUB_ARM64
```

## Step 2: ARM64 패키지 최적화

### ARM64 기본 패키지 목록
```bash
# ARM64 전용 패키지 목록 생성
cat > config/package-lists/writeros-arm64-base.list.chroot << 'EOF'
# ARM64 기본 시스템
live-boot
live-config
live-config-systemd

# ARM64 펌웨어 (Surface Pro X 지원)
firmware-linux
firmware-linux-nonfree
firmware-misc-nonfree

# 네트워킹 (ARM64 WiFi 지원)
network-manager
wireless-tools
wpasupplicant
firmware-iwlwifi
firmware-realtek

# 한글 지원 (동일)
fonts-noto-cjk
fonts-nanum
fcitx5
fcitx5-hangul
fcitx5-config-qt

# 에디터 (핵심!)
neovim
nano

# ARM64 최적화 유틸리티
cpufrequtils
lscpu
hwinfo

# X11 최소 환경 (ARM64 호환)
xserver-xorg-core
xinit
openbox
xterm

# 전력 관리 (ARM SoC 최적화)
acpi
acpid
tlp
powertop

# Surface Pro X 특화
libwacom-common
xserver-xorg-input-wacom
EOF
```

### Surface Pro X 전용 패키지
```bash
# Surface Pro X 하드웨어 지원 패키지
cat > config/package-lists/writeros-surface.list.chroot << 'EOF'
# Surface Pro X 하드웨어 지원
linux-image-arm64
linux-headers-arm64

# 터치 및 펜 지원
libinput-tools
xserver-xorg-input-libinput
libwacom-bin

# 카메라 및 센서
v4l-utils
iio-sensor-proxy

# Bluetooth (Surface 키보드/마우스)
bluez
bluez-tools

# 오디오 (ARM64 ALSA)
alsa-utils
pulseaudio
pulseaudio-module-bluetooth
EOF
```

## Step 3: ARM64 전용 최적화 설정

### ARM SoC 전력 관리 hook
```bash
# ARM64 전력 최적화 hook 생성
cat > config/hooks/live/0031-arm64-power-optimization.hook.chroot << 'EOF'
#!/bin/bash

echo "=== WriterOS ARM64 전력 관리 최적화 시작 ==="

# ARM64 전용 TLP 설정
cat > /etc/tlp.conf << 'TLP_ARM64_CONF'
# WriterOS ARM64 전력 최적화 설정

# ARM CPU 관리 (Qualcomm SQ1)
CPU_SCALING_GOVERNOR_ON_AC=ondemand
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# ARM64는 더 보수적인 설정
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=80
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=20

# 디스크 (Surface Pro X SSD)
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
DISK_SPINDOWN_TIMEOUT_ON_AC="0 0"
DISK_SPINDOWN_TIMEOUT_ON_BAT="30 30"

# WiFi 전력 절약 (더 공격적)
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# USB 자동 서스펜드 (Surface 주변기기 고려)
USB_AUTOSUSPEND=1
USB_BLACKLIST_PHONE=1
USB_BLACKLIST_WWAN=1

# ARM64 특화 설정
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power
TLP_ARM64_CONF

# ARM64 전용 governor 설정
cat > /etc/systemd/system/arm64-governor.service << 'ARM64_GOV_SERVICE'
[Unit]
Description=ARM64 CPU Governor Optimization
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=true

# ARM64 CPU 주파수 설정
ExecStart=/bin/sh -c 'echo ondemand > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
ExecStart=/bin/sh -c 'echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold'
ExecStart=/bin/sh -c 'echo 1 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor'

# ARM64 thermal 최적화
ExecStart=/bin/sh -c 'echo 1 > /sys/class/thermal/thermal_zone*/passive'

[Install]
WantedBy=multi-user.target
ARM64_GOV_SERVICE

systemctl enable arm64-governor

echo "=== WriterOS ARM64 전력 관리 최적화 완료 ==="
EOF

chmod +x config/hooks/live/0031-arm64-power-optimization.hook.chroot
```

### Surface Pro X 하드웨어 설정 hook
```bash
# Surface Pro X 특화 설정 hook
cat > config/hooks/live/0041-surface-hardware.hook.chroot << 'EOF'
#!/bin/bash

echo "=== Surface Pro X 하드웨어 설정 시작 ==="

# Surface Pro X 터치 설정
cat > /etc/X11/xorg.conf.d/40-libinput.conf << 'LIBINPUT_CONF'
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingDrag" "on"
    Option "DisableWhileTyping" "on"
    Option "AccelProfile" "adaptive"
    Option "AccelSpeed" "0.3"
EndSection

Section "InputClass"
    Identifier "libinput touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
LIBINPUT_CONF

# Surface 펜 설정
cat > /etc/X11/xorg.conf.d/50-wacom.conf << 'WACOM_CONF'
Section "InputClass"
    Identifier "Wacom USB device class"
    MatchUSBID "056a:*"
    MatchDevicePath "/dev/input/event*"
    Driver "wacom"
EndSection

Section "InputClass"
    Identifier "Wacom PnP device class"
    MatchPnPID "WACf*|WCOM*|WACM*|FUJ*"
    MatchDevicePath "/dev/input/event*"
    Driver "wacom"
EndSection
WACOM_CONF

# 화면 회전 및 터치 보정 스크립트
cat > /usr/local/bin/surface-orientation << 'SURFACE_ORIENT'
#!/bin/bash
# Surface Pro X 화면 회전 감지 및 자동 보정

DISPLAY=:0

# 센서에서 방향 읽기
orientation=$(cat /sys/class/hwmon/hwmon*/device/in_accel_scale 2>/dev/null | head -1)

case "$orientation" in
    "1") 
        xrandr --output DSI-1 --rotate normal
        xinput map-to-output "pointer:Microsoft Surface" DSI-1
        ;;
    "2") 
        xrandr --output DSI-1 --rotate left
        xinput map-to-output "pointer:Microsoft Surface" DSI-1
        ;;
    "3") 
        xrandr --output DSI-1 --rotate inverted
        xinput map-to-output "pointer:Microsoft Surface" DSI-1
        ;;
    "4") 
        xrandr --output DSI-1 --rotate right
        xinput map-to-output "pointer:Microsoft Surface" DSI-1
        ;;
esac
SURFACE_ORIENT

chmod +x /usr/local/bin/surface-orientation

# Surface 키보드 설정
cat > /home/writeros/.config/autostart/surface-keyboard.desktop << 'SURFACE_KB'
[Desktop Entry]
Type=Application
Name=Surface Keyboard Layout
Exec=/bin/sh -c 'setxkbmap -layout us -variant ,, -option grp:alt_shift_toggle'
Icon=preferences-desktop-keyboard
Terminal=false
Categories=System;
StartupNotify=false
NoDisplay=true
SURFACE_KB

chown -R writeros:writeros /home/writeros/.config

echo "=== Surface Pro X 하드웨어 설정 완료 ==="
EOF

chmod +x config/hooks/live/0041-surface-hardware.hook.chroot
```

### ARM64 성능 최적화 명령어
```bash
# ARM64 전용 명령어들 추가
cat > config/hooks/live/0051-writeros-arm64-commands.hook.chroot << 'EOF'
#!/bin/bash

echo "=== WriterOS ARM64 전용 명령어 설치 시작 ==="

# ARM64 성능 모니터링 명령어
cat > /usr/local/bin/writeros-arm64-status << 'ARM64_STATUS'
#!/bin/bash
# WriterOS ARM64 시스템 상태

echo "=== WriterOS ARM64 시스템 상태 ==="

# CPU 정보
echo "CPU 정보:"
lscpu | grep -E "(Architecture|CPU|Core|Thread|MHz)"

# 온도 상태
echo -e "\n온도 상태:"
if [ -d /sys/class/thermal ]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -f "$zone/temp" ]; then
            name=$(cat "$zone/type" 2>/dev/null || echo "Unknown")
            temp=$(cat "$zone/temp")
            temp_c=$((temp / 1000))
            echo "$name: ${temp_c}°C"
        fi
    done
fi

# 배터리 상태
echo -e "\n배터리 상태:"
if [ -d /sys/class/power_supply/BAT* ]; then
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/capacity" ]; then
            capacity=$(cat "$bat/capacity")
            status=$(cat "$bat/status")
            echo "배터리: ${capacity}% ($status)"
        fi
    done
fi

# 메모리 사용량
echo -e "\n메모리 사용량:"
free -h

# 스토리지 상태
echo -e "\n스토리지:"
df -h / /tmp 2>/dev/null

echo "=== 상태 확인 완료 ==="
ARM64_STATUS

# ARM64 터치 보정 명령어
cat > /usr/local/bin/writeros-touch-calibrate << 'TOUCH_CAL'
#!/bin/bash
# WriterOS ARM64 터치 보정

echo "WriterOS: 터치스크린 보정 시작..."

# 터치 디바이스 찾기
touch_device=$(xinput list | grep -i touch | head -1 | sed 's/.*id=\([0-9]*\).*/\1/')

if [ -n "$touch_device" ]; then
    echo "터치 디바이스 ID: $touch_device"
    
    # 기본 터치 설정 적용
    xinput set-prop "$touch_device" "libinput Tapping Enabled" 1
    xinput set-prop "$touch_device" "libinput Natural Scrolling Enabled" 0
    
    echo "터치 보정 완료"
else
    echo "터치 디바이스를 찾을 수 없습니다"
fi
TOUCH_CAL

# Surface 키보드 연결 명령어
cat > /usr/local/bin/writeros-surface-connect << 'SURFACE_CONNECT'
#!/bin/bash
# Surface 키보드/마우스 연결

echo "WriterOS: Surface 키보드 연결 확인..."

# Bluetooth 서비스 시작
systemctl start bluetooth

# 알려진 Surface 디바이스 연결 시도
bluetooth_devices=(
    "Surface Keyboard"
    "Surface Mouse"
    "Surface Pen"
)

for device in "${bluetooth_devices[@]}"; do
    echo "연결 시도: $device"
    # bluetoothctl로 연결 시도 (실제 MAC 주소는 페어링 후 저장됨)
done

echo "Bluetooth 디바이스 검색 완료"
SURFACE_CONNECT

# 실행 권한 부여
chmod +x /usr/local/bin/writeros-arm64-*
chmod +x /usr/local/bin/writeros-touch-*
chmod +x /usr/local/bin/writeros-surface-*

echo "=== WriterOS ARM64 전용 명령어 설치 완료 ==="
EOF

chmod +x config/hooks/live/0051-writeros-arm64-commands.hook.chroot
```

## Step 4: ARM64 빌드 실행

### 빌드 전 설정 확인
```bash
# ARM64 빌드 설정 최종 확인
cd ~/writeros-build/arm64

# 아키텍처 확인
grep "LB_ARCHITECTURES" config/common
# LB_ARCHITECTURES="arm64"

# 패키지 목록 확인
ls config/package-lists/
cat config/package-lists/writeros-arm64-base.list.chroot

# hook 스크립트 확인
ls -la config/hooks/live/
```

### ARM64 빌드 실행 (크로스 컴파일)
```bash
# ARM64 빌드 시작 (시간이 오래 걸림: 1-2시간)
echo "=== WriterOS ARM64 빌드 시작 ==="
echo "예상 시간: 1-2시간 (크로스 컴파일)"

# 빌드 시작 시간 기록
start_time=$(date)
echo "시작 시간: $start_time"

# 실제 빌드 실행
time sudo lb build

# 빌드 완료 시간 기록
end_time=$(date)
echo "완료 시간: $end_time"
```

**ARM64 빌드 과정**:
```
1. bootstrap (ARM64) - Debian ARM64 기본 시스템 다운로드
2. chroot (에뮬레이션) - QEMU로 ARM64 환경에서 패키지 설치
3. binary (ARM64) - ARM64 ISO 이미지 생성
```

### 빌드 진행 상황 모니터링
```bash
# 다른 터미널에서 모니터링
watch -n 30 'echo "=== 빌드 진행 상황 ===" && \
            du -sh ~/writeros-build/arm64 && \
            echo "프로세스:" && \
            ps aux | grep -E "(lb|debootstrap|chroot)" | grep -v grep && \
            echo "메모리 사용량:" && \
            free -h && \
            ls -la ~/writeros-build/arm64/*.iso 2>/dev/null || echo "ISO 생성 대기 중..."'
```

## Step 5: ARM64 빌드 결과 확인

### 빌드 성공 확인
```bash
# 빌드 완료 후 결과 확인
cd ~/writeros-build/arm64

# 생성된 파일들 확인
ls -lah *.iso

# 예상 출력:
# -rw-r--r-- 1 root root 920M 날짜 시간 live-image-arm64.hybrid.iso

# 파일 정보 확인
file live-image-arm64.hybrid.iso
# live-image-arm64.hybrid.iso: ISO 9660 CD-ROM filesystem data

# 크기 비교 (AMD64 vs ARM64)
echo "ARM64 ISO 크기:"
du -h live-image-arm64.hybrid.iso
echo "AMD64 ISO 크기 (비교):"
du -h ../amd64/live-image-amd64.hybrid.iso 2>/dev/null || echo "AMD64 빌드 없음"
```

### ISO 내용 분석
```bash
# ISO 마운트하여 내용 확인
mkdir -p /tmp/arm64-iso-mount
sudo mount -o loop live-image-arm64.hybrid.iso /tmp/arm64-iso-mount

# ARM64 커널 확인
ls -la /tmp/arm64-iso-mount/live/
file /tmp/arm64-iso-mount/live/vmlinuz
# /tmp/arm64-iso-mount/live/vmlinuz: Linux kernel ARM64 boot executable Image

# initrd 확인
file /tmp/arm64-iso-mount/live/initrd.img

# 마운트 해제
sudo umount /tmp/arm64-iso-mount
```

## Step 6: ARM64 에뮬레이션 테스트

### QEMU ARM64 부팅 테스트
```bash
# ARM64 QEMU 에뮬레이션 준비
sudo apt install -y qemu-system-arm qemu-efi-aarch64

# UEFI 펌웨어 복사
cp /usr/share/qemu-efi-aarch64/QEMU_EFI.fd ./

# ARM64 부팅 테스트
qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 2048 \
    -bios QEMU_EFI.fd \
    -cdrom live-image-arm64.hybrid.iso \
    -boot d \
    -nographic \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-scsi-pci \
    -device scsi-cd,drive=cd0 \
    -drive file=live-image-arm64.hybrid.iso,id=cd0,if=none,media=cdrom
```

### ARM64 부팅 시간 측정
```bash
# ARM64 부팅 시간 측정 스크립트
cat > test-arm64-boot-time.sh << 'ARM64_BOOT_TEST'
#!/bin/bash

echo "WriterOS ARM64 부팅 시간 테스트..."

# QEMU ARM64에서 부팅 시간 측정
start_time=$(date +%s.%N)

timeout 300 qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 2048 \
    -bios QEMU_EFI.fd \
    -cdrom live-image-arm64.hybrid.iso \
    -boot d \
    -nographic \
    -append "console=ttyAMA0 boot=live components quiet" &

qemu_pid=$!

# 부팅 완료 대기 (ARM64는 더 오래 걸림)
echo "ARM64 부팅 대기 중... (최대 5분)"
sleep 60  # ARM64는 부팅이 느림

end_time=$(date +%s.%N)
boot_time=$(echo "$end_time - $start_time" | bc -l)
echo "ARM64 부팅 시간: $boot_time 초"

# QEMU 종료
kill $qemu_pid 2>/dev/null

echo "ARM64 부팅 테스트 완료"
ARM64_BOOT_TEST

chmod +x test-arm64-boot-time.sh
```

### 성능 비교 분석
```bash
# AMD64 vs ARM64 성능 비교
cat > compare-architectures.sh << 'ARCH_COMPARE'
#!/bin/bash

echo "=== WriterOS 아키텍처별 성능 비교 ==="

# ISO 크기 비교
echo "1. ISO 파일 크기:"
echo "AMD64: $(du -h ../amd64/live-image-amd64.hybrid.iso 2>/dev/null | cut -f1 || echo 'N/A')"
echo "ARM64: $(du -h live-image-arm64.hybrid.iso | cut -f1)"

# 빌드 시간 비교 (로그에서)
echo -e "\n2. 빌드 시간:"
echo "AMD64: ~20-40분 (캐시 사용시)"
echo "ARM64: ~60-120분 (크로스 컴파일)"

# 예상 부팅 시간
echo -e "\n3. 예상 부팅 시간:"
echo "AMD64 (네이티브): 8-15초"
echo "ARM64 (에뮬레이션): 30-60초"
echo "ARM64 (실제 하드웨어): 10-20초 예상"

# 타겟 하드웨어
echo -e "\n4. 타겟 하드웨어:"
echo "AMD64: ASUS 제피로스 G14 (2021)"
echo "ARM64: Surface Pro X (SQ1)"

echo -e "\n=== 비교 완료 ==="
ARCH_COMPARE

chmod +x compare-architectures.sh
./compare-architectures.sh
```

## Step 7: Surface Pro X 실제 테스트 준비

### ARM64 ISO를 Windows로 복사
```bash
# WSL2에서 Windows로 ARM64 ISO 복사
cp live-image-arm64.hybrid.iso /mnt/c/Users/$USER/Desktop/WriterOS-v1.0-arm64.iso

echo "ARM64 ISO 파일이 Windows 데스크톱에 복사됨"
echo "파일명: WriterOS-v1.0-arm64.iso"
```

### Surface Pro X 부팅 테스트 가이드
```bash
# Surface Pro X 테스트 가이드 생성
cat > surface-pro-x-test-guide.md << 'SURFACE_GUIDE'
# Surface Pro X에서 WriterOS ARM64 테스트 가이드

## 사전 준비
1. **16GB+ USB 드라이브** 준비
2. **Rufus** 또는 **Balena Etcher** 다운로드
3. **Surface Pro X 백업** (중요한 데이터)

## USB 부팅 디스크 생성
1. Rufus 실행
2. **디바이스**: USB 드라이브 선택
3. **부트 선택**: WriterOS-v1.0-arm64.iso 선택
4. **파티션 방식**: GPT
5. **대상 시스템**: UEFI (non CSM)
6. **시작** 클릭

## Surface Pro X BIOS/UEFI 설정
1. **전원 + 볼륨 UP** 동시 누르며 부팅
2. **Security** → **Secure Boot** 비활성화
3. **Boot** → **USB Boot** 활성화
4. **Exit** → **Save and Exit**

## 부팅 테스트
1. USB 연결 후 재부팅
2. **볼륨 DOWN** 누르며 부팅 (부팅 메뉴)
3. USB 드라이브 선택
4. GRUB 메뉴에서 "WriterOS ARM64 (Live)" 선택

## 테스트 체크리스트
### 하드웨어 인식
- [ ] 부팅 성공
- [ ] 터치스크린 작동
- [ ] Surface 펜 인식
- [ ] WiFi 연결 가능
- [ ] 키보드 (Type Cover) 인식
- [ ] 터치패드 작동
- [ ] 카메라 인식

### 성능 테스트  
- [ ] 부팅 시간: ___초
- [ ] 메모리 사용량: ___MB
- [ ] CPU 온도: ___°C
- [ ] 배터리 수명 테스트

### 글쓰기 환경
- [ ] Neovim 실행
- [ ] 한글 입력 (fcitx5)
- [ ] 터치 키보드 (필요시)
- [ ] 글꼴 렌더링 품질

### WriterOS 기능
- [ ] writeros-arm64-status 명령어
- [ ] writeros-touch-calibrate 실행
- [ ] writeros-surface-connect 테스트
- [ ] 전력 관리 확인

## 문제 해결
### 부팅 실패시
1. **Safe Mode** 선택
2. **nomodeset acpi=off** 파라미터 추가
3. **로그 확인**: dmesg | tail -50

### 터치 문제시
1. **xinput list** 로 디바이스 확인
2. **writeros-touch-calibrate** 실행
3. **X11 로그 확인**: ~/.local/share/xorg/Xorg.0.log

## 성능 벤치마크
```bash
# Surface Pro X에서 실행할 벤치마크
writeros-arm64-status
systemd-analyze
free -h
df -h
cpufreq-info
```

## 로그 수집
문제 발생시 다음 로그들을 수집:
- dmesg
- systemd journal
- Xorg 로그
- 성능 데이터
SURFACE_GUIDE

echo "Surface Pro X 테스트 가이드 생성 완료"
```

## Step 8: 크로스 컴파일 검증

### 간단한 ARM64 프로그램 테스트
```bash
# ARM64 크로스 컴파일 테스트
cat > test-arm64-program.c << 'ARM64_TEST_C'
#include <stdio.h>
#include <sys/utsname.h>
#include <unistd.h>

int main() {
    struct utsname info;
    uname(&info);
    
    printf("=== WriterOS ARM64 Test Program ===\n");
    printf("System: %s\n", info.sysname);
    printf("Release: %s\n", info.release);
    printf("Machine: %s\n", info.machine);
    printf("Hostname: %s\n", info.nodename);
    
    // CPU 정보
    long nprocs = sysconf(_SC_NPROCESSORS_ONLN);
    printf("CPU Cores: %ld\n", nprocs);
    
    // 페이지 크기 (ARM64 특성)
    long page_size = sysconf(_SC_PAGESIZE);
    printf("Page Size: %ld bytes\n", page_size);
    
    printf("WriterOS ARM64 is working!\n");
    return 0;
}
ARM64_TEST_C

# ARM64 크로스 컴파일
aarch64-linux-gnu-gcc -o test-arm64-program test-arm64-program.c

# 파일 확인 (ARM64 바이너리인지)
file test-arm64-program
# test-arm64-program: ELF 64-bit LSB executable, ARM aarch64

# QEMU로 실행 테스트
./test-arm64-program
# 자동으로 QEMU 에뮬레이션을 통해 실행됨
```

### 성능 벤치마크 ARM64 버전
```bash
# ARM64 성능 벤치마크 스크립트
cat > benchmark-writeros-arm64.sh << 'ARM64_BENCHMARK'
#!/bin/bash

echo "=== WriterOS ARM64 성능 벤치마크 ==="

# 아키텍처 확인
arch=$(uname -m)
echo "아키텍처: $arch"

if [ "$arch" != "aarch64" ]; then
    echo "경고: ARM64 환경이 아닙니다 (에뮬레이션 중)"
fi

# CPU 정보
echo -e "\nCPU 정보:"
lscpu | grep -E "Architecture|CPU|Core|Thread|MHz|Model name"

# 메모리 정보  
echo -e "\n메모리 사용량:"
free -h
echo "메모리 대역폭 테스트:"
dd if=/dev/zero of=/dev/null bs=1M count=1024 2>&1 | grep copied

# 스토리지 성능
echo -e "\n스토리지 성능:"
dd if=/dev/zero of=/tmp/test_write bs=1M count=100 conv=fsync 2>&1 | grep copied
rm -f /tmp/test_write

# 온도 모니터링 (ARM SoC)
echo -e "\n시스템 온도:"
if [ -d /sys/class/thermal ]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -f "$zone/temp" ]; then
            name=$(cat "$zone/type" 2>/dev/null || echo "Unknown")
            temp=$(cat "$zone/temp")
            temp_c=$((temp / 1000))
            echo "$name: ${temp_c}°C"
        fi
    done
fi

# 전력 상태
echo -e "\n전력 상태:"
if [ -f /sys/class/power_supply/BAT*/capacity ]; then
    echo "배터리: $(cat /sys/class/power_supply/BAT*/capacity)%"
fi

# ARM64 특화 테스트
echo -e "\nARM64 특화 정보:"
echo "Endianness: $(lscpu | grep "Byte Order")"
echo "Virtualization: $(lscpu | grep Virtualization || echo "Not supported")"

echo -e "\n=== ARM64 벤치마크 완료 ==="
ARM64_BENCHMARK

chmod +x benchmark-writeros-arm64.sh

# ARM64로 크로스 컴파일
aarch64-linux-gnu-gcc -static -o benchmark-writeros-arm64-static benchmark-writeros-arm64.sh
```

## 📊 ARM64 성능 목표

### Surface Pro X 타겟 성능
```
🎯 WriterOS ARM64 (Surface Pro X) 성능 목표:

부팅 시간: 10초 이하 (실제 하드웨어)
메모리 사용: 350MB 이하 (idle)
배터리 지속: 10-12시간 (글쓰기 작업)
서스펜드/리줌: 2-3초
ISO 크기: 900MB 이하
온도: 40°C 이하 (idle)
```

### AMD64 vs ARM64 비교표
```bash
# 성능 비교표 생성
cat > architecture-comparison.md << 'ARCH_COMPARISON'
# WriterOS 아키텍처별 성능 비교

| 항목 | AMD64 (ASUS G14) | ARM64 (Surface Pro X) |
|------|------------------|----------------------|
| **부팅 시간** | 8초 이하 | 10초 이하 |
| **메모리 사용** | 400MB 이하 | 350MB 이하 |
| **배터리 수명** | 6-8시간 | 10-12시간 |
| **서스펜드/리줌** | 1-2초 | 2-3초 |
| **ISO 크기** | 800MB 이하 | 900MB 이하 |
| **CPU 성능** | 높음 | 중간 |
| **전력 효율** | 중간 | 높음 |
| **발열** | 중간 | 낮음 |
| **펜 지원** | ❌ | ✅ |
| **터치** | ❌ | ✅ |
| **휴대성** | 중간 | 높음 |

## 최적 사용 케이스

### AMD64 (ASUS G14)
- 집중적인 글쓰기 작업
- 성능이 중요한 작업
- 외부 모니터 연결
- 개발 작업

### ARM64 (Surface Pro X)  
- 이동 중 글쓰기
- 장시간 배터리 사용
- 터치/펜 입력 활용
- 조용한 환경 (팬 소음 없음)
ARCH_COMPARISON

echo "아키텍처 비교표 생성 완료"
```

## 📚 다음 단계

ARM64 크로스 컴파일이 성공적으로 완료되면:

1. **실제 하드웨어 테스트** - Surface Pro X에서 실제 부팅
2. **성능 최적화** - ARM64 특화 튜닝
3. **하드웨어 드라이버** - Surface 펜, 터치 완전 지원
4. **배터리 최적화** - 12시간+ 목표 달성

## 🎉 완료 확인

다음이 모두 성공하면 ARM64 크로스 컴파일 완료:

```bash
# 1. ARM64 빌드 성공 확인
ls -lah ~/writeros-build/arm64/*.iso

# 2. 파일 형식 확인 (ARM64)
file ~/writeros-build/arm64/live-image-arm64.hybrid.iso

# 3. QEMU 부팅 테스트
./test-arm64-boot-time.sh

# 4. 크로스 컴파일 검증
./test-arm64-program

# 5. 성능 벤치마크
./benchmark-writeros-arm64.sh

# 6. Windows로 복사 확인
ls -la /mnt/c/Users/$USER/Desktop/WriterOS-v1.0-arm64.iso
```

**WriterOS ARM64 크로스 컴파일이 완성되었습니다! 이제 Surface Pro X에서 테스트해보세요! 🚀**

---
*이 문서는 WriterOS ARM64 크로스 컴파일 환경 구축을 위한 상세 가이드입니다.* 
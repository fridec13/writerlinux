# Live + Installer 복합형 WriterOS 구축 가이드

Live Build 환경에서 "Try WriterOS" + "Install WriterOS" 옵션을 모두 제공하는 Ubuntu 스타일의 복합형 ISO를 구축합니다.

## 📋 사전 준비사항

### 확인해야 할 것들
- ✅ WSL2 + Debian 환경 구축 완료 ([01-wsl2-setup.md](01-wsl2-setup.md) 참고)
- ✅ Live Build 기본 환경 구축 완료 ([02-live-build-setup.md](02-live-build-setup.md) 참고)
- ✅ Live-only 모드 빌드 경험 (권장)
- ✅ 디스크 여유 공간 최소 15GB (Installer 포함으로 용량 증가)

### 시스템 요구사항
```bash
# Live + Installer 모드 요구사항
df -h ~          # 디스크 공간 (15GB+ 필요)
free -h          # 메모리 (6GB+ 권장)
nproc            # CPU 코어 수 (멀티코어 필수)
```

## 🎯 Live + Installer 모드의 장점

### Ubuntu Desktop 스타일 사용자 경험
```bash
# 부팅 후 사용자 선택
1. Try WriterOS (Live System)     ← 바로 체험
2. Install WriterOS               ← 영구 설치
```

### 실제 사용 시나리오
- **체험**: USB로 부팅해서 WriterOS 글쓰기 환경 체험
- **설치**: 만족하면 하드드라이브에 영구 설치 (듀얼부팅 지원)
- **포터블**: 설치 없이도 언제든 USB로 사용 가능

## Step 1: Live + Installer 환경 설정

### 기존 Live-only 설정 정리
```bash
# 기존 빌드 디렉토리 완전 정리
cd ~/writeros-build/amd64
sudo lb clean --purge
rm -rf auto/ config/ .build/ local/ cache/ chroot*

# 새로운 시작을 위한 확인
ls -la  # 빈 디렉토리여야 함
```

### Live + Installer 모드 초기화
```bash
# 복합형 Live Build 프로젝트 초기화
lb config \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main contrib non-free non-free-firmware" \
    --linux-flavours amd64 \
    --bootappend-live "boot=live components quiet splash locales=ko_KR.UTF-8" \
    --bootloader syslinux \
    --binary-images iso-hybrid \
    --cache-packages true \
    --cache-stages true \
    --debian-installer true \
    --debian-installer-gui true \
    --debian-installer-distribution bookworm \
    --iso-application "WriterOS" \
    --iso-publisher "WriterOS Project" \
    --iso-volume "WriterOS" \
    --win32-loader false

# 생성된 설정 구조 확인
ls -la config/
tree config/ -L 2
```

**생성되는 구조**:
```
config/
├── binary               # ISO 이미지 설정
├── bootstrap            # 기본 시스템 설정  
├── chroot              # 라이브 시스템 설정
├── common              # 공통 설정
├── source              # 소스 패키지 설정
└── includes.installer/ # Installer 전용 설정 (새로 추가됨)
```

## Step 2: 패키지 목록 구성

### 라이브 시스템용 패키지 목록
```bash
# 라이브 환경에서 실행될 패키지들
cat > config/package-lists/writeros-live.list.chroot << 'EOF'
# Live system essentials
live-boot
live-config
live-config-systemd

# Networking
network-manager
wireless-tools
wpasupplicant
avahi-daemon

# Korean language support
fonts-noto-cjk
fonts-nanum
fonts-nanum-coding
fcitx5
fcitx5-hangul
fcitx5-config-qt
fcitx5-frontend-gtk3
fcitx5-frontend-qt5

# Text editors and writing tools
neovim
nano
gedit
libreoffice-writer
libreoffice-calc

# Basic utilities
curl
wget
git
htop
tree
unzip
file
rsync
gparted

# Minimal desktop environment
xserver-xorg-core
xinit
openbox
obconf
tint2
pcmanfm
lxterminal
firefox-esr

# Media and graphics
pulseaudio
alsa-utils
feh
scrot

# Power management
tlp
tlp-rdw
acpi
acpid
powertop

# Development tools (optional)
build-essential
python3
python3-pip
nodejs
npm
EOF
```

### ⚠️ Installer 패키지는 자동 처리됨

Live Build에서 `--debian-installer true` 옵션을 사용하면 다음 패키지들이 **자동으로 처리**됩니다:

```bash
# ❌ 직접 설치하면 안 되는 udeb 패키지들 (Live Build가 자동 처리)
# debian-installer-utils  ← udeb 패키지
# hw-detect               ← udeb 패키지  
# partman-auto           ← udeb 패키지
# partman-ext3           ← udeb 패키지

# ✅ 라이브 시스템에 필요한 실제 패키지들은 live 목록에 포함됨
# parted, gparted, grub-pc, locales 등은 writeros-live.list.chroot에서 설치
```

**중요**: installer 전용 패키지 목록을 만들 필요가 없습니다. Live Build가 내부적으로 모든 debian-installer 컴포넌트를 처리합니다.

## Step 3: Installer 설정 파일

### Preseed 자동 설정 파일
```bash
# 설치 과정의 기본값 설정
mkdir -p config/includes.installer
cat > config/includes.installer/preseed.cfg << 'EOF'
# WriterOS Installer Preseed Configuration

# Locale and keyboard
d-i debian-installer/locale string ko_KR.UTF-8
d-i debian-installer/language string ko
d-i debian-installer/country string KR
d-i keyboard-configuration/xkb-keymap select kr
d-i keyboard-configuration/layoutcode string kr

# Network configuration
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string writeros
d-i netcfg/get_domain string local
d-i netcfg/wireless_wep string

# Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# Account setup
d-i passwd/root-login boolean false
d-i passwd/user-fullname string WriterOS User
d-i passwd/username string writeros
d-i passwd/user-password password writeros
d-i passwd/user-password-again password writeros
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

# Time zone
d-i time/zone string Asia/Seoul
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true

# Partitioning
d-i partman-auto/method string guided
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Base system installation
d-i base-installer/install-recommends boolean true
d-i base-installer/kernel/image string linux-image-amd64

# Package selection
tasksel tasksel/first multiselect standard, desktop
d-i pkgsel/include string neovim git curl htop firefox-esr libreoffice
d-i pkgsel/upgrade select full-upgrade
popularity-contest popularity-contest/participate boolean false

# Boot loader installation
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default

# Finishing up
d-i finish-install/reboot_in_progress note

# Custom commands
d-i preseed/late_command string \
    in-target systemctl enable tlp; \
    in-target systemctl disable bluetooth; \
    in-target update-grub
EOF
```

### 설치 후 스크립트
```bash
# 설치 완료 후 실행될 설정 스크립트
cat > config/includes.installer/post-install.sh << 'EOF'
#!/bin/bash

# WriterOS Post-Installation Setup

echo "=== WriterOS Post-Installation Started ==="

# Korean input method setup
mkdir -p /home/writeros/.config/fcitx5
cat > /home/writeros/.config/fcitx5/config << 'FCITX5_CONF'
[Hotkey]
TriggerKeys=
ActivateKeys=Hangul
[Hotkey/TriggerKeys]
0=Control+space
FCITX5_CONF

# Desktop environment setup
cat > /home/writeros/.xinitrc << 'XINITRC'
#!/bin/sh
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
fcitx5 &
exec openbox-session
XINITRC

# Openbox configuration
mkdir -p /home/writeros/.config/openbox
cat > /home/writeros/.config/openbox/autostart << 'AUTOSTART'
tint2 &
pcmanfm --desktop &
fcitx5 &
AUTOSTART

# Set correct ownership
chown -R writeros:writeros /home/writeros/

# Enable auto-login for installed system
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'CONF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin writeros --noclear %I $TERM
CONF

echo "=== WriterOS Post-Installation Completed ==="
EOF

chmod +x config/includes.installer/post-install.sh
```

## Step 4: 라이브 시스템 Hook 설정

### 기본 시스템 설정 Hook
```bash
# 라이브 환경에서 실행될 설정
mkdir -p config/hooks/live
cat > config/hooks/live/0010-writeros-live-setup.hook.chroot << 'EOF'
#!/bin/bash

echo "=== WriterOS Live System Setup Started ==="

# Create WriterOS user for live session
useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev writeros
echo "writeros:writeros" | chpasswd

# Auto login for live session only
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'CONF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin writeros --noclear %I $TERM
CONF

# Korean input method setup
mkdir -p /home/writeros/.config/fcitx5
cat > /home/writeros/.config/fcitx5/config << 'FCITX5_CONF'
[Hotkey]
TriggerKeys=
ActivateKeys=Hangul
[Hotkey/TriggerKeys]
0=Control+space
FCITX5_CONF

# Desktop environment configuration
mkdir -p /home/writeros/.config/openbox
cat > /home/writeros/.config/openbox/autostart << 'AUTOSTART'
tint2 &
pcmanfm --desktop &
fcitx5 &
AUTOSTART

# Create desktop shortcut for installer
mkdir -p /home/writeros/Desktop
cat > /home/writeros/Desktop/install-writeros.desktop << 'DESKTOP'
[Desktop Entry]
Name=Install WriterOS
Comment=Install WriterOS to hard drive
Exec=sudo /usr/sbin/debian-installer
Icon=system-installer
Terminal=false
Type=Application
Categories=System;
DESKTOP

chmod +x /home/writeros/Desktop/install-writeros.desktop

# Neovim basic configuration
mkdir -p /home/writeros/.config/nvim
cat > /home/writeros/.config/nvim/init.lua << 'NVIM_CONFIG'
-- WriterOS Neovim configuration
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
print("WriterOS Neovim loaded!")
NVIM_CONFIG

# Set correct ownership
chown -R writeros:writeros /home/writeros/

# Power management optimization
systemctl enable tlp
systemctl enable acpid

# Disable unnecessary services for live session
systemctl disable bluetooth || true
systemctl disable cups || true
systemctl disable NetworkManager-wait-online || true

# Network manager auto-connect
systemctl enable NetworkManager

echo "=== WriterOS Live System Setup Completed ==="
EOF

chmod +x config/hooks/live/0010-writeros-live-setup.hook.chroot
```

### 한글 환경 최적화 Hook
```bash
# 한글 환경 특화 설정
cat > config/hooks/live/0020-korean-environment.hook.chroot << 'EOF'
#!/bin/bash

echo "=== Korean Environment Setup Started ==="

# Set system-wide Korean locale
echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Update locale configuration
update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8

# Configure input method environment
cat > /etc/environment << 'ENV'
LANG=ko_KR.UTF-8
LC_ALL=ko_KR.UTF-8
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
ENV

# Korean fonts configuration
mkdir -p /etc/fonts/conf.d
cat > /etc/fonts/local.conf << 'FONTS'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif CJK KR</family>
    </prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans CJK KR</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Nanum Gothic Coding</family>
    </prefer>
  </alias>
</fontconfig>
FONTS

echo "=== Korean Environment Setup Completed ==="
EOF

chmod +x config/hooks/live/0020-korean-environment.hook.chroot
```

## Step 5: 부트로더 메뉴 커스터마이징

### Syslinux 부트 메뉴 설정
```bash
# 커스텀 부트 메뉴 생성
mkdir -p config/bootloaders/syslinux
cat > config/bootloaders/syslinux/menu.cfg << 'EOF'
menu hshift 0
menu width 82
menu margin 8
menu tabmsg Press [Tab] to edit options

menu title WriterOS Boot Menu
menu background splash.png

default live-amd64
timeout 300

label live-amd64
    menu label ^Try WriterOS (Live System)
    menu default
    linux /live/vmlinuz-*
    initrd /live/initrd.img-*
    append boot=live components quiet splash locales=ko_KR.UTF-8

label live-amd64-failsafe
    menu label Try WriterOS (^Safe Mode)
    linux /live/vmlinuz-*
    initrd /live/initrd.img-*
    append boot=live components memtest noapic noapm nodma nomce nolapic nosmp nosplash vga=normal

label install-amd64
    menu label ^Install WriterOS
    linux /install/vmlinuz
    initrd /install/initrd.gz
    append priority=low vga=788 locales=ko_KR.UTF-8

label install-amd64-gtk
    menu label Install WriterOS (^Graphical)
    linux /install/gtk/vmlinuz
    initrd /install/gtk/initrd.gz
    append priority=low vga=788 locales=ko_KR.UTF-8

label hdt
    menu label ^Hardware Detection Tool
    com32 hdt.c32

label memtest
    menu label ^Memory Test
    linux /live/memtest

menu separator

label reboot
    menu label ^Reboot
    com32 reboot.c32

label poweroff
    menu label ^Power Off
    com32 poweroff.c32
EOF

# 부트 화면 설정
cat > config/bootloaders/syslinux/splash.cfg << 'EOF'
# WriterOS Boot Splash
menu color screen       37;40      #80ffffff #00000000 std
menu color border       30;44      #40ffffff #a0000000 std
menu color title        1;36;44    #c0ffffff #a0000000 std
menu color unsel        37;44      #90ffffff #a0000000 std
menu color hotkey       1;37;44    #ffffffff #a0000000 std
menu color sel          7;37;40    #e0000000 #20ff8000 all
menu color hotsel       1;7;37;40  #e0400000 #20ff8000 all
menu color disabled     1;30;44    #60cccccc #a0000000 std
menu color scrollbar    30;44      #40ffffff #a0000000 std
menu color tabmsg       31;40      #90ffff00 #a0000000 std
menu color cmdmark      1;36;40    #c0ffffff #a0000000 std
menu color cmdline      37;40      #c0ffffff #a0000000 std
menu color pwdborder    30;47      #80ffffff #20ffffff std
menu color pwdheader    31;47      #80ff8080 #20ffffff std
menu color pwdentry     30;47      #80ffffff #20ffffff std
menu color timeout_msg  37;40      #80ffffff #00000000 std
menu color timeout      1;37;40    #c0ffffff #00000000 std
menu color help         37;40      #c0ffffff #00000000 std
menu color msg07        37;40      #90ffffff #00000000 std
EOF
```

## Step 6: 빌드 실행

### 빌드 스크립트 생성
```bash
# 원클릭 빌드 스크립트 생성
cat > build-writeros-installer.sh << 'EOF'
#!/bin/bash

set -e

echo "=== WriterOS Live + Installer 빌드 시작 ==="
echo "시작 시간: $(date)"

# 빌드 시간 측정
START_TIME=$(date +%s)

# 빌드 실행
sudo lb build 2>&1 | tee build.log

# 빌드 시간 계산
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))

echo "=== 빌드 완료 ==="
echo "완료 시간: $(date)"
echo "소요 시간: ${HOURS}시간 ${MINUTES}분 ${SECONDS}초"

# 결과 확인
if [ -f "live-image-amd64.hybrid.iso" ]; then
    echo "✅ ISO 파일 생성 성공!"
    echo "파일 정보:"
    ls -lah live-image-amd64.hybrid.iso
    echo "파일 타입:"
    file live-image-amd64.hybrid.iso
    echo ""
    echo "🎉 WriterOS Live + Installer ISO가 성공적으로 생성되었습니다!"
    echo "   - Try WriterOS: 라이브 시스템으로 즉시 체험"
    echo "   - Install WriterOS: 하드드라이브에 영구 설치"
else
    echo "❌ ISO 파일 생성 실패"
    echo "build.log를 확인하세요"
    exit 1
fi
EOF

chmod +x build-writeros-installer.sh
```

### 빌드 실행
```bash
# 빌드 시작
echo "=== WriterOS Live + Installer 빌드 시작 ==="
./build-writeros-installer.sh

# 별도 터미널에서 모니터링 (선택사항)
watch -n 10 'echo "📊 $(date)" && echo "💾 빌드 크기:" && du -sh ~/writeros-build/amd64 && echo "💿 ISO 상태:" && ls -lah ~/writeros-build/amd64/*.iso 2>/dev/null || echo "ISO 파일 생성 중..." && echo "🔄 활성 프로세스:" && ps aux | grep -E "(lb|apt|dpkg)" | grep -v grep | wc -l'
```

## Step 7: 테스트 및 확인

### QEMU로 가상 머신 테스트
```bash
# QEMU 설치 (아직 설치하지 않았다면)
sudo apt install -y qemu-system-x86

# Live 모드 테스트
qemu-system-x86_64 \
    -m 4096 \
    -cdrom live-image-amd64.hybrid.iso \
    -boot d \
    -enable-kvm \
    -display gtk

# Installer 모드 테스트 (별도 가상 하드드라이브)
qemu-img create -f qcow2 writeros-test.qcow2 20G

qemu-system-x86_64 \
    -m 4096 \
    -cdrom live-image-amd64.hybrid.iso \
    -hda writeros-test.qcow2 \
    -boot d \
    -enable-kvm \
    -display gtk
```

### ISO 파일 정보 확인
```bash
# 생성된 ISO 파일 확인
ls -lah live-image-amd64.hybrid.iso

# ISO 내부 구조 확인
sudo mkdir -p /mnt/writeros-iso
sudo mount -o loop live-image-amd64.hybrid.iso /mnt/writeros-iso
ls -la /mnt/writeros-iso/
tree /mnt/writeros-iso/ -L 2

# 확인 완료 후 언마운트
sudo umount /mnt/writeros-iso
```

## 🔧 문제 해결

### 자주 발생하는 오류들

#### 1. ⚠️ udeb 패키지 설치 오류 (가장 흔한 오류)
```bash
# 🚨 증상: 
# E: Unable to locate package debian-installer-utils
# E: Unable to locate package hw-detect  
# E: Unable to locate package partman-auto

# ✅ 해결책: installer 전용 패키지 목록 완전 삭제
rm -f config/package-lists/writeros-installer.list.chroot

# 이유: udeb 패키지는 일반 시스템에 설치할 수 없음
# Live Build가 --debian-installer true로 자동 처리함
```

#### 2. 빌드 시간 초과
```bash
# 증상: 네트워크 다운로드가 너무 느림
# 해결: 미러 서버 변경
vim config/includes.installer/preseed.cfg

# 한국 미러 서버 사용
d-i mirror/http/hostname string ftp.kaist.ac.kr
d-i mirror/http/directory string /debian
```

#### 3. 한글 폰트 문제
```bash
# 증상: 한글이 깨져서 보임
# 해결: 추가 한글 폰트 설치
echo "fonts-nanum-extra" >> config/package-lists/writeros-live.list.chroot
echo "fonts-noto-color-emoji" >> config/package-lists/writeros-live.list.chroot
```

## 📊 예상 결과

### 성공적인 빌드 결과
```bash
# 생성되는 파일
live-image-amd64.hybrid.iso    # 약 1.2-1.5GB

# 부팅 메뉴 옵션
1. Try WriterOS (Live System)     # 라이브 모드
2. Install WriterOS               # 텍스트 설치
3. Install WriterOS (Graphical)   # GUI 설치  
4. Hardware Detection Tool
5. Memory Test
```

### 사용자 경험
```bash
# 라이브 모드 (Try WriterOS)
부팅 → 자동 로그인 → 한글 데스크톱 → 바로 글쓰기 가능

# 설치 모드 (Install WriterOS)  
부팅 → 설치 위저드 → 파티션 설정 → 듀얼부팅 설치 → 재부팅
```

## 🎉 완료 확인

다음 명령어들이 모두 성공하면 Live + Installer 환경 구축 완료:

```bash
# 1. ISO 파일 생성 확인
ls -lah ~/writeros-build/amd64/live-image-amd64.hybrid.iso

# 2. ISO 파일 크기 확인 (1GB 이상)
du -h ~/writeros-build/amd64/live-image-amd64.hybrid.iso

# 3. ISO 파일 타입 확인
file ~/writeros-build/amd64/live-image-amd64.hybrid.iso

# 4. QEMU 테스트 가능 확인
which qemu-system-x86_64
```

## ⚠️ 중요한 주의사항

### udeb 패키지 오류 방지
```bash
# ❌ 절대 하지 마세요:
echo "debian-installer-utils" >> config/package-lists/any.list.chroot

# ✅ 올바른 방법:
# Live Build가 --debian-installer true로 자동 처리합니다
```

### 올바른 접근 방식
1. **라이브 시스템 패키지**: `writeros-live.list.chroot`에 추가
2. **설치 설정**: `preseed.cfg`와 `post-install.sh`로 설정
3. **Installer 컴포넌트**: Live Build가 자동 처리 (건드리지 말 것)

## 🔧 즉시 테스트하기

문제가 해결된 올바른 설정으로 바로 테스트하려면:

```bash
# 1. 깔끔하게 다시 시작
cd ~/writeros-build/amd64
sudo lb clean --purge
rm -rf config/ auto/ .build/

# 2. Live + Installer 모드 초기화 (installer 패키지 목록 없이)
lb config --debian-installer true \
          --debian-installer-gui true \
          --architectures amd64 \
          --distribution bookworm

# 3. 라이브 시스템 패키지만 추가 (installer 패키지 제외)
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

# 4. 빌드 시작
sudo lb build
```

**이제 udeb 패키지 오류 없이 성공적으로 빌드됩니다! 🚀**

---

## 📚 다음 단계

Live + Installer ISO가 성공적으로 생성되었다면:

1. **실제 하드웨어 테스트** - USB로 실제 컴퓨터에서 테스트
2. **듀얼부팅 설정 테스트** - Windows와 함께 설치 테스트
3. **사용자 피드백 수집** - 실제 사용자들의 체험 결과 분석
4. **성능 최적화** - 부팅 속도 및 메모리 사용량 최적화

---
*이 문서는 WriterOS Live + Installer 복합형 시스템 구축을 위한 완전한 가이드입니다.* 
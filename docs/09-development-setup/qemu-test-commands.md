# WriterOS QEMU Testing Commands

```bash
cd ~/writeros-build/amd64
qemu-system-x86_64 -m 2048 -smp 2 -cdrom live-image-amd64.hybrid.iso -boot d -display gtk -accel tcg
```

## 1. Basic System Check
```bash
# Check if we're in WriterOS
cat /etc/os-release

# Check memory usage
free -h

# Check CPU usage
top -bn1 | head -5
```

## 2. WriterOS Custom Commands Test
```bash
# Test WriterOS commands
ls -la /usr/local/bin/writeros-*

# Test performance mode (if available)
sudo writeros-performance

# Test power save mode (if available)  
sudo writeros-powersave
```

## 3. Boot Time Analysis
```bash
# Check boot time
systemd-analyze

# Check which services took longest
systemd-analyze blame | head -10
```

## 4. Memory Optimization Check
```bash
# Check if zram is active
ls -la /sys/block/zram*

# Check swap status
swapon --show

# Check memory details
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable"
```

## 5. Service Status
```bash
# Check active services
systemctl list-units --type=service --state=active | wc -l

# Check failed services
systemctl list-units --type=service --state=failed

# Check if optimization services are masked
systemctl status apt-daily.service
systemctl status NetworkManager-wait-online.service
```

## 6. Package Count
```bash
# Count installed packages
dpkg -l | grep ^ii | wc -l

# List WriterOS specific packages
dpkg -l | grep -E "zram|earlyoom|preload|systemd-bootchart"
```

## 7. Font and Korean Support
```bash
# Check Korean fonts
fc-list | grep -i noto | grep -i cjk

# Test Korean input (if fcitx5 is available)
echo "한글 테스트" > test.txt && cat test.txt
```

## 8. Neovim Test
```bash
# Test Neovim
nvim --version
nvim test.txt
```

## Expected Results (Optimized vs Baseline)

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| Boot Time | ~15-20s | <8s | 🔄 |
| Memory Usage | ~300-400MB | <400MB | 🔄 |
| Package Count | 8 | ~16 | 🔄 |
| WriterOS Commands | 0 | 3 | 🔄 |
| Zram Active | No | Yes | 🔄 |
| Services Masked | 0 | 6 | 🔄 | 
# 전력 관리 전략

WriterOS의 핵심 목표 중 하나는 극한의 배터리 수명과 빠른 퀵리줌입니다.

## 목표

- **배터리 수명**: 글쓰기 작업 기준 8-12시간
- **퀵리줌**: 1초 이내 suspend/resume
- **하이브리드 슬립**: 배터리 소진 시 자동 hibernation
- **지능형 전력 관리**: 사용 패턴 학습

## Linux 6.14+ 개선사항 활용

### ACPI 최적화
최신 커널의 ACPI 개선사항을 활용하여 suspend/resume 속도 향상:

```bash
# 커널 매개변수
resume=UUID=<swap-partition-uuid>
mem_sleep_default=s2idle
```

### LZ4 Hibernation
빠른 hibernation을 위한 LZ4 압축 사용:

```bash
# 부팅 옵션
hib_compression=lz4
```

## 전력 관리 계층

```
┌─────────────────────────────────────────┐
│         사용자 정책 계층                 │
│  (AI 기반 적응형 전력 관리)              │
├─────────────────────────────────────────┤
│         어플리케이션 계층                │
│  (전력 인식 글쓰기 도구)                 │
├─────────────────────────────────────────┤
│         시스템 서비스 계층               │
│  (최적화된 systemd 서비스)               │
├─────────────────────────────────────────┤
│         커널 계층                       │
│  (CPU 스케줄링, 하드웨어 제어)           │
└─────────────────────────────────────────┘
```

## 핵심 기술

### 1. Intelligent Suspend/Resume

#### Auto-suspend 정책
```yaml
# /etc/writeros/power-policy.yaml
writing_mode:
  idle_timeout: 30s      # 30초 비활성시 화면 끄기
  suspend_timeout: 2m    # 2분 비활성시 suspend
  hibernate_timeout: 30m # 30분 suspend 후 hibernate

reading_mode:
  idle_timeout: 2m       # 읽기 모드에서는 더 관대
  suspend_timeout: 5m
  hibernate_timeout: 45m
```

#### 지능형 Wake 조건
- 키보드/마우스 입력
- 펜 터치 (타블렛 모드)
- 예약된 백업/동기화 작업
- 중요 알림

### 2. CPU 및 GPU 최적화

#### CPU 거버너 설정
```bash
# 글쓰기 모드: 저전력 우선
echo powersave > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# AI 처리 모드: 성능 우선
echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### GPU 전력 관리
```bash
# Intel GPU
echo auto > /sys/class/drm/card0/device/power/control

# AMD GPU
echo low > /sys/class/drm/card0/device/power_dpm_force_performance_level
```

### 3. 하이브리드 슬립 구현

#### Systemd 설정
```ini
# /etc/systemd/sleep.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
AllowHybridSleep=yes

SuspendMode=s2idle
SuspendState=mem
HibernateMode=platform shutdown
HibernateState=disk

HibernateDelaySec=30min
SuspendEstimationSec=60min
```

#### 스마트 전환 스크립트
```bash
#!/bin/bash
# /usr/local/bin/smart-suspend

BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT0/capacity)
AC_CONNECTED=$(cat /sys/class/power_supply/ADP1/online)

if [ "$AC_CONNECTED" = "1" ]; then
    # AC 연결시: 일반 suspend
    systemctl suspend
elif [ "$BATTERY_LEVEL" -lt 20 ]; then
    # 배터리 20% 미만: 즉시 hibernate
    systemctl hibernate
else
    # 배터리 충분: hybrid sleep
    systemctl suspend-then-hibernate
fi
```

### 4. 디스플레이 최적화

#### e-ink 디스플레이 지원
```bash
# e-ink 최적화 설정
echo 1 > /sys/class/graphics/fbcon/cursor_blink  # 커서 깜빡임 비활성화
echo 0 > /sys/class/backlight/*/brightness       # 백라이트 끄기 (e-ink)
```

#### 동적 밝기 조절
```python
#!/usr/bin/env python3
# /usr/local/bin/adaptive-brightness

import subprocess
import time
from datetime import datetime

def get_ambient_light():
    # 주변 조도 센서 읽기 (있는 경우)
    try:
        with open('/sys/bus/iio/devices/iio:device0/in_illuminance_input') as f:
            return int(f.read())
    except:
        # 시간 기반 추정
        hour = datetime.now().hour
        if 6 <= hour <= 18:
            return 80  # 낮
        else:
            return 20  # 밤

def set_brightness(level):
    subprocess.run(['brightnessctl', 'set', f'{level}%'])

while True:
    light = get_ambient_light()
    brightness = min(100, max(10, light))
    set_brightness(brightness)
    time.sleep(30)  # 30초마다 조정
```

### 5. 네트워크 전력 관리

#### WiFi 절전
```bash
# WiFi 파워 세이브 모드
iw dev wlan0 set power_save on

# 불필요한 네트워크 서비스 비활성화
systemctl disable bluetooth
systemctl mask NetworkManager-wait-online.service
```

#### 지능형 연결 관리
```bash
#!/bin/bash
# /usr/local/bin/network-power-manager

# 글쓰기 모드에서는 백그라운드 동기화 제한
if writeros-mode | grep -q "writing"; then
    # 필수 서비스만 허용
    systemctl stop cronie  # cron 작업 중단
    systemctl stop rclone-sync  # 클라우드 동기화 중단
else
    # 휴식 시간에 동기화 재개
    systemctl start cronie
    systemctl start rclone-sync
fi
```

## 전력 모니터링

### 배터리 상태 표시
```bash
#!/bin/bash
# /usr/local/bin/battery-status

BAT_CAP=$(cat /sys/class/power_supply/BAT0/capacity)
BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status)
TIME_LEFT=$(acpi -b | grep -o '[0-9][0-9]:[0-9][0-9]')

echo "🔋 $BAT_CAP% ($BAT_STATUS) - $TIME_LEFT remaining"
```

### 전력 사용량 분석
```python
#!/usr/bin/env python3
# /usr/local/bin/power-analysis

import psutil
import time

def analyze_power_usage():
    # CPU 사용률
    cpu_percent = psutil.cpu_percent(interval=1)
    
    # 활성 프로세스
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
        if proc.info['cpu_percent'] > 1.0:
            processes.append(proc.info)
    
    # 전력 소모 예측
    estimated_hours = estimate_battery_life(cpu_percent)
    
    return {
        'cpu_usage': cpu_percent,
        'power_hungry_processes': processes,
        'estimated_battery_hours': estimated_hours
    }
```

## 최적화 체크리스트

### 시스템 레벨
- [ ] 불필요한 서비스 비활성화
- [ ] 커널 모듈 최소화
- [ ] swap 파티션 구성 (hibernation용)
- [ ] zram 활성화 (메모리 효율성)

### 하드웨어 레벨
- [ ] CPU 전력 상태 최적화
- [ ] GPU 절전 모드 설정
- [ ] 네트워크 카드 절전 설정
- [ ] USB 장치 자동 suspend

### 사용자 레벨
- [ ] 화면 밝기 자동 조절
- [ ] 키보드 백라이트 타이머
- [ ] 자동 파일 저장 간격 조정
- [ ] 백그라운드 프로세스 최소화

## 다음 문서

- [하이브리드 슬립 구현](hybrid-sleep.md)
- [전력 모니터링 도구](power-monitoring.md)
- [하드웨어별 최적화](hardware-optimization.md) 
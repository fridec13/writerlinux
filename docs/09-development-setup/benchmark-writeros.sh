#!/bin/bash

echo "=== WriterOS Performance Benchmark ==="
echo "Date: $(date)"
echo "=========================================="

# Boot Time Analysis
echo "1. Boot Time Analysis:"
if command -v systemd-analyze >/dev/null 2>&1; then
    boot_time=$(systemd-analyze | grep "Startup finished" | awk '{print $4}')
    echo "   Total Boot Time: $boot_time"
    
    echo "   Boot Breakdown:"
    systemd-analyze blame | head -10
else
    echo "   systemd-analyze not available"
fi

echo ""

# Memory Usage Analysis
echo "2. Memory Usage Analysis:"
memory_total=$(free -m | awk 'NR==2{print $2}')
memory_used=$(free -m | awk 'NR==2{print $3}')
memory_percent=$(echo "scale=2; $memory_used*100/$memory_total" | bc)
echo "   Total Memory: ${memory_total}MB"
echo "   Used Memory: ${memory_used}MB (${memory_percent}%)"

echo "   Top Memory Consumers:"
ps aux --sort=-%mem | awk 'NR<=6 {printf "   %-20s %s\n", $11, $4"%"}'

echo ""

# CPU Usage Analysis
echo "3. CPU Usage Analysis:"
cpu_cores=$(nproc)
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "   CPU Cores: $cpu_cores"
echo "   CPU Usage: ${cpu_usage}%"

echo ""

# Disk Usage Analysis
echo "4. Disk Usage Analysis:"
disk_usage=$(df -h / | awk 'NR==2{print $5}')
echo "   Root Disk Usage: $disk_usage"

echo ""

# Service Status
echo "5. Service Status:"
echo "   Active Services:"
systemctl list-units --type=service --state=active | wc -l | xargs echo "   "
echo "   Failed Services:"
systemctl list-units --type=service --state=failed | wc -l | xargs echo "   "

echo ""

# WriterOS Commands Test
echo "6. WriterOS Commands Test:"
if [ -f "/usr/local/bin/writeros-performance" ]; then
    echo "   ✅ writeros-performance: Available"
else
    echo "   ❌ writeros-performance: Not found"
fi

if [ -f "/usr/local/bin/writeros-powersave" ]; then
    echo "   ✅ writeros-powersave: Available"
else
    echo "   ❌ writeros-powersave: Not found"
fi

if [ -f "/usr/local/bin/writeros-suspend" ]; then
    echo "   ✅ writeros-suspend: Available"
else
    echo "   ❌ writeros-suspend: Not found"
fi

echo ""

# Package Count
echo "7. Package Analysis:"
if command -v dpkg >/dev/null 2>&1; then
    package_count=$(dpkg -l | grep ^ii | wc -l)
    echo "   Installed Packages: $package_count"
fi

echo ""

# Zram Status
echo "8. Zram Status:"
if [ -f "/sys/block/zram0/disksize" ]; then
    zram_size=$(cat /sys/block/zram0/disksize)
    echo "   ✅ Zram: Active (Size: $zram_size bytes)"
else
    echo "   ❌ Zram: Not active"
fi

echo ""

# Performance Summary
echo "9. Performance Summary:"
echo "   =========================================="
echo "   Boot Time: $boot_time"
echo "   Memory Usage: ${memory_used}MB/${memory_total}MB (${memory_percent}%)"
echo "   CPU Usage: ${cpu_usage}%"
echo "   Disk Usage: $disk_usage"
echo "   Package Count: $package_count"
echo "   =========================================="

echo ""
echo "=== Benchmark Complete ===" 
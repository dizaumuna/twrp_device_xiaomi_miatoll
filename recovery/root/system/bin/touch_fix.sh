#!/system/bin/sh

LOG=/tmp/touch_fix.log
exec >>"$LOG" 2>&1

DEV=/sys/bus/spi/devices/spi1.0
echo "started, uptime: $(cut -d' ' -f1 /proc/uptime)"

# let twrp boot up and things load
sleep 8

if [ ! -d "$DEV" ]; then
    echo "spi1.0 is not available. current SPI devices:"
    ls /sys/bus/spi/devices
    exit 0
fi

DRV=""
[ -L "$DEV/driver" ] && DRV="$(basename "$(readlink "$DEV/driver")")"
if [ -z "$DRV" ]; then
    echo "no drivers connected to spi1.0. available drivers:"
    ls /sys/bus/spi/drivers
    exit 0
fi
echo "driver: $DRV"

BEFORE="$(dmesg | grep -c 'fw download successfully')"

echo spi1.0 > "/sys/bus/spi/drivers/$DRV/unbind"
sleep 1
echo spi1.0 > "/sys/bus/spi/drivers/$DRV/bind"
sleep 5

AFTER="$(dmesg | grep -c 'fw download successfully')"
echo "fw download diff: before=$BEFORE after=$AFTER"

echo "--- input devices ---"
grep -E "Name=" /proc/bus/input/devices
echo "--- dmesg (touch, last 30) ---"
dmesg | grep -E "FTS_TS|NVT" | tail -n 30
echo "=== end script ==="

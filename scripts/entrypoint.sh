#!/bin/bash
set -e

echo "=========================================="
echo "  AltServer Linux - Docker Container"
echo "=========================================="

# Create necessary directories
mkdir -p /app/log /app/data /var/run/dbus /var/run/avahi-daemon

# Clean up stale files
rm -f /var/run/dbus/pid /var/run/avahi-daemon/pid

# Update library cache
ldconfig

echo ""
echo "Services starting..."
echo "  - D-Bus"
echo "  - Avahi (mDNS)"
echo "  - usbmuxd (USB device handling)"
echo "  - AltServer"
echo ""
echo "Note: Anisette v3 runs in a separate container"
echo ""
echo "=========================================="
echo "  USAGE:"
echo "=========================================="
echo ""
echo "1. PAIR A NEW DEVICE (USB required first time):"
echo "   docker exec -it altserver pair"
echo ""
echo "2. INSTALL AN IPA:"
echo "   - Place your .ipa file in the 'ipa' folder"
echo "   - Run: docker exec -it altserver install <ipa-name> <apple-id> <password>"
echo ""
echo "3. LIST CONNECTED DEVICES:"
echo "   docker exec -it altserver devices"
echo ""
echo "4. VIEW LOGS:"
echo "   docker exec -it altserver logs [service]"
echo "   Services: altserver, netmuxd, anisette, avahi, usbmuxd"
echo ""
echo "5. INTERACTIVE SHELL:"
echo "   docker exec -it altserver bash"
echo ""
echo "=========================================="

# Run the command (default: supervisord)
if [ "$1" = "supervisord" ]; then
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
else
    exec "$@"
fi

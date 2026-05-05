#!/bin/sh
#
# Script de descarga del driver ath6kl para Raspberry Pi
#

WLANDEV=wlan0

echo "Descargando driver ath6kl..."

# Bajar interfaz si existe
if [ -e /sys/class/net/$WLANDEV ]; then
    ip link set $WLANDEV down 2>/dev/null || true

    # Bajar interfaz monitor si existe
    if [ -e /sys/class/net/mon0 ]; then
        ip link set mon0 down 2>/dev/null || true
    fi
fi

# Descargar módulos en orden inverso
rmmod ath6kl_usb 2>/dev/null || true
rmmod cfg80211 2>/dev/null || true

echo "Driver descargado correctamente"

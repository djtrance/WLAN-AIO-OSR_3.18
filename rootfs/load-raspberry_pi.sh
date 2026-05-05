#!/bin/sh
#
# Script de carga del driver ath6kl para Raspberry Pi
# Compatible con Raspberry Pi 1, 2 y Zero 2W
#

TOPDIR=`pwd`
MODULE_PATH=${TOPDIR}/lib/modules
WLANDEV=wlan0

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ser ejecutado como root"
    exit 1
fi

# Verificar si el dispositivo USB está conectado
echo "Buscando dispositivo Atheros USB..."
DEVICE=`lsusb | grep "0cf3:9374"`
DEVICE_9375=`lsusb | grep "0cf3:9375"`

if [ "$DEVICE" = "" -a "$DEVICE_9375" = "" ]; then
    echo "No se detectó dispositivo Atheros USB. Conecta la tarjeta y vuelve a intentar."
    exit 2
fi

# Deshabilitar rfkill
rfkill unblock all 2>/dev/null || true

# Instalar driver
echo "=============Instalando Driver..."
modprobe cfg80211

# Cargar driver con parámetros para Raspberry Pi
modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200

sleep 3

# Detectar interfaz de red
if [ -e /sys/class/net ]; then
    for dev in `ls /sys/class/net/`; do
        if [ -e /sys/class/net/$dev/device/idProduct ]; then
            PID=`cat /sys/class/net/$dev/device/idProduct`
            if [ "$PID" = "9374" -o "$PID" = "9375" ]; then
                WLANDEV=$dev
            fi
        fi
    done

    if [ "$WLANDEV" = "" ]; then
        WLANDEV=wlan0
    fi

    echo "Interfaz detectada: $WLANDEV"
fi

# Subir interfaz
echo "Subiendo interfaz $WLANDEV..."
ip link set $WLANDEV up

# Esperar a que la interfaz esté lista
sleep 2

# Mostrar información del dispositivo
echo "=============Información del Dispositivo..."
ip link show $WLANDEV

# Mostrar información de wireless
if command -v iw &> /dev/null; then
    echo "=============Información Wireless..."
    iw dev $WLANDEV info 2>/dev/null || true

    # Verificar modo monitor
    echo "=============Verificando modo monitor..."
    if iw dev $WLANDEV interface add mon0 type monitor 2>/dev/null; then
        echo "Modo monitor SOPORTADO"
        ip link set mon0 up
        echo "Interfaz de monitor creada: mon0"
    else
        echo "Modo monitor no disponible en esta configuración"
    fi

    # Listar redes disponibles
    echo "=============Redes disponibles..."
    iw dev $WLANDEV scan | grep SSID || true
fi

echo "=============Done!"

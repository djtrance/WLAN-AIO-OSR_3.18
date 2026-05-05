# Modo Monitor - ath6kl Driver para Raspberry Pi

## ¿Soporta el driver modo monitor?

**SÍ, el driver ath6kl soporta modo monitor.**

El código fuente en `drivers/ath6kl/cfg80211.c` incluye soporte para `NL80211_IFTYPE_MONITOR`.

## Configuración del Modo Monitor

### 1. Verificar que el driver está cargado

```bash
lsmod | grep ath6kl
# Deberías ver: cfg80211 y ath6kl_usb
```

### 2. Verificar la interfaz wlan0

```bash
ip link show wlan0
# Deberías ver: state UP o DOWN (no debe estar "No such device")
```

### 3. Crear interfaz en modo monitor

```bash
# Método 1: Usando iw (recomendado)
iw dev wlan0 interface add mon0 type monitor

# Método 2: Usando ip (alternativo)
ip link add mon0 type monitor wlan wlan0

# Activar la interfaz
ip link set mon0 up
```

### 4. Verificar que el modo monitor está activo

```bash
# Ver interfaces de red
ip link show | grep -E "wlan|mon"

# Ver información detallada de mon0
iw dev mon0 info

# Deberías ver: type monitor en la salida
```

## Uso del Modo Monitor con Herramientas Comunes

### a) Aircrack-ng Suite

```bash
# Instalar aircrack-ng (si no está instalado)
apt-get install aircrack-ng

# Escaneo de redes
airodump-ng mon0

# Captura de paquetes
airodump-ng --bssid XX:XX:XX:XX:XX:XX -w capture mon0

# Deauth attack (solo para pruebas autorizadas)
aireplay-ng --deauth 10 -a XX:XX:XX:XX:XX:XX mon0

# Crackeo de WEP/WPA (solo para pruebas autorizadas)
aircrack-ng capture-01.cap
```

### b) Wireshark/TShark

```bash
# Instalar wireshark
apt-get install wireshark

# Capturar paquetes con tshark
tshark -i mon0 -w capture.pcap

# O usar wireshark en modo gráfico
wireshark -i mon0
```

### c) Kismet

```bash
# Instalar kismet
apt-get install kismet

# Ejecutar kismet en modo monitor
kismet -c mon0
```

### d) Bettercap

```bash
# Instalar bettercap (si está disponible)
apt-get install bettercap

# Capturar paquetes WiFi
bettercap -eval "wifi.scanner.on"
```

## Comandos Útiles para Modo Monitor

```bash
# Listar interfaces disponibles
iw dev

# Ver información de una interfaz específica
iw dev wlan0 info
iw dev mon0 info

# Cambiar canal del modo monitor
iw dev mon0 set channel 6

# Ver canales disponibles
iw list | grep -A 20 "Supported channels"

# Escaneo de redes WiFi
iw dev wlan0 scan | grep SSID

# Ver clientes conectados a un AP
airodump-ng --bssid XX:XX:XX:XX:XX:XX -c 6 mon0

# Ver tráfico WiFi en tiempo real
tcpdump -i mon0 -w capture.pcap

# Filtrar tráfico específico en modo monitor
tcpdump -i mon0 -w capture.pcap 'wlan type mgt and wlan addr1 == XX:XX:XX:XX:XX:XX'
```

## Solución de Problemas del Modo Monitor

### Error: "Operation not supported"

```bash
# Verificar que el driver soporta modo monitor
dmesg | grep -i "monitor\|cfg80211"

# Verificar que el firmware está cargado correctamente
ls /lib/firmware/ath6k/

# Recargar el driver con debug enabled
modprobe -r ath6kl_usb
modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200
```

### Error: "No such device"

```bash
# Verificar que el dispositivo USB está conectado
lsusb | grep 0cf3

# Verificar logs del kernel
dmesg | tail -50

# Recargar el driver
modprobe -r ath6kl_usb cfg80211
modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200
```

### Error: "Permission denied"

```bash
# El modo monitor requiere privilegios root
sudo -i

# O usar sudo para cada comando
sudo iw dev wlan0 interface add mon0 type monitor
```

## Configuración Permanente del Modo Monitor

### Crear servicio systemd para cargar el driver al inicio

```bash
cat > /etc/systemd/system/ath6kl-monitor.service << 'EOF'
[Unit]
Description=Ath6kl USB WiFi Driver with Monitor Mode Support
After=network.target usb-storage.service

[Service]
Type=oneshot
ExecStart=/etc/init.d/ath6kl-monitor start
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ath6kl-monitor.service
```

### Script de inicio para modo monitor

```bash
cat > /etc/init.d/ath6kl-monitor << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ath6kl-monitor
# Required-Start:    $local_fs $network usb-storage
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

set -e

WLANDEV=wlan0
MONITORDEV=mon0

case "$1" in
    start)
        echo "Loading ath6kl driver..."
        rfkill unblock all 2>/dev/null || true

        modprobe cfg80211
        modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200

        sleep 3

        if [ -e /sys/class/net/$WLANDEV ]; then
            ip link set $WLANDEV up

            # Crear interfaz monitor si no existe
            if ! ip link show $MONITORDEV &>/dev/null; then
                iw dev $WLANDEV interface add $MONITORDEV type monitor 2>/dev/null || true
                ip link set $MONITORDEV up 2>/dev/null || true
            fi

            echo "ath6kl driver loaded with monitor mode"
        else
            echo "wlan interface not found"
        fi
        ;;

    stop)
        echo "Stopping ath6kl driver..."
        if [ -e /sys/class/net/$WLANDEV ]; then
            ip link set $WLANDEV down 2>/dev/null || true
        fi

        if [ -e /sys/class/net/$MONITORDEV ]; then
            ip link set $MONITORDEV down 2>/dev/null || true
        fi

        rmmod ath6kl_usb 2>/dev/null || true
        rmmod cfg80211 2>/dev/null || true

        echo "ath6kl driver stopped"
        ;;

    reload|restart)
        $0 stop
        $0 start
        ;;

    *)
        echo "Usage: /etc/init.d/ath6kl-monitor {start|stop|reload|restart}"
        exit 1
        ;;
esac

exit 0
EOF

chmod +x /etc/init.d/ath6kl-monitor
update-rc.d ath6kl-monitor defaults 2>/dev/null || true

systemctl daemon-reload
systemctl enable ath6kl-monitor.service
```

## Ejemplos de Uso del Modo Monitor

### Escaneo pasivo de redes WiFi

```bash
# Escaneo sin transmitir paquetes (más discreto)
airodump-ng --essid "RedEjemplo" -w scan_result mon0

# Escaneo completo de todos los canales
airodump-ng --channel 1,6,11 -w scan_all mon0
```

### Captura de paquetes de autenticación WPA

```bash
# Capturar handshake WPA para análisis offline
airodump-ng --bssid XX:XX:XX:XX:XX:XX -c 6 --write handshake mon0

# Una vez capturado el handshake, puedes intentar crackearlo offline
aircrack-ng -w /usr/share/wordlists/dict.txt handshake-01.cap
```

### Análisis de tráfico WiFi

```bash
# Capturar todo el tráfico en un canal específico
tcpdump -i mon0 -w channel6.pcap 'wlan type mgt'

# Filtrar solo paquetes de gestión
tcpdump -i mon0 -w mgmt.pcap 'wlan type mgt'

# Filtrar solo paquetes de datos
tcpdump -i mon0 -w data.pcap 'wlan type data'

# Filtrar solo paquetes de control
tcpdump -i mon0 -w ctrl.pcap 'wlan type ctrl'
```

## Notas Importantes sobre el Modo Monitor

1. **Legalidad**: El modo monitor debe usarse solo en redes propias o con autorización explícita del propietario.

2. **Rendimiento**: El modo monitor puede consumir más recursos CPU que el modo normal.

3. **Compatibilidad**: No todos los dispositivos WiFi soportan todas las funciones del modo monitor.

4. **Kernel 5.10+**: El driver ath6kl ha sido adaptado para funcionar correctamente con kernels 5.10+.

## Referencias

- [Linux Wireless Documentation - Monitor Mode](https://wireless.wiki.kernel.org/en/users/documentation/monitor)
- [Atheros ath6kl Driver Documentation](https://www.kernel.org/doc/html/latest/networking/ath6kl.html)
- [Aircrack-ng Documentation](https://www.aircrack-ng.org/documentation.html)

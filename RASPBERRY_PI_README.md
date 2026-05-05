# Driver ath6kl para Raspberry Pi (1, 2 y Zero 2W)

## Resumen del Driver

Este driver **ath6kl** es un driver USB para tarjetas de red inalámbricas Atheros. Originalmente diseñado para soc nuvoton, ha sido adaptado para funcionar en Raspberry Pi 1, Raspberry Pi 2 y Raspberry Pi Zero 2W.

## Características del Driver

- **Soporte USB**: Funciona con dispositivos USB Atheros AR6004, AR6006
- **Modos de operación**:
  - Cliente (STA mode)
  - Access Point (AP mode)
  - P2P (Wi-Fi Direct)
  - **Monitor Mode** (SOportado según código fuente)

## Dispositivos Soportados

El driver soporta los siguientes dispositivos USB Atheros:

| ID Vendor/Product | Dispositivo |
|-------------------|-------------|
| 0cf3:1021 | Atheros AR9271 |
| 0cf3:1022 | Atheros AR9271 (otro variant) |
| 0cf3:1023 | Atheros AR9271 (otro variant) |
| 0cf3:6204 | Atheros AR6004 HW1.3 |
| 0cf3:6234 | Atheros AR6004 HW3.0 |
| 0cf3:9375 | Atheros AR9271 (Raspberry Pi) |
| 0cf3:9374 | Atheros AR9271 (Raspberry Pi Zero 2W) |
| 0cf3:9372 | Atheros AR9271 (otro variant) |

## Modo Monitor

**SÍ, el driver soporta modo monitor.**

El código fuente en `drivers/ath6kl/cfg80211.c` incluye soporte para `NL80211_IFTYPE_MONITOR`.

### Cómo activar modo monitor:

```bash
# 1. Cargar el driver
modprobe ath6kl_usb

# 2. Verificar que la interfaz wlan0 existe
ip link show wlan0

# 3. Crear interfaz en modo monitor
iw dev wlan0 interface add mon0 type monitor

# 4. Activar la interfaz
ip link set mon0 up

# 5. Usar con herramientas como aircrack-ng, wireshark, etc.
airodump-ng mon0
```

## Uso del Script de Compilación

### 1. Instalar dependencias

```bash
sudo ./build_scripts_raspberry_pi.sh install-deps
```

### 2. Verificar toolchain

```bash
sudo ./build_scripts_raspberry_pi.sh check-toolchain
```

### 3. Aplicar patches para compatibilidad con kernel 5.10+

```bash
sudo ./build_scripts_raspberry_pi.sh patch
```

### 4. Compilar el driver

```bash
sudo ./build_scripts_raspberry_pi.sh build
```

### 5. Instalar el driver en el sistema

```bash
sudo ./build_scripts_raspberry_pi.sh install
```

### 6. Cargar el driver

```bash
sudo ./build_scripts_raspberry_pi.sh load
```

### 7. Verificar modo monitor

```bash
sudo ./build_scripts_raspberry_pi.sh monitor
```

### 8. Crear script de inicio automático

```bash
sudo ./build_scripts_raspberry_pi.sh init
```

## Configuración para Raspberry Pi

### Kernel Version

El script está configurado por defecto para el kernel `5.10.103-v7+` que mencionaste.

### Archivos modificados del driver:

1. **drivers/ath6kl/usb.c** - Tabla de dispositivos USB
2. **drivers/ath6kl/cfg80211.c** - Soporte para modo monitor
3. **drivers/ath6kl/main.c** - Funciones principales del driver
4. **drivers/ath6kl/bmi.c** - BMI transfer functions
5. **drivers/ath6kl/init.c** - Inicialización del driver
6. **drivers/ath6kl/debug.c** - Debugfs API para kernel 5.x
7. **drivers/ath6kl/wmi.c** - WMI API calls
8. **drivers/ath6kl/htc.c** - HTC initialization
9. **drivers/ath6kl/reg.c** - Regulatory API calls
10. **drivers/ath6kl/ap.c** - AP mode functions
11. **drivers/ath6kl/p2p.c** - P2P functions

## Comandos Útiles

```bash
# Verificar si el driver está cargado
lsmod | grep ath6kl

# Ver dispositivos USB conectados
lsusb | grep 0cf3

# Ver interfaces de red
ip link show

# Ver información del driver
iwconfig wlan0

# Ver logs del kernel
dmesg | grep ath6kl

# Descargar el driver
sudo ./build_scripts_raspberry_pi.sh unload

# Limpiar archivos compilados
sudo ./build_scripts_raspberry_pi.sh clean
```

## Solución de Problemas

### El driver no carga

1. Verificar que los kernel headers están instalados:
   ```bash
   ls /lib/modules/$(uname -r)/build
   ```

2. Verificar que el dispositivo USB es detectado:
   ```bash
   lsusb | grep 0cf3
   ```

3. Verificar logs del kernel:
   ```bash
   dmesg | tail -50
   ```

### Modo monitor no disponible

1. Verificar que la interfaz wlan0 existe:
   ```bash
   ip link show | grep wlan
   ```

2. Intentar crear interfaz monitor:
   ```bash
   iw dev wlan0 interface add mon0 type monitor
   ```

3. Si falla, verificar que el driver está correctamente cargado:
   ```bash
   lsmod | grep ath6kl
   dmesg | grep ath6kl
   ```

### Errores de compilación

1. Asegurarse de tener los kernel headers correctos:
   ```bash
   uname -r  # Verificar versión del kernel
   apt-get install linux-headers-$(uname -r)  # Instalar headers
   ```

2. Verificar que la toolchain está instalada:
   ```bash
   arm-linux-gnueabihf-gcc --version
   ```

3. Aplicar patches antes de compilar:
   ```bash
   sudo ./build_scripts_raspberry_pi.sh patch
   ```

## Archivos del Proyecto

```
WLAN-AIO-OSR_3.18/
├── drivers/
│   ├── Makefile              # Makefile principal del driver
│   ├── ath6kl/               # Código fuente del driver USB
│   │   ├── usb.c            # Implementación USB (dispositivos)
│   │   ├── cfg80211.c       # Soporte modo monitor
│   │   ├── main.c           # Funciones principales
│   │   └── ...              # Otros archivos del driver
│   ├── cfg80211/            # Módulo cfg80211
│   └── patches/              # Patches para compatibilidad
├── fw/                       # Firmware del driver
│   └── firmware/
│       ├── AR6004/hw1.3/    # Firmware para HW1.3
│       ├── AR6004/hw3.0/    # Firmware para HW3.0
│       └── AR6006/hw1.1/    # Firmware para HW1.1
├── build_scripts_raspberry_pi.sh  # Script principal de compilación
└── RASPBERRY_PI_README.md  # Este archivo
```

## Licencia

Este driver es derivado del código fuente original de Atheros Communications Inc.
Consultar los archivos LICENSE y notice.txt para detalles de licencia.

## Soporte

Para más información sobre el driver ath6kl:
- [Atheros Wireless LAN Driver](https://www.kernel.org/doc/html/latest/networking/ath6kl.html)
- [Linux Wireless Documentation](https://wireless.wiki.kernel.org/)

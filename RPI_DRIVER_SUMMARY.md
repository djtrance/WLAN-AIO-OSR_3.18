# Resumen del Driver ath6kl para Raspberry Pi

## Información General

| Característica | Valor |
|---------------|-------|
| **Driver** | ath6kl (Atheros Wireless LAN) |
| **Tipo de conexión** | USB |
| **Kernel soportado** | 5.10.103-v7+ (Raspberry Pi) |
| **Arquitectura** | ARM (armhf) |
| **Dispositivos soportados** | AR9271 (0cf3:9374, 0cf3:9375) |
| **Modo Monitor** | **SÍ, soportado** |

## Archivos Creados

### 1. Script Principal de Compilación
**`build_scripts_raspberry_pi.sh`**

Script bash completo para compilar e instalar el driver en Raspberry Pi.

Funciones principales:
- `install-deps` - Instalar dependencias
- `check-toolchain` - Verificar toolchain de compilación
- `patch` - Aplicar patches para compatibilidad con kernel 5.10+
- `build` - Compilar el driver
- `install` - Instalar en el sistema
- `load` - Cargar driver
- `unload` - Descargar driver
- `monitor` - Verificar modo monitor
- `init` - Crear script de inicio automático

### 2. Documentación Principal
**`RASPBERRY_PI_README.md`**

Documentación completa del driver para Raspberry Pi.

### 3. Configuración de Modo Monitor
**`MONITOR_MODE_CONFIG.md`**

Guía detallada para configurar y usar el modo monitor.

### 4. Configuración de Raspberry Pi
**`build/scripts/raspberry_pi/config.raspberry_pi`**

Variables de configuración para cross-compilation.

### 5. Makefile para Raspberry Pi
**`build/scripts/raspberry_pi/Makefile.raspberry_pi`**

Makefile adaptado para Raspberry Pi.

### 6. Script de Carga
**`rootfs/load-raspberry_pi.sh`**

Script para cargar el driver en Raspberry Pi.

### 7. Script de Descarga
**`rootfs/unload-raspberry_pi.sh`**

Script para descargar el driver de Raspberry Pi.

## Uso Rápido

```bash
# 1. Instalar dependencias
sudo ./build_scripts_raspberry_pi.sh install-deps

# 2. Aplicar patches para compatibilidad con kernel 5.10+
sudo ./build_scripts_raspberry_pi.sh patch

# 3. Compilar el driver
sudo ./build_scripts_raspberry_pi.sh build

# 4. Instalar en el sistema
sudo ./build_scripts_raspberry_pi.sh install

# 5. Cargar el driver
sudo ./build_scripts_raspberry_pi.sh load

# 6. Verificar modo monitor
sudo ./build_scripts_raspberry_pi.sh monitor

# 7. Crear script de inicio automático
sudo ./build_scripts_raspberry_pi.sh init

# 8. Descargar el driver cuando sea necesario
sudo ./build_scripts_raspberry_pi.sh unload

# 9. Limpiar archivos compilados
sudo ./build_scripts_raspberry_pi.sh clean
```

## Modo Monitor - Comandos Esenciales

```bash
# Verificar que el driver está cargado
lsmod | grep ath6kl

# Crear interfaz en modo monitor
iw dev wlan0 interface add mon0 type monitor

# Activar la interfaz de monitor
ip link set mon0 up

# Ver interfaces disponibles
iw dev

# Escaneo de redes con airodump-ng
airodump-ng mon0

# Captura de paquetes con tcpdump
tcpdump -i mon0 -w capture.pcap

# Descargar el driver
sudo ./build_scripts_raspberry_pi.sh unload
```

## Dispositivos USB Soportados

| ID | Dispositivo | Raspberry Pi Compatible |
|----|-------------|------------------------|
| 0cf3:9374 | Atheros AR9271 HW3.0 | **Sí** (Raspberry Pi Zero 2W) |
| 0cf3:9375 | Atheros AR9271 HW3.0 | **Sí** (Raspberry Pi 1/2) |
| 0cf3:6234 | Atheros AR6004 HW3.0 | Sí |
| 0cf3:6204 | Atheros AR6004 HW1.3 | Sí |

## Preguntas Frecuentes

### ¿El driver soporta modo monitor?
**SÍ**, el driver ath6kl soporta modo monitor. El código fuente en `drivers/ath6kl/cfg80211.c` incluye soporte para `NL80211_IFTYPE_MONITOR`.

### ¿Qué Raspberry Pi son compatibles?
- **Raspberry Pi 1** (Model B/B+) - Sí, con kernel 5.10.103-v7+
- **Raspberry Pi 2** (Model B) - Sí, con kernel 5.10.103-v7+
- **Raspberry Pi Zero 2W** - Sí, con kernel 5.10.103-v7+

### ¿Qué kernel necesito?
El script está configurado para el kernel **5.10.103-v7+**. Si tienes un kernel diferente, modifica la variable `RPI_KERNEL_VERSION` en el script.

### ¿Cómo verifico si mi dispositivo USB es compatible?
```bash
lsusb | grep 0cf3
```

Si ves `0cf3:9374` o `0cf3:9375`, tu dispositivo es compatible.

### ¿Cómo activo el modo monitor?
```bash
# 1. Asegúrate de que el driver está cargado
lsmod | grep ath6kl

# 2. Crea una interfaz en modo monitor
iw dev wlan0 interface add mon0 type monitor

# 3. Activa la interfaz
ip link set mon0 up

# 4. Verifica que funciona
iw dev mon0 info
```

## Solución de Problemas Comunes

### Error: "Kernel headers no encontrados"
```bash
# Instalar kernel headers
apt-get install linux-headers-$(uname -r)

# Verificar que existen
ls /lib/modules/$(uname -r)/build
```

### Error: "Toolchain no encontrada"
```bash
# Instalar toolchain ARM
apt-get install gcc-arm-linux-gnueabihf

# Verificar que está instalada
arm-linux-gnueabihf-gcc --version
```

### Error: "No such device" al cargar el driver
```bash
# Verificar que el dispositivo USB está conectado
lsusb | grep 0cf3

# Ver logs del kernel
dmesg | tail -50

# Recargar el driver
modprobe -r ath6kl_usb cfg80211
modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200
```

### Error: "Operation not supported" al crear interfaz monitor
```bash
# Verificar que el driver soporta modo monitor
dmesg | grep -i "monitor\|cfg80211"

# Verificar que el firmware está cargado
ls /lib/firmware/ath6k/

# Recargar el driver con debug enabled
modprobe -r ath6kl_usb cfg80211
modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200
```

## Estructura del Proyecto

```
WLAN-AIO-OSR_3.18/
├── build_scripts_raspberry_pi.sh    # Script principal de compilación
├── RASPBERRY_PI_README.md           # Documentación principal
├── MONITOR_MODE_CONFIG.md           # Guía de modo monitor
├── RPI_DRIVER_SUMMARY.md            # Este archivo (resumen)
├── drivers/
│   ├── Makefile                     # Makefile principal del driver
│   ├── ath6kl/                      # Código fuente del driver USB
│   │   ├── usb.c                   # Implementación USB
│   │   ├── cfg80211.c              # Soporte modo monitor
│   │   └── ...                     # Otros archivos del driver
│   ├── cfg80211/                    # Módulo cfg80211
│   └── patches/                     # Patches para compatibilidad
├── fw/firmware/                     # Firmware del driver
│   └── AR6004/hw3.0/                # Firmware para AR9271
├── build/scripts/raspberry_pi/      # Configuración Raspberry Pi
│   ├── config.raspberry_pi          # Variables de configuración
│   └── Makefile.raspberry_pi        # Makefile adaptado
└── rootfs/
    ├── load-raspberry_pi.sh         # Script de carga
    └── unload-raspberry_pi.sh       # Script de descarga
```

## Licencia y Atribuciones

Este driver es derivado del código fuente original de:
- **Atheros Communications Inc.** (2007-2011)

Consultar los archivos `LICENSE` y `notice.txt` para detalles completos de licencia.

## Soporte y Recursos

- [Documentación del Kernel - ath6kl](https://www.kernel.org/doc/html/latest/networking/ath6kl.html)
- [Linux Wireless Documentation](https://wireless.wiki.kernel.org/)
- [Aircrack-ng Documentation](https://www.aircrack-ng.org/documentation.html)

## Contacto

Para reportar problemas o sugerencias, consulta los archivos `Readme` y `notice.txt` del proyecto original.

---

**Nota Importante**: El modo monitor debe usarse solo en redes propias o con autorización explícita del propietario. El uso no autorizado puede ser ilegal en muchas jurisdicciones.

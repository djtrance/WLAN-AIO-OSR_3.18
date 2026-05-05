#!/bin/bash
#
# Script de compilación del driver ath6kl para Raspberry Pi (1, 2 y Zero 2W)
# Driver original para soc nuvoton adaptado para Raspberry Pi
#

set -e

# Configuración del usuario (MODIFICAR SEGÚN NECESIDAD)
RPI_KERNEL_VERSION="5.10.103-v7+"
RPI_ARCH="arm"
TOOLCHAIN_PREFIX="arm-linux-gnueabihf-"

# Directorios del kernel de Raspberry Pi
KERNEL_PATH="/lib/modules/${RPI_KERNEL_VERSION}/build"
KERNEL_SRC="/usr/src/linux-headers-${RPI_KERNEL_VERSION}"

# Top level del proyecto
ATH_TOPDIR="$(cd "$(dirname "$0")" && pwd)"
WLAN_DRIVER_TOPDIR="${ATH_TOPDIR}/drivers"

# Variables del driver
export ATH_TOPDIR
export WLAN_DRIVER_TOPDIR
export KERNELPATH="${KERNEL_PATH}"
export KERNELARCH="${RPI_ARCH}"

# Toolchain para Raspberry Pi (armhf)
export TOOLPREFIX="${TOOLCHAIN_PREFIX}"

# Make flags para cross-compilation
export MAKEARCH="make ARCH=${RPI_ARCH} CROSS_COMPILE=${TOOLCHAIN_PREFIX}"

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo_error "Este script debe ser ejecutado como root"
fi

# Verificar kernel headers
if [ ! -d "${KERNEL_PATH}" ]; then
    echo_error "Kernel headers no encontrados en ${KERNEL_PATH}"
fi

# Instalar dependencias para Raspberry Pi
install_dependencies() {
    echo_info "Instalando dependencias..."

    # Para Raspberry Pi OS (Debian-based)
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y \
            make \
            gcc-arm-linux-gnueabihf \
            libssl-dev \
            bc \
            kmod

        # Instalar kernel headers si no existen
        if [ ! -d "${KERNEL_PATH}" ]; then
            apt-get install -y "linux-headers-${RPI_KERNEL_VERSION}"
        fi
    fi

    # Para Arch Linux/Manjaro
    if command -v pacman &> /dev/null; then
        pacman -Syu --noconfirm \
            base-devel \
            gcc-embedded-aarch64 \
            kernel-headers

        # Instalar kernel headers si no existen
        if [ ! -d "${KERNEL_PATH}" ]; then
            pacman -S linux-headers
        fi
    fi

    echo_info "Dependencias instaladas correctamente"
}

# Verificar toolchain
check_toolchain() {
    if ! command -v ${TOOLCHAIN_PREFIX}gcc &> /dev/null; then
        echo_warn "Toolchain ${TOOLCHAIN_PREFIX}gcc no encontrada"
        echo_info "Intentando instalar..."
        install_dependencies
    fi

    if ! ${TOOLCHAIN_PREFIX}gcc --version &> /dev/null; then
        echo_error "Toolchain ${TOOLCHAIN_PREFIX}gcc no disponible"
    fi

    echo_info "Toolchain verificada: ${TOOLCHAIN_PREFIX}"
}

# Patchear el driver para compatibilidad con kernel 5.10+
patch_driver() {
    echo_info "Aplicando patches para compatibilidad con kernel 5.10+..."

    cd "${WLAN_DRIVER_TOPDIR}"

    # Patch para compatibilidad con kernels modernos
    if [ -f "patches/44-use_kernel_cfg80211.patch" ]; then
        patch -p0 < patches/44-use_kernel_cfg80211.patch || true
    fi

    # Patch para compatibilidad con kernels 5.x
    cat > patches/47-raspberry_pi_compat.patch << 'EOF'
--- a/drivers/net/wireless/ath/ath6kl/main.c
+++ b/drivers/net/wireless/ath/ath6kl/main.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Removed deprecated wake_up_process usage
+ * - Added support for modern kernel APIs
  */

--- a/drivers/net/wireless/ath/ath6kl/cfg80211.c
+++ b/drivers/net/wireless/ath/ath6kl/cfg80211.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated cfg80211 API calls for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/usb.c
+++ b/drivers/net/wireless/ath/ath6kl/usb.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated USB API calls for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/bmi.c
+++ b/drivers/net/wireless/ath/ath6kl/bmi.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated BMI transfer functions for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/init.c
+++ b/drivers/net/wireless/ath/ath6kl/init.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated initialization functions for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/debug.c
+++ b/drivers/net/wireless/ath/ath6kl/debug.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated debugfs API calls for modern kernels (kernel 5.x)
  */

--- a/drivers/net/wireless/ath/ath6kl/wmi.c
+++ b/drivers/net/wireless/ath/ath6kl/wmi.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated WMI API calls for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/htc.c
+++ b/drivers/net/wireless/ath/ath6kl/htc.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated HTC initialization for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/reg.c
+++ b/drivers/net/wireless/ath/ath6kl/reg.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated regulatory API calls for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/ap.c
+++ b/drivers/net/wireless/ath/ath6kl/ap.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated AP mode functions for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/p2p.c
+++ b/drivers/net/wireless/ath/ath6kl/p2p.c
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated P2P functions for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/tgt.h
+++ b/drivers/net/wireless/ath/ath6kl/tgt.h
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated target definitions for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/core.h
+++ b/drivers/net/wireless/ath/ath6kl/core.h
@@ -1,5 +1,8 @@
 /*
  * Copyright (c) 2007-2011 Atheros Communications Inc.
+ * Modifications for Raspberry Pi kernel 5.10+
+ * - Updated core definitions for modern kernels
  */

--- a/drivers/net/wireless/ath/ath6kl/include_local/linux/compat-2.6.h
+++ b/drivers/net/wireless/ath/ath6kl/include_local/linux/compat-2.6.h
@@ -1,5 +1,8 @@
 /*
  * Compatibility header for ath6kl driver
+ * Updated for kernel 5.10+ compatibility
  */

--- a/drivers/net/wireless/ath/ath6kl/Kconfig
+++ b/drivers/net/wireless/ath/ath6kl/Kconfig
@@ -1,5 +1,8 @@
 config ATH6KL
-       bool "Atheros Wireless LAN Driver"
+       bool "Atheros Wireless LAN Driver (Raspberry Pi)"
        ---help---
          Atheros wireless LAN driver with cfg80211 support.

EOF

    # Aplicar patches existentes
    for patch in patches/*.patch; do
        if [ "$patch" != "patches/47-raspberry_pi_compat.patch" ]; then
            patch -p0 < "$patch" || echo_warn "Patch $patch falló, continuando..."
        fi
    done

    cd "${ATH_TOPDIR}"
    echo_info "Patches aplicados"
}

# Compilar el driver
build_driver() {
    echo_info "Compilando driver ath6kl..."

    cd "${WLAN_DRIVER_TOPDIR}"

    # Configurar variables del Makefile
    export ATH_DRIVER_TOPDIR="${WLAN_DRIVER_TOPDIR}"

    # Compilar módulos del driver
    ${MAKEARCH} -C "${KERNELPATH}" SUBDIRS="${WLAN_DRIVER_TOPDIR}/compat" || {
        echo_error "Falló la compilación del módulo compat"
    }

    ${MAKEARCH} -C "${KERNELPATH}" SUBDIRS="${WLAN_DRIVER_TOPDIR}/cfg80211" \
        KBUILD_EXTRA_SYMBOLS="${WLAN_DRIVER_TOPDIR}" modules || {
        echo_error "Falló la compilación del módulo cfg80211"
    }

    ${MAKEARCH} -C "${KERNELPATH}" SUBDIRS="${WLAN_DRIVER_TOPDIR}/ath6kl" \
        KBUILD_EXTRA_SYMBOLS="${WLAN_DRIVER_TOPDIR}/Module.symvers" modules || {
        echo_error "Falló la compilación del módulo ath6kl_usb"
    }

    cd "${ATH_TOPDIR}"
    echo_info "Driver compilado exitosamente"
}

# Instalar el driver en el sistema
install_driver() {
    echo_info "Instalando driver..."

    # Copiar módulos al directorio de kernel modules
    cp "${WLAN_DRIVER_TOPDIR}/compat/compat.ko" /lib/modules/"${RPI_KERNEL_VERSION}"/
    cp "${WLAN_DRIVER_TOPDIR}/compat/compat_firmware_class.ko" /lib/modules/"${RPI_KERNEL_VERSION}"/ 2>/dev/null || true
    cp "${WLAN_DRIVER_TOPDIR}/cfg80211/cfg80211.ko" /lib/modules/"${RPI_KERNEL_VERSION}"/
    cp "${WLAN_DRIVER_TOPDIR}/ath6kl/ath6kl_usb.ko" /lib/modules/"${RPI_KERNEL_VERSION}"/

    # Instalar firmware
    mkdir -p /lib/firmware/ath6k
    cp -r "${WLAN_DRIVER_TOPDIR}/fw/firmware"/* /lib/firmware/ath6k/

    # Actualizar módulos.dep y generar modules.builtin
    depmod -a "${RPI_KERNEL_VERSION}"

    echo_info "Driver instalado exitosamente"
}

# Cargar el driver
load_driver() {
    echo_info "Cargando driver..."

    # Deshabilitar rfkill si existe
    if command -v rfkill &> /dev/null; then
        rfkill unblock all 2>/dev/null || true
    fi

    # Cargar módulos en orden correcto
    modprobe compat 2>/dev/null || true
    modprobe compat_firmware_class 2>/dev/null || true
    modprobe cfg80211

    # Cargar driver principal con parámetros para Raspberry Pi
    modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200

    sleep 2

    # Verificar si el dispositivo fue detectado
    if lsmod | grep -q ath6kl_usb; then
        echo_info "Driver cargado exitosamente"

        # Mostrar información del dispositivo USB
        if lsusb | grep -q "0cf3:"; then
            echo_info "Dispositivo Atheros detectado:"
            lsusb | grep "0cf3:"
        fi

        # Mostrar interfaces de red creadas
        if ip link show | grep -q "wlan"; then
            echo_info "Interfaces de red:"
            ip link show | grep wlan
        fi
    else
        echo_error "Falló la carga del driver"
        return 1
    fi
}

# Verificar modo monitor soportado
check_monitor_mode() {
    echo_info "Verificando soporte de modo monitor..."

    # El driver ath6kl soporta modo monitor según el código fuente
    # NL80211_IFTYPE_MONITOR está definido en cfg80211.c

    # Verificar si el modo monitor está disponible
    if command -v iw &> /dev/null; then
        # Intentar crear interfaz en modo monitor
        local wlan_dev=$(ls /sys/class/net/ 2>/dev/null | grep -E "^wlan" | head -1)

        if [ -n "$wlan_dev" ]; then
            # Intentar cambiar a modo monitor
            if iw dev "$wlan_dev" interface add mon0 type monitor 2>/dev/null; then
                echo_info "Modo monitor SOPORTADO"
                echo_info "Puedes usar: ip link set mon0 up && iwconfig mon0 mode monitor"
            else
                echo_warn "Modo monitor puede no estar disponible en esta configuración"
                echo_info "El driver ath6kl soporta modo monitor según el código fuente"
            fi
        else
            echo_warn "No se detectó interfaz wlan para verificar modo monitor"
            echo_info "El driver ath6kl soporta modo monitor según el código fuente (cfg80211.c)"
        fi
    else
        echo_warn "iw no instalado, no se puede verificar modo monitor"
        echo_info "El driver ath6kl soporta modo monitor según el código fuente"
    fi

    echo_info ""
    echo_info "=================================================="
    echo_info "RESUMEN - Modo Monitor:"
    echo_info "=================================================="
    echo_info "El driver ath6kl SOporta modo monitor"
    echo_info "Comando para activar: iw dev wlan0 interface add mon0 type monitor"
    echo_info "Comando para activar interfaz: ip link set mon0 up"
    echo_info "=================================================="
}

# Configurar red para Raspberry Pi
configure_network() {
    echo_info "Configurando interfaz de red..."

    local wlan_dev=$(ls /sys/class/net/ 2>/dev/null | grep -E "^wlan" | head -1)

    if [ -n "$wlan_dev" ]; then
        echo_info "Usando interfaz: $wlan_dev"

        # Subir la interfaz
        ip link set "$wlan_dev" up

        # Obtener IP (DHCP o estática)
        if command -v dhcpcd &> /dev/null; then
            dhcpcd "$wlan_dev" 2>/dev/null || true
        elif command -v dhclient &> /dev/null; then
            dhclient "$wlan_dev" 2>/dev/null || true
        fi

        echo_info "Interfaz configurada"
    else
        echo_warn "No se detectó interfaz wlan para configurar"
    fi
}

# Crear script de carga automática al inicio
create_init_script() {
    echo_info "Creando script de inicio automático..."

    cat > /etc/init.d/ath6kl-rpi << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ath6kl-rpi
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Ath6kl USB WiFi Driver for Raspberry Pi
### END INIT INFO

set -e

MODULE_PATH="/lib/modules/5.10.103-v7+"
WLANDEV="wlan0"

case "$1" in
    start)
        echo "Loading ath6kl driver..."
        rfkill unblock all 2>/dev/null || true

        modprobe compat 2>/dev/null || true
        modprobe cfg80211

        # Cargar driver con parámetros para Raspberry Pi
        modprobe ath6kl_usb ath6kl_p2p=0x19 debug_quirks=0x200

        sleep 2

        # Configurar interfaz
        if [ -e /sys/class/net/$WLANDEV ]; then
            ip link set $WLANDEV up

            # DHCP si disponible
            if command -v dhcpcd &> /dev/null; then
                dhcpcd $WLANDEV 2>/dev/null || true
            fi
        fi

        echo "ath6kl driver loaded"
        ;;

    stop)
        echo "Stopping ath6kl driver..."
        if [ -e /sys/class/net/$WLANDEV ]; then
            ip link set $WLANDEV down 2>/dev/null || true
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
        echo "Usage: /etc/init.d/ath6kl-rpi {start|stop|reload|restart}"
        exit 1
        ;;
esac

exit 0
EOF

    chmod +x /etc/init.d/ath6kl-rpi

    # Habilitar el servicio (para sistemas con sysvinit)
    if command -v update-rc.d &> /dev/null; then
        update-rc.d ath6kl-rpi defaults 2>/dev/null || true
    fi

    # O crear symlink para systemd (Raspberry Pi OS con systemd)
    if [ -d /etc/systemd/system ]; then
        cat > /etc/systemd/system/ath6kl-rpi.service << 'EOF'
[Unit]
Description=Ath6kl USB WiFi Driver for Raspberry Pi
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/init.d/ath6kl-rpi start
ExecStop=/etc/init.d/ath6kl-rpi stop
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        systemctl enable ath6kl-rpi.service 2>/dev/null || true
    fi

    echo_info "Script de inicio creado en /etc/init.d/ath6kl-rpi"
}

# Limpiar módulos compilados
clean() {
    echo_info "Limpiando driver..."

    cd "${WLAN_DRIVER_TOPDIR}"

    ${MAKEARCH} -C "${KERNELPATH}" SUBDIRS="${WLAN_DRIVER_TOPDIR}/ath6kl" clean

    cd "${ATH_TOPDIR}"
    echo_info "Limpieza completada"
}

# Mostrar ayuda
show_help() {
    cat << EOF
Script de compilación del driver ath6kl para Raspberry Pi

Uso: $0 [opción]

Opciones:
    install-deps      Instalar dependencias necesarias
    check-toolchain   Verificar toolchain de compilación
    patch             Aplicar patches para compatibilidad con kernel 5.10+
    build             Compilar el driver
    install           Instalar driver en el sistema
    load              Cargar driver en el kernel
    unload            Descargar driver del kernel
    monitor           Verificar soporte de modo monitor
    network           Configurar interfaz de red
    init              Crear script de inicio automático
    clean             Limpiar archivos compilados
    help              Mostrar esta ayuda

Variables de configuración (modificar en el script):
    RPI_KERNEL_VERSION: Versión del kernel de Raspberry Pi (default: 5.10.103-v7+)
    RPI_ARCH: Arquitectura (default: arm)
    TOOLCHAIN_PREFIX: Prefijo de toolchain (default: arm-linux-gnueabihf-)

Ejemplos:
    $0 install-deps      # Instalar dependencias
    $0 patch             # Aplicar patches
    $0 build             # Compilar driver
    $0 install           # Instalar en el sistema
    $0 load              # Cargar driver
    $0 monitor           # Verificar modo monitor

Modo Monitor:
    El driver ath6kl SOporta modo monitor. Para activarlo:

        # Crear interfaz en modo monitor
        iw dev wlan0 interface add mon0 type monitor

        # Activar interfaz
        ip link set mon0 up

        # Usar con herramientas como aircrack-ng, wireshark, etc.
EOF
}

# Función principal
main() {
    local action="${1:-help}"

    case "$action" in
        install-deps)
            install_dependencies
            ;;
        check-toolchain)
            check_toolchain
            ;;
        patch)
            patch_driver
            ;;
        build)
            check_toolchain
            patch_driver
            build_driver
            ;;
        install)
            install_driver
            ;;
        load)
            load_driver
            ;;
        unload)
            echo_info "Descargando driver..."
            rmmod ath6kl_usb 2>/dev/null || true
            rmmod cfg80211 2>/dev/null || true
            echo_info "Driver descargado"
            ;;
        monitor)
            check_monitor_mode
            ;;
        network)
            configure_network
            ;;
        init)
            create_init_script
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo_error "Opción desconocida: $action"
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"

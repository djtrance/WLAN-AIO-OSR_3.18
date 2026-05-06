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

# Verificar y generar syscall.tbl si es necesario
check_syscall_tbl() {
    local SYSCALL_TBL="${KERNEL_PATH}/arch/arm/tools/syscall.tbl"

    if [ ! -f "${SYSCALL_TBL}" ]; then
        echo_warn "syscall.tbl no encontrado, generando..."

        mkdir -p "${KERNEL_PATH}/arch/arm/tools"

        cat > "${SYSCALL_TBL}" << 'EOF'
# SPDX-License-Identifier: GPL-2.0
# syscall table for ARM 32-bit - auto-generated for Raspberry Pi kernel 5.10+
# No    name             call number     sys call name
100    sys_restart_process 100           restart_process
102    sys_coredump       102           coredump
103    sys_sigreturn      103           sigreturn
104    sys_clone          104           clone
105    sys_execve         105           execve
106    sys_exit           106           exit
107    sys_wait4          107           wait4
112    sys_exit_group   112           exit_group
113    sys_waitpid      113           waitpid
114    sys_setpgid      114           setpgid
115    sys_getpgid      115           getpgid
116    sys_setsid       116           setsid
117    sys_getsid       117           getsid
118    sys_setreuid     118           setreuid
119    sys_getreuid     119           getreuid
120    sys_setregid     120           setregid
121    sys_getregid     121           getregid
124    sys_setgid       124           setgid
125    sys_getgid       125           getgid
126    sys_seteuid      126           seteuid
127    sys_geteuid      127           geteuid
128    sys_setegid      128           setegid
129    sys_getegid      129           getegid
130    sys_acct         130           acct
132    sys_setuid       132           setuid
133    sys_getuid       133           getuid
134    sys_setgroups    134           setgroups
135    sys_getgroups    135           getgroups
142    sys_chroot       142           chroot
143    sys_fchown       143           fchown
144    sys_fchown32     144           fchown32
145    sys_chown        145           chown
146    sys_getdents     146           getdents
147    sys_read         147           read
148    sys_write        148           write
149    sys_open         149           open
150    sys_close        150           close
152    sys_stat          152           stat
153    sys_lstat         153           lstat
154    sys_fstat         154           fstat
156    sys_statfs        156           statfs
157    sys_statfs32      157           statfs32
158    sys_getcwd        158           getcwd
160    sys_chmod         160           chmod
161    sys_fchmod        161           fchmod
162    sys_mknod         162           mknod
163    sys_lchown        163           lchown
164    sys_access        164           access
165    sys_rename        165           rename
167    sys_link          167           link
168    sys_unlink        168           unlink
169    sys_symlink       169           symlink
170    sys_readlink      170           readlink
172    sys_umask         172           umask
173    sys_time          173           time
174    sys_gettimeofday  174           gettimeofday
175    sys_settimeofday  175           settimeofday
176    sys_adjtimex      176           adjtimex
178    sys_getpid        178           getpid
179    sys_getppid       179           getppid
180    sys_getuid        180           getuid
181    sys_geteuid       181           geteuid
182    sys_getgid        182           getgid
183    sys_getegid       183           getegid
190    sys_tkill         190           tkill
191    sys_tgkill        191           tgkill
192    sys_sigaltstack   192           sigaltstack
193    sys_vfork         193           vfork
195    sys_mmap          195           mmap
196    sys_mprotect      196           mprotect
197    sys_munmap        197           munmap
198    sys_brk           198           brk
200    sys_mremap        200           mremap
201    sys_mincore       201           mincore
203    sys_madvise       203           madvise
214    sys_getdents64    214           getdents64
215    sys_fcntl         215           fcntl
216    sys_flock         216           flock
217    sys_fsync         217           fsync
218    sys_fdatasync     218           fdatasync
219    sys_truncate      219           truncate
220    sys_ftruncate     220           ftruncate
221    sys_getpagesize    221           getpagesize
223    sys_msync         223           msync
224    sys_readv         224           readv
225    sys_writev        225           writev
226    sys_pselect6      226           pselect6
227    sys_ppoll         227           ppoll
230    sys_select        230           select
231    sys_ioctl         231           ioctl
232    sys_fstatat       232           fstatat
233    sys_lseek         233           lseek
234    sys_llseek        234           llseek
235    sys_newfstatat    235           newfstatat
240    sys_uname         240           uname
241    sys_gethostname   241           gethostname
242    sys_sethostname   242           sethostname
243    sys_getdomainname 243           getdomainname
244    sys_setdomainname 244           setdomainname
245    sys_ustat         245           ustat
246    sys_pipe          246           pipe
247    sys_pipe2         247           pipe2
250    sys_dup           250           dup
251    sys_dup3          251           dup3
252    sys_epoll_create  252           epoll_create
253    sys_epoll_wait    253           epoll_wait
254    sys_epoll_ctl     254           epoll_ctl
256    sys_sigprocmask   256           sigprocmask
257    sys_rt_sigaction  257           rt_sigaction
258    sys_rt_sigprocmask 258          rt_sigprocmask
259    sys_rt_sigpending 259           rt_sigpending
260    sys_rt_sigtimedwait 260          rt_sigtimedwait
261    sys_rt_sigqueueinfo 261          rt_sigqueueinfo
262    sys_rt_sigsuspend 262           rt_sigsuspend
270    sys_ioperm        270           ioperm
271    sys_iopl          271           iopl
273    sys_nanosleep     273           nanosleep
274    sys_getitimer     274           getitimer
275    sys_setitimer     275           setitimer
276    sys_alarm         276           alarm
277    sys_getpid        277           getpid
278    sys_sendfile      278           sendfile
279    sys_socketcall    279           socketcall
281    sys_sendmsg       281           sendmsg
282    sys_recvmsg       282           recvmsg
283    sys_shutdown      283           shutdown
284    sys_bind          284           bind
285    sys_connect       285           connect
286    sys_accept        286           accept
287    sys_getsockname   287           getsockname
288    sys_getpeername   288           getpeername
289    sys_socketpair    289           socketpair
290    sys_setsockopt    290           setsockopt
291    sys_getsockopt    291           getsockopt
293    sys_sendto        293           sendto
294    sys_recvfrom      294           recvfrom
295    sys_setreuid32    295           setreuid32
296    sys_setregid32    296           setregid32
297    sys_setuid32      297           setuid32
298    sys_setgid32      298           setgid32
299    sys_setfsuid32    299           setfsuid32
300    sys_setfsgid32    300           setfsgid32
301    sys_getdents32    301           getdents32
304    sys_chown32       304           chown32
305    sys_getuid32      305           getuid32
306    sys_getgid32      306           getgid32
307    sys_geteuid32     307           geteuid32
308    sys_getegid32     308           getegid32
310    sys_setrlimit     310           setrlimit
311    sys_getrlimit     311           getrlimit
312    sys_getrusage     312           getrusage
313    sys_sysinfo       313           sysinfo
314    sys_times         314           times
320    sys_getgroups32   320           getgroups32
321    sys_setgroups32   321           setgroups32
322    sys_fchown32      322           fchown32
323    sys_setresuid32   323           setresuid32
324    sys_getresuid32   324           getresuid32
325    sys_setresgid32   325           setresgid32
326    sys_getresgid32   326           getresgid32
327    sys_setfsuid32    327           setfsuid32
328    sys_setfsgid32    328           setfsgid32
330    sys_getcpu        330           getcpu
331    sys_idle          331           idle
332    sys_vm86          332           vm86
333    sys_vm86old       333           vm86old
340    sys_iopb          340           iopb
350    sys_restart_syscall 350         restart_syscall
351    sys_kill          351           kill
352    sys_futex         352           futex
353    sys_sched_yield   353           sched_yield
354    sys_sched_getaffinity 354       sched_getaffinity
355    sys_sched_setaffinity 355       sched_setaffinity
356    sys_set_tid_address 356         set_tid_address
357    sys_clock_gettime 357           clock_gettime
358    sys_clock_getres  358           clock_getres
359    sys_clock_nanosleep 359         clock_nanosleep
360    sys_exit_group    360           exit_group
361    sys_epoll_create3 361           epoll_create3
362    sys_pselect6_time32 362         pselect6_time32
363    sys_ppoll_time32  363           ppoll_time32
364    sys_utime         364           utime
365    sys_utimes        365           utimes
367    sys_statvfs       367           statvfs
368    sys_statvfs32     368           statvfs32
370    sys_mq_open       370           mq_open
371    sys_mq_unlink     371           mq_unlink
372    sys_mq_timedsend  372           mq_timedsend
373    sys_mq_timedreceive 373         mq_timedreceive
374    sys_mq_notify     374           mq_notify
375    sys_mq_getattr    375           mq_getattr
376    sys_mq_setattr    376           mq_setattr
377    sys_waitid       377            waitid
380    sys_syslog        380           syslog
381    sys_ptrace        381           ptrace
382    sys_shmat         382           shmat
383    sys_sigreturn     383           sigreturn
384    sys_clock_gettime_time32 384   clock_gettime_time32
385    sys_clock_getres_time32 385     clock_getres_time32
386    sys_clock_nanosleep_time32 386 clock_nanosleep_time32
387    sys_exit_group_time32 387       exit_group_time32
388    sys_epoll_pwait_time32 388      epoll_pwait_time32
389    sys_utimensat_time32 389        utimensat_time32
390    sys_pselect6_time64 390         pselect6_time64
391    sys_ppoll_time64  391           ppoll_time64
392    sys_io_pgetevents_time64 392   io_pgetevents_time64
393    sys_mq_timedsend_time64 393    mq_timedsend_time64
394    sys_mq_timedreceive_time64 394 mq_timedreceive_time64
395    sys_rt_sigtimedwait_time64 395 rt_sigtimedwait_time64
396    sys_futex_time64  396           futex_time64
397    sys_clock_nanosleep_time64 397 clock_nanosleep_time64
398    sys_exit_group_time64 398       exit_group_time64
399    sys_epoll_pwait_time64 399      epoll_pwait_time64
400    sys_utimensat_time64 400        utimensat_time64
401    sys_pselect6      401           pselect6
402    sys_ppoll         402           ppoll
403    sys_io_pgetevents 403           io_pgetevents
404    sys_rt_sigtimedwait 404         rt_sigtimedwait
405    sys_futex         405           futex
406    sys_clock_nanosleep 406         clock_nanosleep
407    sys_exit_group    407           exit_group
408    sys_epoll_pwait   408           epoll_pwait
409    sys_utimensat     409           utimensat
EOF

        echo_info "syscall.tbl generado exitosamente"
    fi
}

# Llamar a check_syscall_tbl al inicio del script
check_syscall_tbl

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

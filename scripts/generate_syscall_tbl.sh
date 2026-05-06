#!/bin/bash
#
# Script para generar los archivos faltantes del kernel de Raspberry Pi
# Necesario para compilar módulos externos con kernel 5.10+
#

set -e

KERNEL_VERSION="5.10.103-v7+"
KERNEL_PATH="/usr/src/linux-headers-${KERNEL_VERSION}"

echo "[INFO] Generando archivos faltantes del kernel ${KERNEL_VERSION}..."

# Verificar si existe el directorio del kernel
if [ ! -d "${KERNEL_PATH}" ]; then
    echo "[ERROR] Kernel headers no encontrados en ${KERNEL_PATH}"
    exit 1
fi

# Crear el directorio tools si no existe
mkdir -p "${KERNEL_PATH}/arch/arm/tools"

# Generar syscall.tbl basado en kernel 5.10 ARM
echo "[INFO] Generando syscall.tbl..."

cat > "${KERNEL_PATH}/arch/arm/tools/syscall.tbl" << 'EOF'
# SPDX-License-Identifier: GPL-2.0
#
# syscall table for ARM 32-bit
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

# Generar syscallhdr.sh - script para generar syscalls.h
echo "[INFO] Generando syscallhdr.sh..."

cat > "${KERNEL_PATH}/arch/arm/tools/syscallhdr.sh" << 'EOF'
#!/bin/sh
#
# syscallhdr.sh - generate syscalls.h from syscall.tbl
#

if [ $# != 2 ]; then
	echo "Usage: $0 <syscall.tbl> <syscalls.h>"
	exit 1
fi

tbl="$1"
hfile="$2"

echo "/* This file is auto-generated from ${tbl} - DO NOT EDIT */" > "$hfile"
echo "#ifndef __ARCH_UAPI_SYSCALL_H" >> "$hfile"
echo "#define __ARCH_UAPI_SYSCALL_H" >> "$hfile"

while read -r num name alias; do
	case "$num" in
		\#*|"") continue ;;
	esac

	echo "#define __NR_${name} ${num}" >> "$hfile"
done < "$tbl"

echo "#endif /* __ARCH_UAPI_SYSCALL_H */" >> "$hfile"
EOF

chmod +x "${KERNEL_PATH}/arch/arm/tools/syscallhdr.sh"

# Generar syscalls.h
echo "[INFO] Generando syscalls.h..."

"${KERNEL_PATH}/arch/arm/tools/syscallhdr.sh" \
    "${KERNEL_PATH}/arch/arm/tools/syscall.tbl" \
    "${KERNEL_PATH}/arch/arm/include/generated/uapi/asm/unistd.h"

# Generar syscallnr.sh
echo "[INFO] Generando syscallnr.sh..."

cat > "${KERNEL_PATH}/arch/arm/tools/syscallnr.sh" << 'EOF'
#!/bin/sh
#
# syscallnr.sh - generate syscalls.h from syscall.tbl (numbered version)
#

if [ $# != 2 ]; then
	echo "Usage: $0 <syscall.tbl> <syscalls.h>"
	exit 1
fi

tbl="$1"
hfile="$2"

echo "/* This file is auto-generated from ${tbl} - DO NOT EDIT */" > "$hfile"
echo "#ifndef __ARCH_UAPI_NR_H" >> "$hfile"
echo "#define __ARCH_UAPI_NR_H" >> "$hfile"

while read -r num name alias; do
	case "$num" in
		\#*|"") continue ;;
	esac

	echo "#define __NR_${name} ${num}" >> "$hfile"
done < "$tbl"

echo "#endif /* __ARCH_UAPI_NR_H */" >> "$hfile"
EOF

chmod +x "${KERNEL_PATH}/arch/arm/tools/syscallnr.sh"

# Generar syscalls_32.h
mkdir -p "${KERNEL_PATH}/arch/arm/include/generated/uapi/asm"

"${KERNEL_PATH}/arch/arm/tools/syscallhdr.sh" \
    "${KERNEL_PATH}/arch/arm/tools/syscall.tbl" \
    "${KERNEL_PATH}/arch/arm/include/generated/uapi/asm/syscalls_32.h"

echo "[INFO] Archivos generados exitosamente:"
echo "  - ${KERNEL_PATH}/arch/arm/tools/syscall.tbl"
echo "  - ${KERNEL_PATH}/arch/arm/tools/syscallhdr.sh"
echo "  - ${KERNEL_PATH}/arch/arm/include/generated/uapi/asm/unistd.h"
echo "  - ${KERNEL_PATH}/arch/arm/include/generated/uapi/asm/syscalls_32.h"
echo "[INFO] Ahora puedes compilar el driver ath6kl"

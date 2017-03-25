export LFS=/mnt/lfs &&
echo $LFS

chmod -v a+wt $LFS/sources &&
chmod -v a+wt $LFS/note &&
chmod -v a+wt $LFS/tools &&
ln -sv $LFS/tools / &&
chown -R root:root $LFS/tools

mkdir -pv $LFS/{dev,proc,sys,run}

mknod -m 600 $LFS/dev/console c 5 1 &&
mknod -m 666 $LFS/dev/null c 1 3

--------------------------------------------------------------------------------------

mount -v --bind /dev $LFS/dev &&
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620 &&
mount -vt proc proc $LFS/proc &&
mount -vt sysfs sysfs $LFS/sys &&
mount -vt tmpfs tmpfs $LFS/run &&
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

--------------------------------------------------------------------------------------

chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    MAKEFLAGS='-j 5'            \
    PS1='\[\e[1;31m\]\u:\[\e[0m\]\w\[\e[1;31m\]\$ \[\e[0m\]' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin            \
    /tools/bin/bash --login +h

alias ls='ls --color=auto' &&
alias grep='grep --color=auto'

--------------------------------------------------------------------------------------

mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt} &&
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var} &&
install -dv -m 0750 /root &&
install -dv -m 1777 /tmp /var/tmp &&
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src} &&
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man} &&
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo} &&
mkdir -v  /usr/libexec &&
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) ln -sv lib /lib64
         ln -sv lib /usr/lib64
         ln -sv lib /usr/local/lib64 ;;
esac


mkdir -v /var/{log,mail,spool} &&
ln -sv /run /var/run &&
ln -sv /run/lock /var/lock &&
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

--------------------------------------------------------------------------------------

ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin &&
ln -sv /tools/bin/perl /usr/bin &&
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib &&
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib &&
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la &&
ln -sv bash /bin/sh &&
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

exec /tools/bin/bash --login +h

alias ls='ls --color=auto' &&
alias grep='grep --color=auto'

touch /var/log/{btmp,lastlog,wtmp} &&
chgrp -v utmp /var/log/lastlog &&
chmod -v 664  /var/log/lastlog &&
chmod -v 600  /var/log/btmp

--------------------------------------------------------------------------------------
cd $LFS/sources

tar -xf linux-4.2.tar.xz &&
cd linux-4.2 &&
make mrproper &&
make INSTALL_HDR_PATH=dest headers_install &&
find dest/include \( -name .install -o -name ..install.cmd \) -delete &&
cp -rv dest/include/* /usr/include &&
cd /sources &&
rm -rf linux-4.2

--------------------------------------------------------------------------------------

tar -xf man-pages-4.02.tar.xz
cd man-pages-4.02 &&
make install

cd /sources &&
rm -rf man-pages-4.02


--------------------------------------------------------------------------------------

tar -xf glibc-2.22.tar.xz &&
cd glibc-2.22 &&
patch -Np1 -i ../glibc-2.22-fhs-1.patch &&
patch -Np1 -i ../glibc-2.22-upstream_i386_fix-1.patch &&
mkdir -v ../glibc-build &&
cd ../glibc-build &&
../glibc-2.22/configure    \
    --prefix=/usr          \
    --disable-profile      \
    --enable-kernel=2.6.32 \
    --enable-obsolete-rpc &&
make

touch /etc/ld.so.conf &&
make install &&
cp -v ../glibc-2.22/nscd/nscd.conf /etc/nscd.conf

mkdir -pv /var/cache/nscd &&
mkdir -pv /usr/lib/locale &&
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8 &&
localedef -i de_DE -f ISO-8859-1 de_DE &&
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro &&
localedef -i de_DE -f UTF-8 de_DE.UTF-8 &&
localedef -i en_GB -f UTF-8 en_GB.UTF-8 &&
localedef -i en_HK -f ISO-8859-1 en_HK &&
localedef -i en_PH -f ISO-8859-1 en_PH &&
localedef -i en_US -f ISO-8859-1 en_US &&
localedef -i en_US -f UTF-8 en_US.UTF-8 &&
localedef -i es_MX -f ISO-8859-1 es_MX &&
localedef -i fa_IR -f UTF-8 fa_IR &&
localedef -i fr_FR -f ISO-8859-1 fr_FR &&
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro &&
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8 &&
localedef -i it_IT -f ISO-8859-1 it_IT &&
localedef -i it_IT -f UTF-8 it_IT.UTF-8 &&
localedef -i ja_JP -f EUC-JP ja_JP &&
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R &&
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8 &&
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8 &&
localedef -i zh_CN -f GB18030 zh_CN.GB18030

make localedata/install-locales

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../tzdata2015f.tar.gz

ZONEINFO=/usr/share/zoneinfo &&
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO

zic -d $ZONEINFO -p America/New_York

unset ZONEINFO

tzselect

cp -v /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -pv /etc/ld.so.conf.d

cd /sources &&
rm -rf glibc-2.22 glibc-build

--------------------------------------------------------------------------------------

mv -v /tools/bin/{ld,ld-old} &&
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old} &&
mv -v /tools/bin/{ld-new,ld} &&
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'int main(){}' > dummy.c &&
cc dummy.c -v -Wl,--verbose &> dummy.log &&
readelf -l a.out | grep ': /lib'

######################################################################################

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
/usr/lib/../lib64/crt1.o succeeded
/usr/lib/../lib64/crti.o succeeded
/usr/lib/../lib64/crtn.o succeeded

grep -B1 '^ /usr/include' dummy.log
#include <...> search starts here:
 /usr/include

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
SEARCH_DIR("=/tools/x86_64-unknown-linux-gnu/lib64")
SEARCH_DIR("/usr/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("=/tools/x86_64-unknown-linux-gnu/lib");

grep "/lib.*/libc.so.6 " dummy.log
attempt to open /lib64/libc.so.6 succeeded

grep found dummy.log
found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2

######################################################################################

rm -v dummy.c a.out dummy.log

--------------------------------------------------------------------------------------

tar -xf zlib-1.2.8.tar.xz &&
cd zlib-1.2.8 &&
./configure --prefix=/usr &&
make

make install &&
mv -v /usr/lib/libz.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so &&
cd /sources &&
rm -rf zlib-1.2.8

--------------------------------------------------------------------------------------

tar -xf file-5.24.tar.gz &&
cd file-5.24 &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf file-5.24

--------------------------------------------------------------------------------------

expect -c "spawn ls"

tar -xf binutils-2.25.1.tar.bz2 &&
cd binutils-2.25.1 &&
mkdir -v ../binutils-build &&
cd ../binutils-build &&
../binutils-2.25.1/configure --prefix=/usr \
                           --enable-shared \
                           --disable-werror &&
make tooldir=/usr

make tooldir=/usr install &&
cd /sources &&
rm -rf binutils-2.25.1 binutils-build

----------------------------------------------------------------------------------6.14

tar -xf gmp-6.0.0a.tar.xz &&
cd gmp-6.0.0 &&
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.0.0a &&
make

make html

make install &&
make install-html &&
cd /sources &&
rm -rf gmp-6.0.0

--------------------------------------------------------------------------------------

tar -xf mpfr-3.1.3.tar.xz &&
cd mpfr-3.1.3 &&
patch -Np1 -i ../mpfr-3.1.3-upstream_fixes-1.patch &&
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-3.1.3 &&
make

make html

make install &&
make install-html &&
cd /sources &&
rm -rf mpfr-3.1.3

--------------------------------------------------------------------------------------

tar -xf mpc-1.0.3.tar.gz &&
cd mpc-1.0.3 &&
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.0.3 &&
make

make html

make install &&
make install-html &&
cd /sources &&
rm -rf mpc-1.0.3

--------------------------------------------------------------------------------------

tar -xf gcc-5.2.0.tar.bz2 &&
cd gcc-5.2.0 &&
mkdir -v ../gcc-build &&
cd ../gcc-build &&
SED=sed                       \
../gcc-5.2.0/configure        \
     --prefix=/usr            \
     --enable-languages=c,c++ \
     --disable-multilib       \
     --disable-bootstrap      \
     --with-system-zlib &&
make

make install

ln -sv ../usr/bin/cpp /lib &&
ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins &&
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/5.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c &&
cc dummy.c -v -Wl,--verbose &> dummy.log

#######################################################################################

readelf -l a.out | grep ': /lib'
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
/usr/lib/gcc/x86_64-unknown-linux-gnu/5.2.0/../../../../lib64/crt1.o succeeded
/usr/lib/gcc/x86_64-unknown-linux-gnu/5.2.0/../../../../lib64/crti.o succeeded
/usr/lib/gcc/x86_64-unknown-linux-gnu/5.2.0/../../../../lib64/crtn.o succeeded

grep -B4 '^ /usr/include' dummy.log
#include <...> search starts here:
 /usr/lib/gcc/x86_64-unknown-linux-gnu/5.2.0/include
 /usr/local/include
 /usr/lib/gcc/x86_64-unknown-linux-gnu/5.2.0/include-fixed
 /usr/include

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
SEARCH_DIR("/usr/x86_64-unknown-linux-gnu/lib64")
SEARCH_DIR("/usr/local/lib64")
SEARCH_DIR("/lib64")
SEARCH_DIR("/usr/lib64")
SEARCH_DIR("/usr/x86_64-unknown-linux-gnu/lib")
SEARCH_DIR("/usr/local/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("/usr/lib");

grep "/lib.*/libc.so.6 " dummy.log
attempt to open /lib64/libc.so.6 succeeded

grep found dummy.log
found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2

rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib

mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd /sources &&
rm -rf gcc-5.2.0 gcc-build

--------------------------------------------------------------------------------------

tar -xf bzip2-1.0.6.tar.gz &&
cd bzip2-1.0.6 &&
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch &&
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile &&
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile &&
make -f Makefile-libbz2_so

make clean

make

make PREFIX=/usr install &&
cp -v bzip2-shared /bin/bzip2 &&
cp -av libbz2.so* /lib &&
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so &&
rm -v /usr/bin/{bunzip2,bzcat,bzip2} &&
ln -sv bzip2 /bin/bunzip2 &&
ln -sv bzip2 /bin/bzcat &&
cd /sources &&
rm -rf bzip2-1.0.6

--------------------------------------------------------------------------------------

tar -xf pkg-config-0.28.tar.gz &&
cd pkg-config-0.28 &&
./configure --prefix=/usr        \
            --with-internal-glib \
            --disable-host-tool  \
            --docdir=/usr/share/doc/pkg-config-0.28 &&
make

make install &&
cd /sources &&
rm -rf pkg-config-0.28


--------------------------------------------------------------------------------------

tar -xf ncurses-6.0.tar.gz &&
cd ncurses-6.0 &&
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in &&
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec &&
make

make install &&
mv -v /usr/lib/libncursesw.so.6* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

rm -vf                     /usr/lib/libcursesw.so &&
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so &&
ln -sfv libncurses.so      /usr/lib/libcurses.so &&
mkdir -v       /usr/share/doc/ncurses-6.0 &&
cp -v -R doc/* /usr/share/doc/ncurses-6.0


make distclean

./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding \
            --with-abi-version=5 &&
make sources libs &&
cp -av lib/lib*.so.5* /usr/lib

cd /sources &&
rm -rf ncurses-6.0

--------------------------------------------------------------------------------------

tar -xf attr-2.4.47.src.tar.gz &&
cd attr-2.4.47 &&
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in &&
sed -i -e "/SUBDIRS/s|man2||" man/Makefile &&
./configure --prefix=/usr \
            --bindir=/bin \
            --disable-static &&
make

make install install-dev install-lib &&
chmod -v 755 /usr/lib/libattr.so

mv -v /usr/lib/libattr.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

cd /sources &&
rm -rf attr-2.4.47

--------------------------------------------------------------------------------------

tar -xf acl-2.2.52.src.tar.gz &&
cd acl-2.2.52 &&
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in &&
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test &&
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
    libacl/__acl_to_any_text.c &&
./configure --prefix=/usr    \
            --bindir=/bin    \
            --disable-static \
            --libexecdir=/usr/lib &&
make

make install install-dev install-lib &&
chmod -v 755 /usr/lib/libacl.so &&
mv -v /usr/lib/libacl.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so &&
cd /sources &&
rm -rf acl-2.2.52

--------------------------------------------------------------------------------------

tar -xf libcap-2.24.tar.xz &&
cd libcap-2.24 &&
sed -i '/install.*STALIBNAME/d' libcap/Makefile &&
make

make RAISE_SETFCAP=no prefix=/usr install &&
chmod -v 755 /usr/lib/libcap.so &&
mv -v /usr/lib/libcap.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so &&
cd /sources &&
rm -rf libcap-2.24

--------------------------------------------------------------------------------------

tar -xf sed-4.2.2.tar.bz2 &&
cd sed-4.2.2 &&
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2 &&
make

make html

make install &&
make -C doc install-html &&
cd /sources &&
rm -rf sed-4.2.2

--------------------------------------------------------------------------------------

tar -xf shadow-4.2.1.tar.xz &&
cd shadow-4.2.1

sed -i 's/groups$(EXEEXT) //' src/Makefile.in

find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

sed -i 's@DICTPATH.*@DICTPATH\t/lib/cracklib/pw_dict@' etc/login.defs

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32 &&
make

make install &&
mv -v /usr/bin/passwd /bin &&
cd /sources &&
rm -rf shadow-4.2.1

pwconv

grpconv

sed -i 's/yes/no/' /etc/default/useradd

passwd root
#define9X

--------------------------------------------------------------------------------------

tar -xf psmisc-22.21.tar.gz &&
cd psmisc-22.21 &&
./configure --prefix=/usr &&
make

make install &&
mv -v /usr/bin/fuser   /bin &&
mv -v /usr/bin/killall /bin &&
cd /sources &&
rm -rf psmisc-22.21

--------------------------------------------------------------------------------------

tar -xf procps-ng-3.3.11.tar.xz &&
cd procps-ng-3.3.11 &&
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.11 \
            --disable-static                         \
            --disable-kill &&
make

make install &&
mv -v /usr/lib/libprocps.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so &&
cd /sources &&
rm -rf procps-ng-3.3.11

--------------------------------------------------------------------------------------

tar -xf e2fsprogs-1.42.13.tar.gz &&
cd e2fsprogs-1.42.13 &&
mkdir -v build &&
cd build &&
LIBS=-L/tools/lib                    \
CFLAGS=-I/tools/include              \
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck &&
make

make install &&
make install-libs &&
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a &&
gunzip -v /usr/share/info/libext2fs.info.gz &&
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info &&
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo &&
install -v -m644 doc/com_err.info /usr/share/info &&
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info &&
cd /sources &&
rm -rf e2fsprogs-1.42.13

--------------------------------------------------------------------------------------

tar -xf coreutils-8.24.tar.xz &&
cd coreutils-8.24 &&
patch -Np1 -i ../coreutils-8.24-i18n-1.patch &&
sed -i '/tests\/misc\/sort.pl/ d' Makefile.in &&
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime &&
make

make install &&
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin &&
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin &&
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin &&
mv -v /usr/bin/chroot /usr/sbin &&
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8 &&
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8 &&
mv -v /usr/bin/{head,sleep,nice,test,[} /bin &&
cd /sources &&
rm -rf coreutils-8.24

--------------------------------------------------------------------------------------

tar -xf iana-etc-2.30.tar.bz2 &&
cd iana-etc-2.30 &&
make

make install &&
cd /sources &&
rm -rf iana-etc-2.30

--------------------------------------------------------------------------------------

tar -xf m4-1.4.17.tar.xz &&
cd m4-1.4.17 &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf m4-1.4.17

--------------------------------------------------------------------------------------

tar -xf flex-2.5.39.tar.xz &&
cd flex-2.5.39 &&
sed -i -e '/test-bison/d' tests/Makefile.in &&
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.5.39 &&
make

make install &&
ln -sv flex /usr/bin/lex &&
cd /sources &&
rm -rf flex-2.5.39

--------------------------------------------------------------------------------------

tar -xf bison-3.0.4.tar.xz &&
cd bison-3.0.4 &&
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4 &&
make

make install &&
cd /sources &&
rm -rf bison-3.0.4

--------------------------------------------------------------------------------------

tar -xf grep-2.21.tar.xz &&
cd grep-2.21 &&
sed -i -e '/tp++/a  if (ep <= tp) break;' src/kwset.c &&
./configure --prefix=/usr --bindir=/bin &&
make

make install &&
cd /sources &&
rm -rf grep-2.21

--------------------------------------------------------------------------------------

tar -xf readline-6.3.tar.gz &&
cd readline-6.3 &&
patch -Np1 -i ../readline-6.3-upstream_fixes-3.patch &&
sed -i '/MV.*old/d' Makefile.in &&
sed -i '/{OLDSUFF}/c:' support/shlib-install &&
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-6.3 &&
make SHLIB_LIBS=-lncurses

make SHLIB_LIBS=-lncurses install  &&
mv -v /usr/lib/lib{readline,history}.so.* /lib  &&
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so  &&
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so &&
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.3 &&
cd /sources &&
rm -rf readline-6.3

--------------------------------------------------------------------------------------

tar -xf bash-4.3.30.tar.gz &&
cd bash-4.3.30 &&
patch -Np1 -i ../bash-4.3.30-upstream_fixes-2.patch &&
./configure --prefix=/usr                       \
            --bindir=/bin                       \
            --docdir=/usr/share/doc/bash-4.3.30 \
            --without-bash-malloc               \
            --with-installed-readline &&
make

make install &&
cd /sources &&
rm -rf bash-4.3.30

exec /bin/bash --login +h

alias ls='ls --color=auto' &&
alias grep='grep --color=auto'

--------------------------------------------------------------------------------------

tar -xf bc-1.06.95.tar.bz2 &&
cd bc-1.06.95 &&
patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch &&
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info &&
make

make install &&
cd /sources &&
rm -rf bc-1.06.95

--------------------------------------------------------------------------------------

tar -xf libtool-2.4.6.tar.xz &&
cd libtool-2.4.6 &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf libtool-2.4.6

--------------------------------------------------------------------------------------

tar -xf gdbm-1.11.tar.gz &&
cd gdbm-1.11 &&
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat &&
make

make install &&
cd /sources &&
rm -rf gdbm-1.11

--------------------------------------------------------------------------------------

tar -xf expat-2.1.0.tar.gz &&
cd expat-2.1.0 &&
./configure --prefix=/usr --disable-static &&
make

make install &&
install -v -dm755 /usr/share/doc/expat-2.1.0 &&
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0 &&
cd /sources &&
rm -rf expat-2.1.0

--------------------------------------------------------------------------------------

tar -xf inetutils-1.9.4.tar.xz &&
cd inetutils-1.9.4 &&
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers &&
make

make install &&
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin &&
mv -v /usr/bin/ifconfig /sbin &&
cd /sources &&
rm -rf inetutils-1.9.4

--------------------------------------------------------------------------------------

tar -xf perl-5.22.0.tar.bz2 &&
cd perl-5.22.0 &&
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts &&
export BUILD_ZLIB=False &&
export BUILD_BZIP2=0 &&
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib &&
make

make install &&
unset BUILD_ZLIB BUILD_BZIP2 &&
cd /sources &&
rm -rf perl-5.22.0

--------------------------------------------------------------------------------------

tar -xf XML-Parser-2.44.tar.gz &&
cd XML-Parser-2.44 &&
perl Makefile.PL &&
make

make install &&
cd /sources &&
rm -rf XML-Parser-2.44

--------------------------------------------------------------------------------------

tar -xf autoconf-2.69.tar.xz &&
cd autoconf-2.69 &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf autoconf-2.69

--------------------------------------------------------------------------------------

tar -xf automake-1.15.tar.xz &&
cd automake-1.15 &&
sed -i 's:/\\\${:/\\\$\\{:' bin/automake.in &&
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15 &&
make

make install &&
cd /sources &&
rm -rf automake-1.15

--------------------------------------------------------------------------------------

tar -xf diffutils-3.3.tar.xz &&
cd diffutils-3.3 &&
sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf diffutils-3.3

--------------------------------------------------------------------------------------

tar -xf gawk-4.1.3.tar.xz &&
cd gawk-4.1.3 &&
./configure --prefix=/usr &&
make

make install &&
mkdir -v /usr/share/doc/gawk-4.1.3 &&
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.1.3 &&
cd /sources &&
rm -rf gawk-4.1.3

--------------------------------------------------------------------------------------

tar -xf findutils-4.4.2.tar.gz &&
cd findutils-4.4.2 &&
./configure --prefix=/usr --localstatedir=/var/lib/locate &&
make

make install &&
mv -v /usr/bin/find /bin &&
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb &&
cd /sources &&
rm -rf findutils-4.4.2

--------------------------------------------------------------------------------------

tar -xf gettext-0.19.5.1.tar.xz &&
cd gettext-0.19.5.1 &&
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.5.1 &&
make

make install &&
cd /sources &&
rm -rf gettext-0.19.5.1

--------------------------------------------------------------------------------------

tar -xf intltool-0.51.0.tar.gz &&
cd intltool-0.51.0 &&
sed -i 's:\\\${:\\\$\\{:' intltool-update.in &&
./configure --prefix=/usr &&
make

make install &&
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO &&
cd /sources &&
rm -rf intltool-0.51.0

--------------------------------------------------------------------------------------

tar -xf gperf-3.0.4.tar.gz &&
cd gperf-3.0.4 &&
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4 &&
make

make install &&
cd /sources &&
rm -rf gperf-3.0.4

--------------------------------------------------------------------------------------

cat /etc/papersize

tar -xf groff-1.22.3.tar.gz	&&
cd groff-1.22.3 &&
PAGE=letter ./configure --prefix=/usr

make

make install

cd /sources &&
rm -rf groff-1.22.3

--------------------------------------------------------------------------------------

tar -xf xz-5.2.1.tar.xz &&
cd xz-5.2.1 &&
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.1 &&
make

make install &&
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin &&
mv -v /usr/lib/liblzma.so.* /lib &&
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so &&
cd /sources &&
rm -rf xz-5.2.1

--------------------------------------------------------------------------------------

tar -xf grub-2.02~beta2.tar.xz &&
cd grub-2.02~beta2 &&
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-grub-emu-usb \
            --disable-efiemu       \
            --disable-werror &&
make

make install &&
cd /sources &&
rm -rf grub-2.02~beta2

--------------------------------------------------------------------------------------

tar -xf less-458.tar.gz &&
cd less-458 &&
./configure --prefix=/usr --sysconfdir=/etc &&
make

make install &&
cd /sources &&
rm -rf less-458

--------------------------------------------------------------------------------------

tar -xf gzip-1.6.tar.xz &&
cd gzip-1.6 &&
./configure --prefix=/usr --bindir=/bin &&
make

make install &&
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin &&
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin &&
cd /sources &&
rm -rf gzip-1.6

--------------------------------------------------------------------------------------

tar -xf iproute2-4.2.0.tar.xz &&
cd iproute2-4.2.0 &&
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile &&
sed -i /ARPD/d Makefile &&
sed -i 's/arpd.8//' man/man8/Makefile &&
make

make DOCDIR=/usr/share/doc/iproute2-4.2.0 install &&
cd /sources &&
rm -rf iproute2-4.2.0

--------------------------------------------------------------------------------------

tar -xf kbd-2.0.3.tar.xz &&
cd kbd-2.0.3 &&
patch -Np1 -i ../kbd-2.0.3-backspace-1.patch &&
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure &&
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in &&
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock &&
make

make install

mkdir -v       /usr/share/doc/kbd-2.0.3
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.3

cd /sources &&
rm -rf kbd-2.0.3

--------------------------------------------------------------------------------------

tar -xf kmod-21.tar.xz &&
cd kmod-21 &&
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib &&
make

make install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done

ln -sv kmod /bin/lsmod &&
cd /sources &&
rm -rf kmod-21

--------------------------------------------------------------------------------------

tar -xf libpipeline-1.4.1.tar.gz
cd libpipeline-1.4.1
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf libpipeline-1.4.1

--------------------------------------------------------------------------------------

tar -xf make-4.1.tar.bz2 &&
cd make-4.1 &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf make-4.1

--------------------------------------------------------------------------------------

tar -xf patch-2.7.5.tar.xz &&
cd patch-2.7.5 &&
./configure --prefix=/usr &&
make

make install &&
cd /sources &&
rm -rf patch-2.7.5


--------------------------------------------------------------------------------------

tar -xf sysklogd-1.5.1.tar.gz &&
cd sysklogd-1.5.1 &&
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c &&
make

make BINDIR=/sbin install &&
cd $LFS/sources &&
rm -rf sysklogd-1.5.1

cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF

--------------------------------------------------------------------------------------

tar -xf sysvinit-2.88dsf.tar.bz2 &&
cd sysvinit-2.88dsf &&
patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch &&
make -C src

make -C src install &&
cd $LFS/sources &&
rm -rf sysvinit-2.88dsf

--------------------------------------------------------------------------------------

tar -xf tar-1.28.tar.xz &&
cd tar-1.28 &&
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin &&
make

make install &&
make -C doc install-html docdir=/usr/share/doc/tar-1.28 &&
cd /sources &&
rm -rf tar-1.28

--------------------------------------------------------------------------------------

tar -xf texinfo-6.0.tar.xz &&
cd texinfo-6.0 &&
./configure --prefix=/usr &&
make

make install

make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info &&
rm -v dir &&
for f in *
  do install-info $f dir 2>/dev/null
done &&
popd

cd /sources &&
rm -rf texinfo-6.0

--------------------------------------------------------------------------------------

tar -xf eudev-3.1.2.tar.gz &&
cd eudev-3.1.2 &&
sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl

cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF

./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-split-usr      \
            --enable-manpages       \
            --enable-hwdb           \
            --disable-introspection \
            --disable-gudev         \
            --disable-static        \
            --config-cache          \
            --disable-gtk-doc-html &&
LIBRARY_PATH=/tools/lib make

mkdir -pv /lib/udev/rules.d &&
mkdir -pv /etc/udev/rules.d &&
make LD_LIBRARY_PATH=/tools/lib install

tar -xvf ../udev-lfs-20140408.tar.bz2 &&
make -f udev-lfs-20140408/Makefile.lfs install

LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update

cd $LFS/sources &&
rm -rf eudev-3.1.2

--------------------------------------------------------------------------------------

tar -xf util-linux-2.27.tar.xz &&
cd util-linux-2.27 &&
mkdir -pv /var/lib/hwclock &&
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.27 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir &&
make

make install &&
cd /sources &&
rm -rf util-linux-2.27

--------------------------------------------------------------------------------------

tar -xf man-db-2.7.2.tar.xz &&
cd man-db-2.7.2 &&
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.7.2 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap &&
make

make install &&
cd $LFS/sources &&
rm -rf man-db-2.7.2

--------------------------------------------------------------------------------------

tar -xf vim-7.4.tar.bz2 &&
cd vim74 &&
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h &&
./configure --prefix=/usr &&
make

make install &&
ln -sv vim /usr/bin/vi

for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim74/doc /usr/share/doc/vim-7.4 &&
cd /sources &&
rm -rf vim74

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

##################################
vim -c ':options'
vi /etc/vimrc
set spelllang=en,ru
set spell
##################################

--------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------

logout

chroot $LFS /tools/bin/env -i            \
    HOME=/root TERM=$TERM PS1='\[\e[1;31m\]\u:\[\e[0m\]\w\[\e[1;31m\]\$ \[\e[0m\]' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin   \
    /tools/bin/bash --login

/tools/bin/find /{,usr/}{bin,lib,sbin} -type f \
    -exec /tools/bin/strip --strip-debug '{}' ';'

--------------------------------------------------------------------------------------

rm -rf /tmp/*

chroot "$LFS" /usr/bin/env -i              \
    HOME=/root TERM="$TERM" PS1='\[\e[1;31m\]\u:\[\e[0m\]\w\[\e[1;31m\]\$ \[\e[0m\]' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin     \
    /bin/bash --login

alias ls='ls --color=auto' &&
alias grep='grep --color=auto'

MAKEFLAGS='-j 5'

rm /usr/lib/lib{bfd,opcodes}.a &&
rm /usr/lib/libbz2.a &&
rm /usr/lib/lib{com_err,e2p,ext2fs,ss}.a &&
rm /usr/lib/libltdl.a &&
rm /usr/lib/libz.a

--------------------------------------------------------------------------------------

cd $LFS/sources

tar -xf lfs-bootscripts-20150222.tar.bz2 &&
cd lfs-bootscripts-20150222

make install

cd $LFS/sources &&
rm -rf lfs-bootscripts-20150222

--------------------------------------------------------------------------------------

bash /lib/udev/init-net-rules.sh

cat /etc/udev/rules.d/70-persistent-net.rules
# net device r8169
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="34:97:f6:a0:09:f7", ATTR{dev_id}=="0x0", ATTR{type}=="1", NAME="enp3s0"


#udevadm test /sys/block/hdd

sed -i -e 's/"write_cd_rules"/"write_cd_rules mode"/' \
    /etc/udev/rules.d/83-cdrom-symlinks.rules

#udevadm info -a -p /sys/class/video4linux/video0

cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"

# Persistent symlinks for webcam and tuner
#KERNEL=="video*", ATTRS{idProduct}=="1910", ATTRS{idVendor}=="0d81", \
#    SYMLINK+="webcam"
#KERNEL=="video*", ATTRS{device}=="0x036f", ATTRS{vendor}=="0x109e", \
#    SYMLINK+="tvtuner"

EOF

--------------------------------------------------------------------------------------

cd /etc/sysconfig/

cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.2.108
GATEWAY=192.168.2.1
PREFIX=24
BROADCAST=192.168.2.255
EOF

cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

#domain sicdns
nameserver 192.168.10.1
nameserver 192.168.2.1

# End /etc/resolv.conf
EOF

echo "sic" > /etc/hostname

cat > /etc/hosts << "EOF"
# Begin /etc/hosts (network card version)

#127.0.0.1 localhost
#<192.168.1.1> <HOSTNAME.example.org> [alias1] [alias2 ...]
127.0.0.1 <HOSTNAME.example.org> <HOSTNAME> localhost

# End /etc/hosts (network card version)
EOF

--------------------------------------------------------------------------------------

cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF


cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF


cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

#UNICODE="1"
#KEYMAP="de-latin1"
#KEYMAP_CORRECTIONS="euro2"
#LEGACY_CHARSET="iso-8859-15"
#FONT="LatArCyrHeb-16 -m 8859-15"

KEYMAP="de-latin1"
KEYMAP_CORRECTIONS="euro2"
FONT="lat0-16 -m 8859-15"

# End /etc/sysconfig/console
EOF

cat > /etc/sysconfig/rc.site << "EOF"
# rc.site
# Optional parameters for boot scripts.

# Distro Information
# These values, if specified here, override the defaults
#DISTRO="Linux From Scratch" # The distro name
#DISTRO_CONTACT="lfs-dev@linuxfromscratch.org" # Bug report address
#DISTRO_MINI="LFS" # Short name used in filenames for distro config

# Define custom colors used in messages printed to the screen

# Please consult `man console_codes` for more information
# under the "ECMA-48 Set Graphics Rendition" section
#
# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font.  This does
# not affect framebuffer consoles

# These values, if specified here, override the defaults
#BRACKET="\\033[1;34m" # Blue
#FAILURE="\\033[1;31m" # Red
#INFO="\\033[1;36m"    # Cyan
#NORMAL="\\033[0;39m"  # Grey
#SUCCESS="\\033[1;32m" # Green
#WARNING="\\033[1;33m" # Yellow

# Use a colored prefix
# These values, if specified here, override the defaults
#BMPREFIX="     "
#SUCCESS_PREFIX="${SUCCESS}  *  ${NORMAL}"
#FAILURE_PREFIX="${FAILURE}*****${NORMAL}"
#WARNING_PREFIX="${WARNING} *** ${NORMAL}"

# Manually seet the right edge of message output (characters)
# Useful when resetting console font during boot to override
# automatic screen width detection
#COLUMNS=120

# Interactive startup
#IPROMPT="yes" # Whether to display the interactive boot prompt
#itime="3"    # The amount of time (in seconds) to display the prompt

# The total length of the distro welcome string, without escape codes
#wlen=$(echo "Welcome to ${DISTRO}" | wc -c )
#welcome_message="Welcome to ${INFO}${DISTRO}${NORMAL}"

# The total length of the interactive string, without escape codes
#ilen=$(echo "Press 'I' to enter interactive startup" | wc -c )
#i_message="Press '${FAILURE}I${NORMAL}' to enter interactive startup"

# Set scripts to skip the file system check on reboot
#FASTBOOT=yes

# Skip reading from the console
#HEADLESS=yes

# Write out fsck progress if yes
#VERBOSE_FSCK=no

# Speed up boot without waiting for settle in udev
#OMIT_UDEV_SETTLE=y

# Speed up boot without waiting for settle in udev_retry
#OMIT_UDEV_RETRY_SETTLE=yes

# Skip cleaning /tmp if yes
#SKIPTMPCLEAN=no

# For setclock
#UTC=1
#CLOCKPARAMS=

# For consolelog
#LOGLEVEL=5

# For network
#HOSTNAME=mylfs

# Delay between TERM and KILL signals at shutdown
#KILLDELAY=3

# Optional sysklogd parameters
#SYSKLOGD_PARMS="-m 0"

# Console parameters
#UNICODE=1
#KEYMAP="de-latin1"
#KEYMAP_CORRECTIONS="euro2"
#FONT="lat0-16 -m 8859-15"
#LEGACY_CHARSET=
EOF


LC_ALL=POSIX locale charmap
ANSI_X3.4-1968
LC_ALL=POSIX locale language
LC_ALL=POSIX locale charmap
LC_ALL=POSIX locale int_curr_symbol
LC_ALL=POSIX locale int_prefix

cat > /etc/profile << "EOF"
# Begin /etc/profile

#export LANG=<ll>_<CC>.<charmap><@modifiers>
export LANG=POSIX

# End /etc/profile
EOF

--------------------------------------------------------------------------------------

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

--------------------------------------------------------------------------------------

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

--------------------------------------------------------------------------------------

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda2      /            ext4     defaults            1     1
/dev/sda1      swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF

hdparm -I /dev/sda | grep NCQ

--------------------------------------------------------------------------------------

cd $LFS/sources

tar -xf linux-4.2.tar.xz &&
cd linux-4.2

make mrproper

make defconfig

make LANG=POSIX LC_ALL= menuconfig

cat > /home/config << EOF
Device Drivers  --->
  Generic Driver Options  --->
    [ ] Support for uevent helper [CONFIG_UEVENT_HELPER]
    [*] Maintain a devtmpfs filesystem to mount at /dev [CONFIG_DEVTMPFS]

Device Drivers  --->
  [*] Network device support  --->
    [*]   Ethernet driver support  ---> 
      <M>     Realtek 8169 gigabit ethernet support 
EOF

make

23:18--23:28

make modules_install

cp -v arch/x86_64/boot/bzImage /boot/vmlinuz-4.2-lfs-7.8 &&
cp -v System.map /boot/System.map-4.2 &&
cp -v .config /boot/config-4.2 &&
install -d /usr/share/doc/linux-4.2 &&
cp -r Documentation/* /usr/share/doc/linux-4.2

install -v -m755 -d /etc/modprobe.d

cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

--------------------------------------------------------------------------------------

grub-install /dev/sda

cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 4.2-lfs-7.8" {
        linux   /boot/vmlinuz-4.2-lfs-7.8 root=/dev/sda2 ro
}
EOF

--------------------------------------------------------------------------------------

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="7.8"
DISTRIB_CODENAME="Adeliea"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

--------------------------------------------------------------------------------------

logout

umount -v $LFS/dev/pts &&
umount -v $LFS/dev &&
umount -v $LFS/run &&
umount -v $LFS/proc &&
umount -v $LFS/sys

umount -v $LFS

-----------------------------------------------------------------------------------end

Setup is 15836 bytes (padded to 15872 bytes).
System is 5898 kB
CRC a0ffc4ef
Kernel: arch/x86/boot/bzImage is ready  (#1)
  Building modules, stage 2.
  MODPOST 20 modules
  CC      crypto/echainiv.mod.o
  LD [M]  crypto/echainiv.ko
  CC      drivers/net/ethernet/realtek/r8169.mod.o
  LD [M]  drivers/net/ethernet/realtek/r8169.ko
  CC      drivers/thermal/x86_pkg_temp_thermal.mod.o
  LD [M]  drivers/thermal/x86_pkg_temp_thermal.ko
  CC      fs/efivarfs/efivarfs.mod.o
  LD [M]  fs/efivarfs/efivarfs.ko
  CC      net/ipv4/netfilter/ipt_MASQUERADE.mod.o
  LD [M]  net/ipv4/netfilter/ipt_MASQUERADE.ko
  CC      net/ipv4/netfilter/iptable_nat.mod.o
  LD [M]  net/ipv4/netfilter/iptable_nat.ko
  CC      net/ipv4/netfilter/nf_log_arp.mod.o
  LD [M]  net/ipv4/netfilter/nf_log_arp.ko
  CC      net/ipv4/netfilter/nf_log_ipv4.mod.o
  LD [M]  net/ipv4/netfilter/nf_log_ipv4.ko
  CC      net/ipv4/netfilter/nf_nat_ipv4.mod.o
  LD [M]  net/ipv4/netfilter/nf_nat_ipv4.ko
  CC      net/ipv4/netfilter/nf_nat_masquerade_ipv4.mod.o
  LD [M]  net/ipv4/netfilter/nf_nat_masquerade_ipv4.ko
  CC      net/ipv6/netfilter/nf_log_ipv6.mod.o
  LD [M]  net/ipv6/netfilter/nf_log_ipv6.ko
  CC      net/netfilter/nf_log_common.mod.o
  LD [M]  net/netfilter/nf_log_common.ko
  CC      net/netfilter/nf_nat.mod.o
  LD [M]  net/netfilter/nf_nat.ko
  CC      net/netfilter/nf_nat_ftp.mod.o
  LD [M]  net/netfilter/nf_nat_ftp.ko
  CC      net/netfilter/nf_nat_irc.mod.o
  LD [M]  net/netfilter/nf_nat_irc.ko
  CC      net/netfilter/nf_nat_sip.mod.o
  LD [M]  net/netfilter/nf_nat_sip.ko
  CC      net/netfilter/xt_LOG.mod.o
  LD [M]  net/netfilter/xt_LOG.ko
  CC      net/netfilter/xt_addrtype.mod.o
  LD [M]  net/netfilter/xt_addrtype.ko
  CC      net/netfilter/xt_mark.mod.o
  LD [M]  net/netfilter/xt_mark.ko
  CC      net/netfilter/xt_nat.mod.o
  LD [M]  net/netfilter/xt_nat.ko


export LFS=/mnt/lfs
mkdir -v $LFS
mount /dev/sda2 $LFS
swapon /dev/sda1

mount -v --bind /dev $LFS/dev &&
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620 &&
mount -vt proc proc $LFS/proc &&
mount -vt sysfs sysfs $LFS/sys &&
mount -vt tmpfs tmpfs $LFS/run &&
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

chroot "$LFS" /usr/bin/env -i              \
    HOME=/root TERM="$TERM"                \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin     \
    /bin/bash --login

MAKEFLAGS='-j 5'

--------------------------------------------------------------------------------------

cd /xc

tar -xf linux-4.2.tar.xz &&
cd linux-4.2

make mrproper

#make defconfig
cp -v /boot/config-4.2 .config

make LANG=POSIX LC_ALL= menuconfig

make

make modules_install

mkdir -v /boot/back
mv -v /boot/vmlinuz-4.2-lfs-7.8 /boot/back/
mv -v /boot/System.map-4.2 /boot/back/
mv -v /boot/config-4.2 /boot/back/
mv -v /usr/share/doc/linux-4.2 /usr/share/doc/linux-4.2.bak

cp -v arch/x86_64/boot/bzImage /boot/vmlinuz-4.2-lfs-7.8 &&
cp -v System.map /boot/System.map-4.2 &&
cp -v .config /boot/config-4.2 &&
install -d /usr/share/doc/linux-4.2 &&
cp -r Documentation/* /usr/share/doc/linux-4.2

#Device Drivers  --->
#  Generic Driver Options  --->
#    [ ] Support for uevent helper [CONFIG_UEVENT_HELPER]
#    [*] Maintain a devtmpfs filesystem to mount at /dev [CONFIG_DEVTMPFS]

#Device Drivers  --->
#  [*] Network device support  --->
#    [*]   Ethernet driver support  ---> 
#      <M>     Realtek 8169 gigabit ethernet support 

#Device Drivers  --->
#  Generic Driver Options  --->
#    [ ] Support for uevent helper [CONFIG_UEVENT_HELPER]
#    [*] Maintain a devtmpfs filesystem to mount at /dev [CONFIG_DEVTMPFS]

#Device Drivers  --->
#  [*] Network device support  --->
#    [*]   Ethernet driver support  ---> 
#      <*>     Realtek 8169 gigabit ethernet support

#Device Drivers  --->
#  Input device support --->
#    <*> Generic input layer (needed for...) [CONFIG_INPUT]
#    <*>   Event interface                   [CONFIG_INPUT_EVDEV]
#    [*]   Miscellaneous devices  --->       [CONFIG_INPUT_MISC]
#      <*>    User level driver support      [CONFIG_INPUT_UINPUT]

#Processor type and features --->
#  [*] Symmetric multi-processing support          [CONFIG_SMP]
#  [*] Support for extended (non-PC) x86 platforms [CONFIG_X86_EXTENDED_PLATFORM]
#  [*] ScaleMP vSMP                                [CONFIG_X86_VSMP]

#Device Drivers --->
#  Input device support --->
#    [*] Mice --->                                 [CONFIG_INPUT_MOUSE]
#      <*/M> PS/2 mouse                            [CONFIG_MOUSE_PS2]
#      [*] Virtual mouse (vmmouse)                 [CONFIG_MOUSE_PS2_VMMOUSE]

#Device Drivers  --->
#  HID support  --->
#    <*/M> HID bus support                                      [CONFIG_HID]
#            Special HID drivers --->
#              <*/M> Wacom Intuos/Graphire tablet support (USB) [CONFIG_HID_WACOM]

#Device Drivers  --->
#  Graphics support --->
#    Direct rendering Manager --->
#      <*> Direct Rendering Manager (XFree86 ... support) ---> [CONFIG_DRM]
#      <*> ATI Radeon                                          [CONFIG_DRM_RADEON]

#Device Drivers  --->
#  Graphics support --->
#    Direct rendering Manager --->
#      <*> Direct Rendering Manager (XFree86 ... support) ---> [CONFIG_DRM]
#      <*> Intel I810                                          [CONFIG_DRM_I810]
#      <*> Intel 8xx/9xx/G3x/G4x/HD Graphics                   [CONFIG_DRM_I915]
#      [*]   Enable modesetting on intel by default            [CONFIG_DRM_I915_KMS]

#Device Drivers  --->
#  Graphics support --->
#    Direct rendering Manager --->
#      <*> Direct Rendering Manager (XFree86 ... support) ---> [CONFIG_DRM]
#      <*> Nouveau (NVIDIA) cards                              [CONFIG_DRM_NOUVEAU]
#      [*]   Support for backlight control                     [CONFIG_DRM_NOUVEAU_BACKLIGHT]

#Device Drivers  --->
#  Graphics support  --->
#    Direct Rendering Manager  --->
#      <*> Direct Rendering Manager (XFree86 ... support) --->  [CONFIG_DRM]
#      <*> DRM driver for VMware Virtual GPU                    [CONFIG_DRM_VMWGFX]
#      [*]   Enable framebuffer console under vmwgfx by default [CONFIG_DRM_VMWGFX_FBCON]

#Device Drivers --->
#  [*] USB support --->                   [CONFIG_USB_SUPPORT]
#    <*/M> Support for Host-side USB      [CONFIG_USB]
#    (Select any USB hardware device drivers you may need on the same page)

#Device Drivers --->
#  <*/m> Sound card support --->                  [CONFIG_SOUND]
#    <*/m> Advanced Linux Sound Architecture ---> [CONFIG_SND]
#            Select settings and drivers appropriate for your hardware.
#    < >   Open Sound System (DEPRECATED)         [CONFIG_SOUND_PRIME]

#.config
#CONFIG_USB_HID=m
#CONFIG_INPUT=Y
#CONFIG_HID=Y
#CONFIG_EXPERT=y
#CONFIG_USB_KBD=m
#CONFIG_USB_MOUSE=m
#CONFIG_I2C_HID=m
#CONFIG_HID_GENERIC=m

--------------------------------------------------------------------------------------

mkdir -v /xc/firefox
cd /xc/firefox

#Device Drivers --->
#  <*/m> Sound card support --->                  [CONFIG_SOUND]
#    <*/m> Advanced Linux Sound Architecture ---> [CONFIG_SND]
#            Select settings and drivers appropriate for your hardware.
#    < >   Open Sound System (DEPRECATED)         [CONFIG_SOUND_PRIME]

wget http://alsa.cybermirror.org/lib/alsa-lib-1.0.29.tar.bz2
wget ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.0.29.tar.bz2
md5sum alsa-lib-1.0.29.tar.bz2 
de67e0eca72474d6b1121037dafe1024  alsa-lib-1.0.29.tar.bz2
de67e0eca72474d6b1121037dafe1024

tar -xf alsa-lib-1.0.29.tar.bz2 &&
cd alsa-lib-1.0.29 &&
./configure &&
make

#make doc

make install

install -v -d -m755 /usr/share/doc/alsa-lib-1.0.29/html/search &&
install -v -m644 doc/doxygen/html/*.* \
                /usr/share/doc/alsa-lib-1.0.29/html &&
#install -v -m644 doc/doxygen/html/search/* \
#                /usr/share/doc/alsa-lib-1.0.29/html/search
##install: cannot stat 'doc/doxygen/html/*.*': No such file or directory

cd /xc/firefox &&
rm -rf alsa-lib-1.0.29

------------------------------------------------------------------------------------1

#wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.bz2
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/p/pcre-8.37.tar.bz2
wget http://www.linuxfromscratch.org/patches/blfs/7.8/pcre-8.37-upstream_fixes-1.patch
md5sum pcre-8.37.tar.bz2 
ed91be292cb01d21bc7e526816c26981  pcre-8.37.tar.bz2
ed91be292cb01d21bc7e526816c26981

tar -xf pcre-8.37.tar.bz2 &&
cd pcre-8.37 &&
patch -Np1 -i ../pcre-8.37-upstream_fixes-1.patch &&
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.37 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                 &&
make

make install                     &&
mv -v /usr/lib/libpcre.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so

cd /xc/firefox &&
rm -rf pcre-8.37

------------------------------------------------------------------------------------2

wget http://ftp.gnome.org/pub/gnome/sources/glib/2.44/glib-2.44.1.tar.xz
md5sum glib-2.44.1.tar.xz
83efba4722a9674b97437d1d99af79db  glib-2.44.1.tar.xz
83efba4722a9674b97437d1d99af79db

tar -xf glib-2.44.1.tar.xz &&
cd glib-2.44.1 &&
./configure --prefix=/usr --with-pcre=system &&
make

make install

cd /xc/firefox &&
rm -rf glib-2.44.1

-------------------------------------------------------------------------------------

wget http://ftp.gnome.org/pub/gnome/sources/atk/2.16/atk-2.16.0.tar.xz
md5sum atk-2.16.0.tar.xz 
c7c5002bd6e58b4723a165f1bf312116  atk-2.16.0.tar.xz
c7c5002bd6e58b4723a165f1bf312116 

tar -xf atk-2.16.0.tar.xz &&
cd atk-2.16.0 &&
./configure --prefix=/usr &&
make

make install

cd /xc/firefox &&
rm -rf atk-2.16.0


-------------------------------------------------------------------------------------1

wget http://www.nasm.us/pub/nasm/releasebuilds/2.11.08/nasm-2.11.08.tar.xz
wget http://www.nasm.us/pub/nasm/releasebuilds/2.11.08/nasm-2.11.08-xdoc.tar.xz
md5sum nasm-2.11.08.tar.xz 
0d461a085b088a14dd6628c53be1ce28  nasm-2.11.08.tar.xz
0d461a085b088a14dd6628c53be1ce28 

tar -xf nasm-2.11.08.tar.xz &&
cd nasm-2.11.08 &&
tar -xf ../nasm-2.11.08-xdoc.tar.xz --strip-components=1 &&
./configure --prefix=/usr &&
make

make install

install -m755 -d         /usr/share/doc/nasm-2.11.08/html  &&
cp -v doc/html/*.html    /usr/share/doc/nasm-2.11.08/html  &&
cp -v doc/*.{txt,ps,pdf} /usr/share/doc/nasm-2.11.08       &&
cp -v doc/info/*         /usr/share/info                   &&
install-info /usr/share/info/nasm.info /usr/share/info/dir

cd /xc/firefox &&
rm -rf nasm-2.11.08

-------------------------------------------------------------------------------------2

wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
md5sum yasm-1.3.0.tar.gz 
fc9e586751ff789b34b1f21d572d96af  yasm-1.3.0.tar.gz
fc9e586751ff789b34b1f21d572d96af

tar -xf yasm-1.3.0.tar.gz &&
cd yasm-1.3.0 &&
sed -i 's#) ytasm.*#)#' Makefile.in &&
./configure --prefix=/usr &&
make

make install

cd /xc/firefox &&
rm -rf yasm-1.3.0

-------------------------------------------------------------------------------------3

#wget http://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.4.1.tar.gz
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/l/libjpeg-turbo-1.4.1.tar.gz
md5sum libjpeg-turbo-1.4.1.tar.gz 
b1f6b84859a16b8ebdcda951fa07c3f2  libjpeg-turbo-1.4.1.tar.gz
b1f6b84859a16b8ebdcda951fa07c3f2

tar -xf libjpeg-turbo-1.4.1.tar.gz &&
cd libjpeg-turbo-1.4.1 &&
sed -i -e '/^docdir/ s:$:/libjpeg-turbo-1.4.1:' Makefile.in &&
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-jpeg8            \
            --disable-static &&
make

#If installing libjpeg-turbo over an older jpeg installation, not all library symbolic links are updated properly. To fix this before installation, run the following as the root user: 
#rm -f /usr/lib/libjpeg.so*

make install

cd /xc/firefox &&
rm -rf libjpeg-turbo-1.4.1

-------------------------------------------------------------------------------------4

wget http://download.osgeo.org/libtiff/tiff-4.0.5.tar.gz
md5sum tiff-4.0.5.tar.gz 
523a76b4a3b24a0287dcfae82580ed2c  tiff-4.0.5.tar.gz
523a76b4a3b24a0287dcfae82580ed2c

tar -xf tiff-4.0.5.tar.gz &&
cd tiff-4.0.5 &&
./configure --prefix=/usr --disable-static &&
make

make install

cd /xc/firefox &&
rm -rf tiff-4.0.5

-------------------------------------------------------------------------------------5

wget http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.31/gdk-pixbuf-2.31.7.tar.xz
md5sum gdk-pixbuf-2.31.7.tar.xz 
8a42218ed76a75e38dc737c0c5d30190  gdk-pixbuf-2.31.7.tar.xz
8a42218ed76a75e38dc737c0c5d30190

tar -xf gdk-pixbuf-2.31.7.tar.xz &&
cd gdk-pixbuf-2.31.7 &&
./configure --prefix=/usr --with-x11 &&
make

make install

cd /xc/firefox &&
rm -rf gdk-pixbuf-2.31.7

#If you installed the package on to your system using a “DESTDIR” method, an important file was not installed and should be copied and/or generated. Generate it using the following command as the root user:
#gdk-pixbuf-query-loaders --update-cache

-------------------------------------------------------------------------------------6

wget http://cairographics.org/releases/cairo-1.14.2.tar.xz
md5sum cairo-1.14.2.tar.xz 
e1cdfaf1c6c995c4d4c54e07215b0118  cairo-1.14.2.tar.xz
e1cdfaf1c6c995c4d4c54e07215b0118

tar -xf cairo-1.14.2.tar.xz &&
cd cairo-1.14.2 &&
./configure --prefix=/usr    \
            --disable-static \
            --enable-tee &&
make

make install

cd /xc/firefox &&
rm -rf cairo-1.14.2

-------------------------------------------------------------------------------------7

#wget http://download.icu-project.org/files/icu4c/55.1/icu4c-55_1-src.tgz
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/i/icu4c-55_1-src.tgz
md5sum icu4c-55_1-src.tgz 
e2d523df79d6cb7855c2fbe284f4db29  icu4c-55_1-src.tgz
e2d523df79d6cb7855c2fbe284f4db29

tar -xf icu4c-55_1-src.tgz &&
cd icu &&
cd source &&
./configure --prefix=/usr &&
make

make install

cd /xc/firefox &&
rm -rf icu

-------------------------------------------------------------------------------------8

wget http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.0.3.tar.bz2
md5sum harfbuzz-1.0.3.tar.bz2
bf459ed21c68d97fbb3313cbdee53268  harfbuzz-1.0.3.tar.bz2
bf459ed21c68d97fbb3313cbdee53268 

tar -xf harfbuzz-1.0.3.tar.bz2 &&
cd harfbuzz-1.0.3 &&
./configure --prefix=/usr --with-gobject &&
make

make install

cd /xc/firefox &&
rm -rf harfbuzz-1.0.3

--------------------------------------------------------------------------------------9

wget http://downloads.sourceforge.net/freetype/freetype-2.6.tar.bz2
5682890cb0267f6671dd3de6eabd3e69  freetype-2.6.tar.bz2
5682890cb0267f6671dd3de6eabd3e69

wget http://downloads.sourceforge.net/freetype/freetype-doc-2.6.tar.bz2
f456b7ead3c351c7c218bb3afd45803c 

tar -xf freetype-2.6.tar.bz2 &&
cd freetype-2.6 &&
tar -xf ../freetype-doc-2.6.tar.bz2 --strip-components=2 -C docs &&
sed -i  -e "/AUX.*.gxvalid/s@^# @@" \
        -e "/AUX.*.otvalid/s@^# @@" \
        modules.cfg                        &&
sed -ri -e 's:.*(#.*SUBPIXEL.*) .*:\1:' \
        include/config/ftoption.h          &&
./configure --prefix=/usr --disable-static &&
make

make install &&
install -v -m755 -d /usr/share/doc/freetype-2.6 &&
cp -v -R docs/*     /usr/share/doc/freetype-2.6

cd /xc/firefox &&
rm -rf freetype-2.6

-------------------------------------------------------------------------------------10

wget http://ftp.gnome.org/pub/gnome/sources/pango/1.36/pango-1.36.8.tar.xz
md5sum pango-1.36.8.tar.xz 
217a9a753006275215fa9fa127760ece  pango-1.36.8.tar.xz
217a9a753006275215fa9fa127760ece

tar -xf pango-1.36.8.tar.xz &&
cd pango-1.36.8 &&
./configure --prefix=/usr --sysconfdir=/etc &&
make

make install

cd /xc/firefox &&
rm -rf pango-1.36.8

# If you installed the package on to your system using a “DESTDIR” method, an important file was not installed and must be copied and/or generated. Generate it using the following command as the root user:
#pango-querymodules --update-cache

--------------------------------------------------------------------------------------11

wget http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.15.tar.xz
md5sum hicolor-icon-theme-0.15.tar.xz 
6aa2b3993a883d85017c7cc0cfc0fb73  hicolor-icon-theme-0.15.tar.xz
6aa2b3993a883d85017c7cc0cfc0fb73

tar -xf hicolor-icon-theme-0.15.tar.xz &&
cd hicolor-icon-theme-0.15 &&
./configure --prefix=/usr &&
make install

cd /xc/firefox &&
rm -rf hicolor-icon-theme-0.15

--------------------------------------------------------------------------------------12

wget http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.28.tar.xz
md5sum gtk+-2.24.28.tar.xz 
bfacf87b2ea67e4e5c7866a9003e6526  gtk+-2.24.28.tar.xz
bfacf87b2ea67e4e5c7866a9003e6526

tar -xf gtk+-2.24.28.tar.xz &&
cd gtk+-2.24.28 &&
sed -e 's#l \(gtk-.*\).sgml#& -o \1#' \
    -i docs/{faq,tutorial}/Makefile.in      &&
sed -e 's#pltcheck.sh#$(NULL)#g' \
    -i gtk/Makefile.in                      &&
./configure --prefix=/usr --sysconfdir=/etc &&
make

make install

cd /xc/firefox &&
rm -rf gtk+-2.24.28

# If you installed the package on to your system using a “DESTDIR” method, an important file was not installed and must be copied and/or generated. Generate it using the following command as the root user:
#gtk-query-immodules-2.0 --update-cache

cat > ~/.gtkrc-2.0 << "EOF"
include "/usr/share/themes/Glider/gtk-2.0/gtkrc"
gtk-icon-theme-name = "hicolor"
EOF

cat > /etc/gtk-2.0/gtkrc << "EOF"
include "/usr/share/themes/Clearlooks/gtk-2.0/gtkrc"
gtk-icon-theme-name = "elementary"
EOF


--------------------------------------------------------------------------------------

#wget http://downloads.sourceforge.net/infozip/unzip60.tar.gz
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/u/unzip60.tar.gz
md5sum unzip60.tar.gz 
62b490407489521db863b523a7f86375  unzip60.tar.gz
62b490407489521db863b523a7f86375

tar -xf unzip60.tar.gz &&
cd unzip60 &&
make -f unix/Makefile generic

make prefix=/usr MANDIR=/usr/share/man/man1 \
 -f unix/Makefile install

cd /xc/firefox &&
rm -rf unzip60

--------------------------------------------------------------------------------------

#wget http://downloads.sourceforge.net/infozip/zip30.tar.gz
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/z/zip30.tgz
md5sum zip30.tgz 
7b74551e63f8ee6aab6fbc86676c0d37  zip30.tgz
7b74551e63f8ee6aab6fbc86676c0d37

tar -xf zip30.tgz &&
cd zip30 &&
make -f unix/Makefile generic_gcc

make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install

cd /xc/firefox &&
rm -rf zip30

--------------------------------------------------------------------------------------

#wget http://downloads.sourceforge.net/levent/libevent-2.0.22-stable.tar.gz
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/l/libevent-2.0.22-stable.tar.gz
md5sum libevent-2.0.22-stable.tar.gz
c4c56f986aa985677ca1db89630a2e11  libevent-2.0.22-stable.tar.gz
c4c56f986aa985677ca1db89630a2e11

tar -xf libevent-2.0.22-stable.tar.gz &&
cd libevent-2.0.22-stable &&
./configure --prefix=/usr --disable-static &&
make

make install

install -v -m755 -d /usr/share/doc/libevent-2.0.22/api &&
#cp      -v -R       doxygen/html/* /usr/share/doc/libevent-2.0.22/api

cd /xc/firefox &&
rm -rf libevent-2.0.22-stable

--------------------------------------------------------------------------------------

#wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.4.0.tar.bz2
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/l/libvpx-1.4.0.tar.bz2
md5sum libvpx-1.4.0.tar.bz2 
63b1d7f59636a42eeeee9225cc14e7de  libvpx-1.4.0.tar.bz2
63b1d7f59636a42eeeee9225cc14e7de 

tar -xf libvpx-1.4.0.tar.bz2 &&
cd libvpx-1.4.0 &&
sed   -e 's/cp -p/cp/'       \
      -i build/make/Makefile &&
chmod -v 644 vpx/*.h         &&
mkdir ../libvpx-build &&
cd    ../libvpx-build &&
../libvpx-1.4.0/configure --prefix=/usr \
                           --enable-shared \
                           --disable-static &&
make

make install

cd /xc/firefox &&
rm -rf libvpx-1.4.0
rm -rf libvpx-build

--------------------------------------------------------------------------------------

#wget http://sqlite.org/2015/sqlite-autoconf-3081101.tar.gz
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/s/sqlite-autoconf-3081101.tar.gz
md5sum sqlite-autoconf-3081101.tar.gz 
298c8d6af7ca314f68de92bc7a356cbe  sqlite-autoconf-3081101.tar.gz
298c8d6af7ca314f68de92bc7a356cbe

#wget http://sqlite.org/2015/sqlite-doc-3081101.zip
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/s/sqlite-doc-3081101.zip
md5sum sqlite-doc-3081101.zip 
29fc9f4d2346187b11c09f867d69b427  sqlite-doc-3081101.zip
29fc9f4d2346187b11c09f867d69b427 

tar -xf sqlite-autoconf-3081101.tar.gz &&
cd sqlite-autoconf-3081101 &&
unzip -q ../sqlite-doc-3081101.zip &&
./configure --prefix=/usr --disable-static        \
            CFLAGS="-g -O2 -DSQLITE_ENABLE_FTS3=1 \
            -DSQLITE_ENABLE_COLUMN_METADATA=1     \
            -DSQLITE_ENABLE_UNLOCK_NOTIFY=1       \
            -DSQLITE_SECURE_DELETE=1              \
            -DSQLITE_ENABLE_DBSTAT_VTAB=1" &&
make

make install

install -v -m755 -d /usr/share/doc/sqlite-3.8.11.1 &&
cp -v -R sqlite-doc-3081101/* /usr/share/doc/sqlite-3.8.11.1

cd /xc/firefox &&
rm -rf sqlite-autoconf-3081101

--------------------------------------------------------------------------------------

wget https://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v4.10.9/src/nspr-4.10.9.tar.gz
md5sum nspr-4.10.9.tar.gz 
86769a7fc3b4c30f7fdcb45ab284c452  nspr-4.10.9.tar.gz
86769a7fc3b4c30f7fdcb45ab284c452

tar -xf nspr-4.10.9.tar.gz &&
cd nspr-4.10.9 &&
cd nspr                                                     &&
sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
sed -i 's#$(LIBRARY) ##' config/rules.mk                    &&
./configure --prefix=/usr \
            --with-mozilla \
            --with-pthreads \
            $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
make

make install

cd /xc/firefox &&
rm -rf nspr-4.10.9

--------------------------------------------------------------------------------------

wget https://ftp.mozilla.org/pub/mozilla.org/security/nss/releases/NSS_3_20_RTM/src/nss-3.20.tar.gz
wget http://www.linuxfromscratch.org/patches/blfs/7.8/nss-3.20-standalone-1.patch
md5sum nss-3.20.tar.gz 
db83988499d1eb3b623d77ecf495b0f5  nss-3.20.tar.gz
db83988499d1eb3b623d77ecf495b0f5

tar -xf nss-3.20.tar.gz &&
cd nss-3.20 &&
patch -Np1 -i ../nss-3.20-standalone-1.patch &&
cd nss &&
make BUILD_OPT=1                      \
  NSPR_INCLUDE_DIR=/usr/include/nspr  \
  USE_SYSTEM_ZLIB=1                   \
  ZLIB_LIBS=-lz                       \
  $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
  $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1) -j1

cd ../dist                                                       &&
install -v -m755 Linux*/lib/*.so              /usr/lib           &&
install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib           &&
install -v -m755 -d                           /usr/include/nss   &&
cp -v -RL {public,private}/nss/*              /usr/include/nss   &&
chmod -v 644                                  /usr/include/nss/* &&
install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin &&
install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib/pkgconfig

cd /xc/firefox &&
rm -rf nss-3.20

--------------------------------------------------------------------------------------GConfig 1

wget http://xmlsoft.org/sources/libxml2-2.9.2.tar.gz
md5sum libxml2-2.9.2.tar.gz 
9e6a9aca9d155737868b3dc5fd82f788  libxml2-2.9.2.tar.gz
9e6a9aca9d155737868b3dc5fd82f788 

wget http://www.w3.org/XML/Test/xmlts20130923.tar.gz

tar -xf libxml2-2.9.2.tar.gz &&
cd libxml2-2.9.2 &&
sed -e /xmlInitializeCatalog/d \
    -e 's/((ent->checked =.*&&/(((ent->checked == 0) ||\
            ((ent->children == NULL) \&\& (ctxt->options \& XML_PARSE_NOENT))) \&\&/' \
    -i parser.c &&
sed -e  "/The id is/{N;
                     a if (ctxt != NULL)
                    }" \
    -i valid.c

./configure --prefix=/usr --disable-static --with-history &&
make

#tar xf ../xmlts20130923.tar.gz

make install

cd /xc/firefox &&
rm -rf libxml2-2.9.2

--------------------------------------------------------------------------------------GConfig 2

wget http://dbus.freedesktop.org/releases/dbus/dbus-1.10.0.tar.gz

5af6297348107a906c8449817a728b3b

tar -xf dbus-1.10.0.tar.gz &&
cd dbus-1.10.0 &&
groupadd -g 18 messagebus &&
useradd -c "D-Bus Message Daemon User" -d /var/run/dbus \
        -u 18 -g messagebus -s /bin/false messagebus

./configure --prefix=/usr                  \
            --sysconfdir=/etc              \
            --localstatedir=/var           \
            --disable-doxygen-docs         \
            --disable-xml-docs             \
            --disable-static               \
            --disable-systemd              \
            --without-systemdsystemunitdir \
            --with-console-auth-dir=/run/console/ \
            --docdir=/usr/share/doc/dbus-1.10.0   &&
make

make install

chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper &&
chmod -v      4750       /usr/libexec/dbus-daemon-launch-helper

dbus-uuidgen --ensure

#make distclean                     &&
#./configure --enable-tests         \
#            --enable-asserts       \
#            --disable-doxygen-docs \
#            --disable-xml-docs     &&
#make

#make check
#sed -i -e 's:run-test.sh:$(NULL):g' test/name-test/Makefile.in

cat > /etc/dbus-1/session-local.conf << "EOF"
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

  <!-- Search for .service files in /usr/local -->
  <servicedir>/usr/local/share/dbus-1/services</servicedir>

</busconfig>
EOF

#wget http://www.linuxfromscratch.org/blfs/downloads/7.8/blfs-bootscripts-20150924.tar.bz2
#make install-dbus
----
# Start the D-Bus session daemon
##eval `dbus-launch`
##export DBUS_SESSION_BUS_ADDRESS
----
####~/.bash_logout
# Kill the D-Bus session daemon
##kill $DBUS_SESSION_BUS_PID
----

cd /xc/firefox &&
rm -rf dbus-1.10.0

--------------------------------------------------------------------------------------GConfig 3

wget http://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.104.tar.gz
md5sum dbus-glib-0.104.tar.gz 
5497d2070709cf796f1878c75a72a039  dbus-glib-0.104.tar.gz
5497d2070709cf796f1878c75a72a039 

tar -xf dbus-glib-0.104.tar.gz &&
cd dbus-glib-0.104 &&
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static &&
make

make install

cd /xc/firefox &&
rm -rf dbus-glib-0.104

--------------------------------------------------------------------------------------GConfig 4

wget http://ftp.gnome.org/pub/gnome/sources/GConf/3.2/GConf-3.2.6.tar.xz
md5sum GConf-3.2.6.tar.xz 
2b16996d0e4b112856ee5c59130e822c  GConf-3.2.6.tar.xz
2b16996d0e4b112856ee5c59130e822c

tar -xf GConf-3.2.6.tar.xz &&
cd GConf-3.2.6 &&
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --disable-orbit \
            --disable-static &&
make

make install &&
ln -s gconf.xml.defaults /etc/gconf/gconf.xml.system

cd /xc/firefox &&
rm -rf GConf-3.2.6

--------------------------------------------------------------------------------------

logout

umount -v $LFS/dev/pts &&
umount -v $LFS/dev &&
umount -v $LFS/run &&
umount -v $LFS/proc &&
umount -v $LFS/sys

umount -v $LFS

reboot

--------------------------------------------------------------------------------------

wget https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/41.0/source/firefox-41.0.source.tar.xz
#wget http://ftp.lfs-matrix.net/pub/blfs/7.8/f/firefox-41.0.source.tar.xz
md5sum firefox-41.0.source.tar.xz 
81324515c2f562db8c4800ebafaa5d25  firefox-41.0.source.tar.xz
81324515c2f562db8c4800ebafaa5d25

SHELL=/bin/sh

tar -xf firefox-41.0.source.tar.xz &&
cd mozilla-release

cat > mozconfig << "EOF"
# If you have a multicore machine, all cores will be used by default.
# If desired, you can reduce the number of cores used, e.g. to 1, by
# uncommenting the next line and setting a valid number of CPU cores.
#mk_add_options MOZ_MAKE_FLAGS="-j1"

# If you have installed DBus-Glib comment out this line:
ac_add_options --disable-dbus

# If you have installed dbus-glib, and you have installed (or will install)
# wireless-tools, and you wish to use geolocation web services, comment out
# this line
ac_add_options --disable-necko-wifi

# If you have installed libnotify comment out this line:
ac_add_options --disable-libnotify

# GStreamer is necessary for H.264 video playback in HTML5 Video Player;
# to be enabled, also remember to set "media.gstreamer.enabled" to "true"
# in about:config. If you have GStreamer 1.x.y, comment out this line and
# uncomment the following one:
ac_add_options --disable-gstreamer
#ac_add_options --enable-gstreamer=1.0

# Uncomment these lines if you have installed optional dependencies:
#ac_add_options --enable-system-hunspell
#ac_add_options --enable-startup-notification

# Comment out following option if you have PulseAudio installed
ac_add_options --disable-pulseaudio

# Comment out following options if you have not installed
# recommended dependencies:
ac_add_options --enable-system-sqlite
ac_add_options --with-system-libevent
ac_add_options --with-system-libvpx
ac_add_options --with-system-nspr
ac_add_options --with-system-nss
ac_add_options --with-system-icu

# The BLFS editors recommend not changing anything below this line:
ac_add_options --prefix=/usr
ac_add_options --enable-application=browser

ac_add_options --disable-crashreporter
ac_add_options --disable-updater
ac_add_options --disable-tests

ac_add_options --enable-optimize
ac_add_options --enable-strip
ac_add_options --enable-install-strip

ac_add_options --enable-gio
ac_add_options --enable-official-branding
ac_add_options --enable-safe-browsing
ac_add_options --enable-url-classifier

# From firefox-40, using system cairo causes firefox to crash
# frequently when it is doing background rendering in a tab.
#ac_add_options --enable-system-cairo
ac_add_options --enable-system-ffi
ac_add_options --enable-system-pixman

ac_add_options --with-pthreads

ac_add_options --with-system-bz2
ac_add_options --with-system-jpeg
ac_add_options --with-system-png
ac_add_options --with-system-zlib

mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/firefox-build-dir
EOF

make -f client.mk

make -f client.mk install INSTALL_SDK= &&
chown -R 0:0 /usr/lib/firefox-41.0     &&
mkdir -pv    /usr/lib/mozilla/plugins  &&
ln    -sfv   ../../mozilla/plugins \
             /usr/lib/firefox-41.0/browser
# '/usr/lib/firefox-41.0/browser' -> '../../mozilla/plugins'

mkdir -pv /usr/share/applications &&
mkdir -pv /usr/share/pixmaps &&
cat > /usr/share/applications/firefox.desktop << "EOF" &&
[Desktop Entry]
Encoding=UTF-8
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Exec=firefox %u
Terminal=false
Type=Application
Icon=firefox
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=application/xhtml+xml;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF
ln -sfv /usr/lib/firefox-41.0/browser/icons/mozicon128.png \
        /usr/share/pixmaps/firefox.png

cd /xc/firefox &&
rm -rf mozilla-release

-----------------------------------------------------------------------------------end


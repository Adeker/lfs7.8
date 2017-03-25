wget www.linuxfromscratch.org/blfs/downloads/7.8/blfs-book-7.8-html.tar.bz2
mkdir -v blfs7.8
cd blfs7.8
tar -xf .,/blfs-book-7.8-html.tar.bz2

mkdir $LFS/xc &&
chmod -v a+wt $LFS/xc &&
cd $LFS/xc

wget http://ftp.gnu.org/gnu/wget/wget-1.16.3.tar.xz
wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/gnutls-3.4.4.1.tar.xz
wget http://p11-glue.freedesktop.org/releases/p11-kit-0.23.1.tar.gz

wget http://anduin.linuxfromscratch.org/sources/other/certdata.txt

wget https://openssl.org/source/openssl-1.0.2d.tar.gz
md5sum openssl-1.0.2d.tar.gz 
38dd619b2e77cbac69b99f52a053d25a  openssl-1.0.2d.tar.gz

wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
md5sum libffi-3.2.1.tar.gz
83b89587607e3eb65c70d361f13bab43  libffi-3.2.1.tar.gz

wget http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.6.tar.gz
wget https://ftp.gnu.org/gnu/nettle/nettle-3.1.1.tar.gz

--------------------------------------------------------------------------------------

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


MAKEFLAGS='-j 5' &&
export XORG_PREFIX="/usr" &&
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc \
    --localstatedir=/var --disable-static" &&
cd /xc

--------------------------------------------------------------------------------------y

tar -xf nettle-3.1.1.tar.gz &&
cd nettle-3.1.1 &&
./configure --prefix=/usr &&
make

sed -i '/^install-here/ s/ install-static//' Makefile

make install

chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
install -v -m755 -d /usr/share/doc/nettle-3.1.1  &&
install -v -m644 nettle.html /usr/share/doc/nettle-3.1.1

cd /xc &&
rm -rf nettle-3.1.1

--------------------------------------------------------------------------------------y

tar -xf libtasn1-4.6.tar.gz &&
cd libtasn1-4.6 &&
./configure --prefix=/usr --disable-static &&
make

make install

make -C doc/reference install-data-local

cd /xc &&
rm -rf libtasn1-4.6

--------------------------------------------------------------------------------------y

tar -xf libffi-3.2.1.tar.gz &&
cd libffi-3.2.1 &&
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in &&

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in        &&

./configure --prefix=/usr --disable-static &&
make

make install

cd /xc &&
rm -rf libffi-3.2.1

--------------------------------------------------------------------------------------y

tar -xf openssl-1.0.2d.tar.gz &&
cd openssl-1.0.2d &&
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic &&
make

sed -i 's# libcrypto.a##;s# libssl.a##' Makefile

make MANDIR=/usr/share/man MANSUFFIX=ssl install &&
install -dv -m755 /usr/share/doc/openssl-1.0.2d  &&
cp -vfr doc/*     /usr/share/doc/openssl-1.0.2d

cd /xc &&
rm -rf openssl-1.0.2d

--------------------------------------------------------------------------------------y

cat > /usr/bin/make-cert.pl << "EOF"
#!/usr/bin/perl -w

# Used to generate PEM encoded files from Mozilla certdata.txt.
# Run as ./make-cert.pl > certificate.crt
#
# Parts of this script courtesy of RedHat (mkcabundle.pl)
#
# This script modified for use with single file data (tempfile.cer) extracted
# from certdata.txt, taken from the latest version in the Mozilla NSS source.
# mozilla/security/nss/lib/ckfw/builtins/certdata.txt
#
# Authors: DJ Lucas
#          Bruce Dubbs
#
# Version 20120211

my $certdata = './tempfile.cer';

open( IN, "cat $certdata|" )
    || die "could not open $certdata";

my $incert = 0;

while ( <IN> )
{
    if ( /^CKA_VALUE MULTILINE_OCTAL/ )
    {
        $incert = 1;
        open( OUT, "|openssl x509 -text -inform DER -fingerprint" )
            || die "could not pipe to openssl x509";
    }

    elsif ( /^END/ && $incert )
    {
        close( OUT );
        $incert = 0;
        print "\n\n";
    }

    elsif ($incert)
    {
        my @bs = split( /\\/ );
        foreach my $b (@bs)
        {
            chomp $b;
            printf( OUT "%c", oct($b) ) unless $b eq '';
        }
    }
}
EOF

chmod +x /usr/bin/make-cert.pl


cat > /usr/bin/make-ca.sh << "EOF"
#!/bin/sh
# Begin make-ca.sh
# Script to populate OpenSSL's CApath from a bundle of PEM formatted CAs
#
# The file certdata.txt must exist in the local directory
# Version number is obtained from the version of the data.
#
# Authors: DJ Lucas
#          Bruce Dubbs
#
# Version 20120211

certdata="certdata.txt"

if [ ! -r $certdata ]; then
  echo "$certdata must be in the local directory"
  exit 1
fi

REVISION=$(grep CVS_ID $certdata | cut -f4 -d'$')

if [ -z "${REVISION}" ]; then
  echo "$certfile has no 'Revision' in CVS_ID"
  exit 1
fi

VERSION=$(echo $REVISION | cut -f2 -d" ")

TEMPDIR=$(mktemp -d)
TRUSTATTRIBUTES="CKA_TRUST_SERVER_AUTH"
BUNDLE="BLFS-ca-bundle-${VERSION}.crt"
CONVERTSCRIPT="/usr/bin/make-cert.pl"
SSLDIR="/etc/ssl"

mkdir "${TEMPDIR}/certs"

# Get a list of starting lines for each cert
CERTBEGINLIST=$(grep -n "^# Certificate" "${certdata}" | cut -d ":" -f1)

# Get a list of ending lines for each cert
CERTENDLIST=`grep -n "^CKA_TRUST_STEP_UP_APPROVED" "${certdata}" | cut -d ":" -f 1`

# Start a loop
for certbegin in ${CERTBEGINLIST}; do
  for certend in ${CERTENDLIST}; do
    if test "${certend}" -gt "${certbegin}"; then
      break
    fi
  done

  # Dump to a temp file with the name of the file as the beginning line number
  sed -n "${certbegin},${certend}p" "${certdata}" > "${TEMPDIR}/certs/${certbegin}.tmp"
done

unset CERTBEGINLIST CERTDATA CERTENDLIST certbegin certend

mkdir -p certs
rm -f certs/*      # Make sure the directory is clean

for tempfile in ${TEMPDIR}/certs/*.tmp; do
  # Make sure that the cert is trusted...
  grep "CKA_TRUST_SERVER_AUTH" "${tempfile}" | \
    egrep "TRUST_UNKNOWN|NOT_TRUSTED" > /dev/null

  if test "${?}" = "0"; then
    # Throw a meaningful error and remove the file
    cp "${tempfile}" tempfile.cer
    perl ${CONVERTSCRIPT} > tempfile.crt
    keyhash=$(openssl x509 -noout -in tempfile.crt -hash)
    echo "Certificate ${keyhash} is not trusted!  Removing..."
    rm -f tempfile.cer tempfile.crt "${tempfile}"
    continue
  fi

  # If execution made it to here in the loop, the temp cert is trusted
  # Find the cert data and generate a cert file for it

  cp "${tempfile}" tempfile.cer
  perl ${CONVERTSCRIPT} > tempfile.crt
  keyhash=$(openssl x509 -noout -in tempfile.crt -hash)
  mv tempfile.crt "certs/${keyhash}.pem"
  rm -f tempfile.cer "${tempfile}"
  echo "Created ${keyhash}.pem"
done

# Remove blacklisted files
# MD5 Collision Proof of Concept CA
if test -f certs/8f111d69.pem; then
  echo "Certificate 8f111d69 is not trusted!  Removing..."
  rm -f certs/8f111d69.pem
fi

# Finally, generate the bundle and clean up.
cat certs/*.pem >  ${BUNDLE}
rm -r "${TEMPDIR}"
EOF

chmod +x /usr/bin/make-ca.sh


cat > /usr/sbin/remove-expired-certs.sh << "EOF"
#!/bin/sh
# Begin /usr/sbin/remove-expired-certs.sh
#
# Version 20120211

# Make sure the date is parsed correctly on all systems
mydate()
{
  local y=$( echo $1 | cut -d" " -f4 )
  local M=$( echo $1 | cut -d" " -f1 )
  local d=$( echo $1 | cut -d" " -f2 )
  local m

  if [ ${d} -lt 10 ]; then d="0${d}"; fi

  case $M in
    Jan) m="01";;
    Feb) m="02";;
    Mar) m="03";;
    Apr) m="04";;
    May) m="05";;
    Jun) m="06";;
    Jul) m="07";;
    Aug) m="08";;
    Sep) m="09";;
    Oct) m="10";;
    Nov) m="11";;
    Dec) m="12";;
  esac

  certdate="${y}${m}${d}"
}

OPENSSL=/usr/bin/openssl
DIR=/etc/ssl/certs

if [ $# -gt 0 ]; then
  DIR="$1"
fi

certs=$( find ${DIR} -type f -name "*.pem" -o -name "*.crt" )
today=$( date +%Y%m%d )

for cert in $certs; do
  notafter=$( $OPENSSL x509 -enddate -in "${cert}" -noout )
  date=$( echo ${notafter} |  sed 's/^notAfter=//' )
  mydate "$date"

  if [ ${certdate} -lt ${today} ]; then
     echo "${cert} expired on ${certdate}! Removing..."
     rm -f "${cert}"
  fi
done
EOF

chmod u+x /usr/sbin/remove-expired-certs.sh


######################################################################################
URL=http://anduin.linuxfromscratch.org/sources/other/certdata.txt &&
rm -f certdata.txt &&
wget $URL          &&
make-ca.sh         &&
unset URL
######################################################################################

make-ca.sh

SSLDIR=/etc/ssl                                              &&
remove-expired-certs.sh certs                                &&
install -d ${SSLDIR}/certs                                   &&
cp -v certs/*.pem ${SSLDIR}/certs                            &&
c_rehash                                                     &&
install BLFS-ca-bundle*.crt ${SSLDIR}/ca-bundle.crt          &&
ln -sfv ../ca-bundle.crt ${SSLDIR}/certs/ca-certificates.crt &&
unset SSLDIR

rm -r certs BLFS-ca-bundle*

--------------------------------------------------------------------------------------y

tar -xf p11-kit-0.23.1.tar.gz &&
cd p11-kit-0.23.1 &&
./configure --prefix=/usr --sysconfdir=/etc &&
make

make install

cd /xc &&
rm -rf p11-kit-0.23.1

--------------------------------------------------------------------------------------y

tar -xf gnutls-3.4.4.1.tar.xz &&
cd gnutls-3.4.4.1 &&
./configure --prefix=/usr \
            --with-default-trust-store-file=/etc/ssl/ca-bundle.crt &&
make

make install

make -C doc/reference install-data-local

cd /xc &&
rm -rf gnutls-3.4.4.1

--------------------------------------------------------------------------------------y

tar -xf wget-1.16.3.tar.xz &&
cd wget-1.16.3 &&
./configure --prefix=/usr --sysconfdir=/etc &&
make

make install

echo ca-directory=/etc/ssl/certs >> /etc/wgetrc

cd /xc &&
rm -rf wget-1.16.3

--------------------------------------------------------------------------------------

cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend

# Set the initial path
export PATH=/bin:/usr/bin

if [ $EUID -eq 0 ] ; then
        pathappend /sbin:/usr/sbin
        unset HISTFILE
fi

# Setup some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"

# Set some defaults for graphical systems
export XDG_DATA_DIRS=/usr/share/
export XDG_CONFIG_DIRS=/etc/xdg/

# Setup a red prompt for root and a green one for users.
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

for script in /etc/profile.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done

unset script RED GREEN NORMAL

# End /etc/profile
EOF

install --directory --mode=0755 --owner=root --group=root /etc/profile.d

cat > /etc/profile.d/dircolors.sh << "EOF"
# Setup for /bin/ls and /bin/grep to support color, the alias is in /etc/bashrc.
if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)
fi

if [ -f "$HOME/.dircolors" ] ; then
        eval $(dircolors -b $HOME/.dircolors)
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
EOF

cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

# Set some defaults before other applications add to these paths.
pathappend /usr/share/man  MANPATH
pathappend /usr/share/info INFOPATH
EOF

cat > /etc/profile.d/readline.sh << "EOF"
# Setup the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF

cat > /etc/profile.d/umask.sh << "EOF"
# By default, the umask should be set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF

cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>
export LANG=POSIX
EOF

cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides colored /bin/ls and /bin/grep commands.  Used in conjunction
# with code in /etc/profile.

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u@\h [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u@\h [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

unset RED GREEN NORMAL

# End /etc/bashrc
EOF

cat > ~/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF

cat > ~/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

if [ -f "/etc/bashrc" ] ; then
  source /etc/bashrc
fi

# End ~/.bashrc
EOF

cat > ~/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal items to perform on logout.

# End ~/.bash_logout
EOF

dircolors -p > /etc/dircolors

--------------------------------------------------------------------------------------
2016-10-30
--------------------------------------------------------------------------------------

sudo su

export LFS=/mnt/lfs &&
mkdir $LFS &&
mount /dev/sda2 &&
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


MAKEFLAGS='-j 5' &&
export XORG_PREFIX="/usr" &&
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc \
    --localstatedir=/var --disable-static" &&
cd /xc

mkdir wget
mv *.gz wget/
mv *.xz wget/
mv *.txt wget/
ls wget
certdata.txt           libffi-3.2.1.tar.gz  nettle-3.1.1.tar.gz    p11-kit-0.23.1.tar.gz
gnutls-3.4.4.1.tar.xz  libtasn1-4.6.tar.gz  openssl-1.0.2d.tar.gz  wget-1.16.3.tar.xz

--------------------------------------------------------------------------------------

wget  http://ftp.x.org/pub/individual/util/util-macros-1.19.0.tar.bz2

tar -xf util-macros-1.19.0.tar.bz2 &&
cd util-macros-1.19.0 &&
./configure $XORG_CONFIG

make install

cd /xc &&
rm -rf util-macros-1.19.0

--------------------------------------------------------------------------------------

wget http://www.sudo.ws/dist/sudo-1.8.14p3.tar.gz

tar -xf sudo-1.8.14p3.tar.gz &&
cd sudo-1.8.14p3 &&
./configure --prefix=/usr              \
            --libexecdir=/usr/lib      \
            --with-secure-path         \
            --with-all-insults         \
            --with-env-editor          \
            --docdir=/usr/share/doc/sudo-1.8.14p3 \
            --with-passprompt="[sudo] password for %p" &&
make

make install &&
ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0

cd /xc &&
rm -rf sudo-1.8.14p3

--------------------------------------------------------------------------------------

cat > proto-7.7.md5 << "EOF"
1a05fb01fa1d5198894c931cf925c025  bigreqsproto-1.1.2.tar.bz2
98482f65ba1e74a08bf5b056a4031ef0  compositeproto-0.4.2.tar.bz2
998e5904764b82642cc63d97b4ba9e95  damageproto-1.2.1.tar.bz2
4ee175bbd44d05c34d43bb129be5098a  dmxproto-2.3.1.tar.bz2
b2721d5d24c04d9980a0c6540cb5396a  dri2proto-2.8.tar.bz2
a3d2cbe60a9ca1bf3aea6c93c817fee3  dri3proto-1.0.tar.bz2
e7431ab84d37b2678af71e29355e101d  fixesproto-5.0.tar.bz2
36934d00b00555eaacde9f091f392f97  fontsproto-2.1.3.tar.bz2
5565f1b0facf4a59c2778229c1f70d10  glproto-1.4.17.tar.bz2
6caebead4b779ba031727f66a7ffa358  inputproto-2.3.1.tar.bz2
94afc90c1f7bef4a27fdd59ece39c878  kbproto-1.0.7.tar.bz2
2d569c75884455c7148d133d341e8fd6  presentproto-1.0.tar.bz2
a46765c8dcacb7114c821baf0df1e797  randrproto-1.5.0.tar.bz2
1b4e5dede5ea51906f1530ca1e21d216  recordproto-1.14.2.tar.bz2
a914ccc1de66ddeb4b611c6b0686e274  renderproto-0.11.1.tar.bz2
cfdb57dae221b71b2703f8e2980eaaf4  resourceproto-1.2.0.tar.bz2
edd8a73775e8ece1d69515dd17767bfb  scrnsaverproto-1.2.2.tar.bz2
e658641595327d3990eab70fdb55ca8b  videoproto-2.3.2.tar.bz2
5f4847c78e41b801982c8a5e06365b24  xcmiscproto-1.2.2.tar.bz2
70c90f313b4b0851758ef77b95019584  xextproto-7.3.0.tar.bz2
120e226ede5a4687b25dd357cc9b8efe  xf86bigfontproto-1.2.0.tar.bz2
a036dc2fcbf052ec10621fd48b68dbb1  xf86dgaproto-2.1.tar.bz2
1d716d0dac3b664e5ee20c69d34bc10e  xf86driproto-2.1.1.tar.bz2
e793ecefeaecfeabd1aed6a01095174e  xf86vidmodeproto-2.3.1.tar.bz2
9959fe0bfb22a0e7260433b8d199590a  xineramaproto-1.2.1.tar.bz2
3ce2f230c5d8fa929f326ad1f0fa40a8  xproto-7.0.28.tar.bz2
EOF

mkdir proto &&
cd proto &&
grep -v '^#' ../proto-7.7.md5 | awk '{print $2}' | wget -i- -c \
    -B http://ftp.x.org/pub/individual/proto/ &&
md5sum -c ../proto-7.7.md5

as_root()
{
  if   [ $EUID = 0 ];        then $*
  elif [ -x /usr/bin/sudo ]; then sudo $*
  else                            su -c \\"$*\\"
  fi
}

export -f as_root

bash -e

for package in $(grep -v '^#' ../proto-7.7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  ./configure $XORG_CONFIG
  as_root make install
  popd
  rm -rf $packagedir
done

exit

cd /xc

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/lib/libXau-1.0.8.tar.bz2

tar -xf libXau-1.0.8.tar.bz2 &&
cd libXau-1.0.8 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf libXau-1.0.8

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/lib/libXdmcp-1.1.2.tar.bz2

tar -xf libXdmcp-1.1.2.tar.bz2 &&
cd libXdmcp-1.1.2 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf libXdmcp-1.1.2

--------------------------------------------------------------------------------------1

wget http://downloads.sourceforge.net/tcl/tcl8.6.4-src.tar.gz &&
wget http://downloads.sourceforge.net/tcl/tcl8.6.4-html.tar.gz

tar -xf tcl8.6.4-src.tar.gz &&
cd tcl8.6.4 &&
tar -xf ../tcl8.6.4-html.tar.gz --strip-components=1

export SRCDIR=`pwd` &&
cd unix &&
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
make &&
sed -e "s#$SRCDIR/unix#/usr/lib#" \
    -e "s#$SRCDIR#/usr/include#"  \
    -i tclConfig.sh               &&
sed -e "s#$SRCDIR/unix/pkgs/tdbc1.0.3#/usr/lib/tdbc1.0.3#" \
    -e "s#$SRCDIR/pkgs/tdbc1.0.3/generic#/usr/include#"    \
    -e "s#$SRCDIR/pkgs/tdbc1.0.3/library#/usr/lib/tcl8.6#" \
    -e "s#$SRCDIR/pkgs/tdbc1.0.3#/usr/include#"            \
    -i pkgs/tdbc1.0.3/tdbcConfig.sh                        &&
sed -e "s#$SRCDIR/unix/pkgs/itcl4.0.3#/usr/lib/itcl4.0.3#" \
    -e "s#$SRCDIR/pkgs/itcl4.0.3/generic#/usr/include#"    \
    -e "s#$SRCDIR/pkgs/itcl4.0.3#/usr/include#"            \
    -i pkgs/itcl4.0.3/itclConfig.sh                        &&
unset SRCDIR

make install &&
make install-private-headers &&
ln -v -sf tclsh8.6 /usr/bin/tclsh &&
chmod -v 755 /usr/lib/libtcl8.6.so

mkdir -v -p /usr/share/doc/tcl-8.6.4 &&
cp -v -r  ../html/* /usr/share/doc/tcl-8.6.4

cd /xc &&
rm -rf tcl8.6.4

--------------------------------------------------------------------------------------2

wget http://prdownloads.sourceforge.net/expect/expect5.45.tar.gz

tar -xf expect5.45.tar.gz &&
cd expect5.45 && 
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include &&
make

make install &&
ln -svf expect5.45/libexpect5.45.so /usr/lib

cd /xc &&
rm -rf xpect5.45

--------------------------------------------------------------------------------------3

wget https://ftp.gnu.org/pub/gnu/dejagnu/dejagnu-1.5.3.tar.gz

tar -xf dejagnu-1.5.3.tar.gz &&
cd dejagnu-1.5.3 &&
./configure --prefix=/usr &&
makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi &&
makeinfo --plaintext       -o doc/dejagnu.txt  doc/dejagnu.texi

make install &&
install -v -dm755   /usr/share/doc/dejagnu-1.5.3 &&
install -v -m644    doc/dejagnu.{html,txt} \
                    /usr/share/doc/dejagnu-1.5.3

cd /xc &&
rm -rf dejagnu-1.5.3

--------------------------------------------------------------------------------------4

wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
md5sum libffi-3.2.1.tar.gz
83b89587607e3eb65c70d361f13bab43  libffi-3.2.1.tar.gz
83b89587607e3eb65c70d361f13bab43

tar -xf libffi-3.2.1.tar.gz &&
cd libffi-3.2.1 &&
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in &&

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in        &&

./configure --prefix=/usr --disable-static &&
make

make install

cd /xc &&
rm -rf libffi-3.2.1

--------------------------------------------------------------------------------------5

wget https://www.python.org/ftp/python/3.4.3/Python-3.4.3.tar.xz &&
#wget https://docs.python.org/3.4/archives/python-3.4.3-docs-html.tar.bz2
wget http://ftp.lfs-matrix.net/pub/blfs/7.8/p/python-3.4.3-docs-html.tar.bz2
md5sum Python-3.4.3.tar.xz
7d092d1bba6e17f0d9bd21b49e441dd5  Python-3.4.3.tar.xz
7d092d1bba6e17f0d9bd21b49e441dd5 

tar -xf Python-3.4.3.tar.xz &&
cd Python-3.4.3 &&
CXX="/usr/bin/g++"              \
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --without-ensurepip &&
make

make install &&
chmod -v 755 /usr/lib/libpython3.4m.so &&
chmod -v 755 /usr/lib/libpython3.so

install -v -dm755 /usr/share/doc/python-3.4.5/html &&
tar --strip-components=1 \
    --no-same-owner \
    --no-same-permissions \
    -C /usr/share/doc/python-3.4.5/html \
    -xvf ../python-3.4.5-docs-html.tar.bz2

export PYTHONDOCS=/usr/share/doc/python-3.4.3/html

install -v -dm755 /usr/share/doc/python-3.4.3/html

tar --strip-components=1 \
    --no-same-owner \
    --no-same-permissions \
    -C /usr/share/doc/python-3.4.3/html \
    -xvf ../python-3.4.3-docs-html.tar.bz2

export PYTHONDOCS=/usr/share/doc/python-3.4.3/html

cd /xc &&
rm -rf Python-3.4.3

--------------------------------------------------------------------------------------6

wget http://xcb.freedesktop.org/dist/xcb-proto-1.11.tar.bz2
md5sum xcb-proto-1.11.tar.bz2
6bf2797445dc6d43e9e4707c082eff9c  xcb-proto-1.11.tar.bz2
6bf2797445dc6d43e9e4707c082eff9c 

tar -xf xcb-proto-1.11.tar.bz2 &&
cd xcb-proto-1.11 &&
./configure $XORG_CONFIG

make install

cd /xc &&
rm -rf xcb-proto-1.11

--------------------------------------------------------------------------------------

wget http://xcb.freedesktop.org/dist/libxcb-1.11.1.tar.bz2
md5sum libxcb-1.11.1.tar.bz2
f97a65e6158775de518ac391935634c2  libxcb-1.11.1.tar.bz2
f97a65e6158775de518ac391935634c2 

tar -xf libxcb-1.11.1.tar.bz2 &&
cd libxcb-1.11.1 &&
sed -i "s/pthread-stubs//" configure &&
./configure $XORG_CONFIG      \
            --enable-xinput   \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.11.1 &&
make

make install

cd /xc &&
rm -rf libxcb-1.11.1

--------------------------------------------------------------------------------------1

wget http://ftp.gnu.org/gnu/which/which-2.21.tar.gz
md5sum which-2.21.tar.gz
097ff1a324ae02e0a3b0369f07a7544a  which-2.21.tar.gz
097ff1a324ae02e0a3b0369f07a7544a

tar -xf which-2.21.tar.gz &&
cd which-2.21 &&
./configure --prefix=/usr &&
make

make install

cd /xc &&
rm -rf which-2.21

cat > /usr/bin/which << "EOF"
#!/bin/bash
type -pa "$@" | head -n 1 ; exit ${PIPESTATUS[0]}
EOF

chmod -v 755 /usr/bin/which &&
chown -v root:root /usr/bin/which

--------------------------------------------------------------------------------------2

wget http://downloads.sourceforge.net/libpng/libpng-1.6.18.tar.xz
wget http://downloads.sourceforge.net/libpng-apng/libpng-1.6.18-apng.patch.gz
md5sum libpng-1.6.18.tar.xz
6a57c8e0f5469b9c9949a4b43d57b3a1  libpng-1.6.18.tar.xz
6a57c8e0f5469b9c9949a4b43d57b3a1

tar -xf libpng-1.6.18.tar.xz &&
cd libpng-1.6.18

gzip -cd ../libpng-1.6.18-apng.patch.gz | patch -p1

./configure --prefix=/usr --disable-static &&
make

make install

mkdir -v /usr/share/doc/libpng-1.6.18 &&
cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.18

cd /xc &&
rm -rf libpng-1.6.18

------------------------------------------------------------------------------------No3.1

wget http://ftp.gnome.org/pub/gnome/sources/glib/2.44/glib-2.44.1.tar.xz
md5sum glib-2.44.1.tar.xz
83efba4722a9674b97437d1d99af79db  glib-2.44.1.tar.xz
83efba4722a9674b97437d1d99af79db

tar -xf glib-2.44.1.tar.xz &&
cd glib-2.44.1 &&
./configure --prefix=/usr --with-pcre=system &&
make

#configure: error: Package requirements (libpcre >= 8.13) were not met:

#No package 'libpcre' found

#Consider adjusting the PKG_CONFIG_PATH environment variable if you
#installed software in a non-standard prefix.

#Alternatively, you may set the environment variables PCRE_CFLAGS
#and PCRE_LIBS to avoid the need to call pkg-config.
#See the pkg-config man page for more details.

make install

cd /xc &&
rm -rf glib-2.44.1

------------------------------------------------------------------------------------No3.2

wget http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.0.3.tar.bz2
md5sum harfbuzz-1.0.3.tar.bz2
bf459ed21c68d97fbb3313cbdee53268  harfbuzz-1.0.3.tar.bz2
bf459ed21c68d97fbb3313cbdee53268 

tar -xf harfbuzz-1.0.3.tar.bz2 &&
cd harfbuzz-1.0.3 &&
./configure --prefix=/usr --with-gobject &&
make

make install

cd /xc &&
rm -rf harfbuzz-1.0.3

--------------------------------------------------------------------------------------

wget http://downloads.sourceforge.net/freetype/freetype-2.6.tar.bz2
5682890cb0267f6671dd3de6eabd3e69  freetype-2.6.tar.bz2
5682890cb0267f6671dd3de6eabd3e69

wget http://downloads.sourceforge.net/freetype/freetype-doc-2.6.tar.bz2
f456b7ead3c351c7c218bb3afd45803c 

tar -xf freetype-2.6.tar.bz2 &&
cd freetype-2.6

tar -xf ../freetype-doc-2.6.tar.bz2 --strip-components=2 -C docs

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

cd /xc &&
rm -rf freetype-2.6

--------------------------------------------------------------------------------------

wget http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.1.tar.bz2
824d000eb737af6e16c826dd3b2d6c90  fontconfig-2.11.1.tar.bz2
824d000eb737af6e16c826dd3b2d6c90

tar -xf fontconfig-2.11.1.tar.bz2 &&
cd fontconfig-2.11.1 &&
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-docs       \
            --docdir=/usr/share/doc/fontconfig-2.11.1 &&
make

make install

install -v -dm755 \
        /usr/share/{man/man{3,5},doc/fontconfig-2.11.1/fontconfig-devel} &&
install -v -m644 fc-*/*.1          /usr/share/man/man1 &&
install -v -m644 doc/*.3           /usr/share/man/man3 &&
install -v -m644 doc/fonts-conf.5  /usr/share/man/man5 &&
install -v -m644 doc/fontconfig-devel/* \
        /usr/share/doc/fontconfig-2.11.1/fontconfig-devel &&
install -v -m644 doc/*.{pdf,sgml,txt,html} \
       /usr/share/doc/fontconfig-2.11.1

cd /xc &&
rm -rf fontconfig-2.11.1

--------------------------------------------------------------------------------------

cat > lib-7.7.md5 << "EOF"
c5ba432dd1514d858053ffe9f4737dd8  xtrans-1.3.5.tar.bz2
2e36b73f8a42143142dda8129f02e4e0  libX11-1.6.3.tar.bz2
52df7c4c1f0badd9f82ab124fb32eb97  libXext-1.3.3.tar.bz2
d79d9fe2aa55eb0f69b1a4351e1368f7  libFS-1.0.7.tar.bz2
addfb1e897ca8079531669c7c7711726  libICE-1.0.9.tar.bz2
499a7773c65aba513609fe651853c5f3  libSM-1.2.2.tar.bz2
7a773b16165e39e938650bcc9027c1d5  libXScrnSaver-1.2.2.tar.bz2
8f5b5576fbabba29a05f3ca2226f74d3  libXt-1.1.5.tar.bz2
41d92ab627dfa06568076043f3e089e4  libXmu-1.1.2.tar.bz2
769ee12a43611cdebd38094eaf83f3f0  libXpm-3.5.11.tar.bz2
e5e06eb14a608b58746bdd1c0bd7b8e3  libXaw-1.0.13.tar.bz2
b985b85f8b9386c85ddcfe1073906b4d  libXfixes-5.0.1.tar.bz2
f7a218dcbf6f0848599c6c36fc65c51a  libXcomposite-0.4.4.tar.bz2
5db92962b124ca3a8147daae4adbd622  libXrender-0.9.9.tar.bz2
1e7c17afbbce83e2215917047c57d1b3  libXcursor-1.1.14.tar.bz2
0cf292de2a9fa2e9a939aefde68fd34f  libXdamage-1.1.4.tar.bz2
0920924c3a9ebc1265517bdd2f9fde50  libfontenc-1.1.3.tar.bz2
96f76ba94b4c909230bac1e2dcd551c4  libXfont-1.5.1.tar.bz2
331b3a2a3a1a78b5b44cfbd43f86fcfe  libXft-2.3.2.tar.bz2
9c4a69c34b19ec1e4212e849549544cb  libXi-1.7.4.tar.bz2
9336dc46ae3bf5f81c247f7131461efd  libXinerama-1.1.3.tar.bz2
309762867e41c6fd813da880d8a1bc93  libXrandr-1.5.0.tar.bz2
45ef29206a6b58254c81bea28ec6c95f  libXres-1.0.7.tar.bz2
25c6b366ac3dc7a12c5d79816ce96a59  libXtst-1.2.2.tar.bz2
e0af49d7d758b990e6fef629722d4aca  libXv-1.0.10.tar.bz2
eba6b738ed5fdcd8f4203d7c8a470c79  libXvMC-1.0.9.tar.bz2
d7dd9b9df336b7dd4028b6b56542ff2c  libXxf86dga-1.1.4.tar.bz2
298b8fff82df17304dfdb5fe4066fe3a  libXxf86vm-1.1.4.tar.bz2
ba983eba5a9f05d152a0725b8e863151  libdmx-1.1.3.tar.bz2
ace78aec799b1cf6dfaea55d3879ed9f  libpciaccess-0.13.4.tar.bz2
4a4cfeaf24dab1b991903455d6d7d404  libxkbfile-1.0.9.tar.bz2
66662e76899112c0f99e22f2fc775a7e  libxshmfence-1.2.tar.bz2
EOF

mkdir lib &&
cd lib &&
grep -v '^#' ../lib-7.7.md5 | awk '{print $2}' | wget -i- -c \
    -B http://ftp.x.org/pub/individual/lib/ &&
md5sum -c ../lib-7.7.md5

as_root()
{
  if   [ $EUID = 0 ];        then $*
  elif [ -x /usr/bin/sudo ]; then sudo $*
  else                            su -c \\"$*\\"
  fi
}

export -f as_root

#grep -A9 summary *make_check.log

bash -e

for package in $(grep -v '^#' ../lib-7.7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  case $packagedir in
    libXfont-[0-9]* )
      ./configure $XORG_CONFIG --disable-devel-docs
    ;;
    libXt-[0-9]* )
      ./configure $XORG_CONFIG \
                  --with-appdefaultdir=/etc/X11/app-defaults
    ;;
    * )
      ./configure $XORG_CONFIG
    ;;
  esac
  make
  #make check 2>&1 | tee ../$packagedir-make_check.log
  as_root make install
  popd
  rm -rf $packagedir
  as_root /sbin/ldconfig
done

exit

#ln -sv $XORG_PREFIX/lib/X11 /usr/lib/X11 &&
#ln -sv $XORG_PREFIX/include/X11 /usr/include/X11

cd /xc

--------------------------------------------------------------------------------------

wget http://xcb.freedesktop.org/dist/xcb-util-0.4.0.tar.bz2
md5sum xcb-util-0.4.0.tar.bz2
2e97feed81919465a04ccc71e4073313  xcb-util-0.4.0.tar.bz2
2e97feed81919465a04ccc71e4073313 

tar -xf xcb-util-0.4.0.tar.bz2 &&
cd xcb-util-0.4.0 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xcb-util-0.4.0

--------------------------------------------------------------------------------------

wget http://xcb.freedesktop.org/dist/xcb-util-image-0.4.0.tar.bz2
08fe8ffecc8d4e37c0ade7906b3f4c87  xcb-util-image-0.4.0.tar.bz2
08fe8ffecc8d4e37c0ade7906b3f4c87

tar -xf xcb-util-image-0.4.0.tar.bz2 &&
cd xcb-util-image-0.4.0 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xcb-util-image-0.4.0

--------------------------------------------------------------------------------------

wget http://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.0.tar.bz2
md5sum xcb-util-keysyms-0.4.0.tar.bz2
1022293083eec9e62d5659261c29e367  xcb-util-keysyms-0.4.0.tar.bz2
1022293083eec9e62d5659261c29e367 

tar -xf xcb-util-keysyms-0.4.0.tar.bz2 &&
cd xcb-util-keysyms-0.4.0 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
cd xcb-util-keysyms-0.4.0

--------------------------------------------------------------------------------------

wget http://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.9.tar.bz2
md5sum xcb-util-renderutil-0.3.9.tar.bz2
468b119c94da910e1291f3ffab91019a  xcb-util-renderutil-0.3.9.tar.bz2
468b119c94da910e1291f3ffab91019a

tar -xf xcb-util-renderutil-0.3.9.tar.bz2 &&
cd xcb-util-renderutil-0.3.9 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xcb-util-renderutil-0.3.9

--------------------------------------------------------------------------------------

wget http://xcb.freedesktop.org/dist/xcb-util-wm-0.4.1.tar.bz2
md5sum xcb-util-wm-0.4.1.tar.bz2 
87b19a1cd7bfcb65a24e36c300e03129  xcb-util-wm-0.4.1.tar.bz2
87b19a1cd7bfcb65a24e36c300e03129 

tar -xf xcb-util-wm-0.4.1.tar.bz2 &&
cd xcb-util-wm-0.4.1 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf cd xcb-util-wm-0.4.1

--------------------------------------------------------------------------------------1

wget http://dri.freedesktop.org/libdrm/libdrm-2.4.64.tar.bz2
md5sum libdrm-2.4.64.tar.bz2 
543b2d28359cf33974fa0e772dd61732  libdrm-2.4.64.tar.bz2
543b2d28359cf33974fa0e772dd61732

tar -xf libdrm-2.4.64.tar.bz2 &&
cd libdrm-2.4.64 &&
sed -e "/pthread-stubs/d" \
    -i configure.ac &&
autoreconf -fiv     &&
./configure --prefix=/usr \
            --enable-udev \
            --disable-valgrind &&
make

make install

cd /xc &&
rm -rf libdrm-2.4.64

--------------------------------------------------------------------------------------2

wget https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tar.xz
wget https://docs.python.org/2.7/archives/python-2.7.10-docs-html.tar.bz2
wget ftp://ftp.lfs-matrix.net/pub/blfs/7.8/p/python-2.7.10-docs-html.tar.bz2
md5sum Python-2.7.10.tar.xz
c685ef0b8e9f27b5e3db5db12b268ac6  Python-2.7.10.tar.xz
c685ef0b8e9f27b5e3db5db12b268ac6

tar -xf Python-2.7.10.tar.xz &&
cd Python-2.7.10 &&
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --enable-unicode=ucs4 &&
make

make install &&
chmod -v 755 /usr/lib/libpython2.7.so.1.0

install -v -dm755 /usr/share/doc/python-2.7.10

tar --strip-components=1                     \
    --no-same-owner                          \
    --directory /usr/share/doc/python-2.7.10 \
    -xvf ../python-2.7.10-docs-html.tar.bz2

find /usr/share/doc/python-2.7.10 -type d -exec chmod 0755 {} \; &&
find /usr/share/doc/python-2.7.10 -type f -exec chmod 0644 {} \;

export PYTHONDOCS=/usr/share/doc/python-2.7.10

cd /xc &&
rm -rf Python-2.7.10

--------------------------------------------------------------------------------------3

wget http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
md5sum llvm-3.7.0.src.tar.xz
b98b9495e5655a672d6cb83e1a180f8e  llvm-3.7.0.src.tar.xz
b98b9495e5655a672d6cb83e1a180f8e

wget http://llvm.org/releases/3.7.0/cfe-3.7.0.src.tar.xz
md5sum cfe-3.7.0.src.tar.xz
8f9d27335e7331cf0a4711e952f21f01  cfe-3.7.0.src.tar.xz
8f9d27335e7331cf0a4711e952f21f01

wget http://llvm.org/releases/3.7.0/compiler-rt-3.7.0.src.tar.xz
md5sum compiler-rt-3.7.0.src.tar.xz
383c10affd513026f08936b5525523f5  compiler-rt-3.7.0.src.tar.xz
383c10affd513026f08936b5525523f5

tar -xf llvm-3.7.0.src.tar.xz &&
cd llvm-3.7.0.src &&
tar -xf ../cfe-3.7.0.src.tar.xz -C tools &&
tar -xf ../compiler-rt-3.7.0.src.tar.xz -C projects &&
mv tools/cfe-3.7.0.src tools/clang &&
mv projects/compiler-rt-3.7.0.src projects/compiler-rt

sed -r "/ifeq.*CompilerTargetArch/s#i386#i686#g" \
    -i projects/compiler-rt/make/platform/clang_linux.mk

sed -e "s:/docs/llvm:/share/doc/llvm-3.7.0:" \
    -i Makefile.config.in &&
mkdir -v build &&
cd       build &&
CC=gcc CXX=g++                          \
../configure --prefix=/usr              \
             --datarootdir=/usr/share   \
             --sysconfdir=/etc          \
             --enable-libffi            \
             --enable-optimized         \
             --enable-shared            \
             --enable-targets=host,r600 \
             --disable-assertions       \
             --docdir=/usr/share/doc/llvm-3.7.0 &&
make

#make -C ../docs -f Makefile.sphinx man
-----------------------------------------------------
#make: Entering directory '/xc/llvm-3.7.0.src/docs'
#sphinx-build -b man -d _build/doctrees   . _build/man
#make: sphinx-build: Command not found
#Makefile.sphinx:119: recipe for target 'man' failed
#make: *** [man] Error 127
#make: Leaving directory '/xc/llvm-3.7.0.src/docs'
-----------------------------------------------------

make install &&
for file in /usr/lib/lib{clang,LLVM,LTO}*.a
do
  test -f $file && chmod -v 644 $file
done &&
unset file

install -v -dm755 /usr/lib/clang-analyzer &&
for prog in scan-build scan-view
do
  cp -rfv ../tools/clang/tools/$prog /usr/lib/clang-analyzer/
  ln -sfv ../lib/clang-analyzer/$prog/$prog /usr/bin/
done &&
ln -sfv /usr/bin/clang /usr/lib/clang-analyzer/scan-build/ &&
mv -v /usr/lib/clang-analyzer/scan-build/scan-build.1 /usr/share/man/man1/ &&
unset prog

#install -v -m644 ../docs/_build/man/* /usr/share/man/man1/
-----------------------------------------------------
#install: cannot stat '../docs/_build/man/*': No such file or directory
-----------------------------------------------------

cd /xc &&
rm -rf llvm-3.7.0.src

--------------------------------------------------------------------------------------4

wget https://fedorahosted.org/releases/e/l/elfutils/0.163/elfutils-0.163.tar.bz2
md5sum elfutils-0.163.tar.bz2 
77ce87f259987d2e54e4d87b86cbee41  elfutils-0.163.tar.bz2
77ce87f259987d2e54e4d87b86cbee41

tar -xf elfutils-0.163.tar.bz2 &&
cd elfutils-0.163 &&
./configure --prefix=/usr --program-prefix="eu-" &&
make

make install

cd /xc &&
rm -rf elfutils-0.163

--------------------------------------------------------------------------------------5

#wget ftp://ftp.freedesktop.org/pub/mesa/10.6.6/mesa-10.6.6.tar.xz
wget ftp://ftp.lfs-matrix.net/pub/blfs/7.8/Xorg/mesa-10.6.6.tar.xz
wget http://www.linuxfromscratch.org/patches/blfs/7.8/mesa-10.6.6-llvm_3_7-1.patch
wget http://www.linuxfromscratch.org/patches/blfs/7.8/mesa-10.6.6-add_xdemos-1.patch
ce091e6e969392f7c63ca8c0275bbc0f  mesa-10.6.6.tar.xz
ce091e6e969392f7c63ca8c0275bbc0f

tar -xf mesa-10.6.6.tar.xz &&
cd mesa-10.6.6 &&
patch -Np1 -i ../mesa-10.6.6-add_xdemos-1.patch &&
patch -Np1 -i ../mesa-10.6.6-llvm_3_7-1.patch

GLL_DRV="nouveau,r300,r600,radeonsi,svga,swrast" &&
./autogen.sh CFLAGS='-O2' CXXFLAGS='-O2'    \
            --prefix=$XORG_PREFIX           \
            --sysconfdir=/etc               \
            --enable-texture-float          \
            --enable-gles1                  \
            --enable-gles2                  \
            --enable-osmesa                 \
            --enable-xa                     \
            --enable-gbm                    \
            --enable-glx-tls                \
            --with-egl-platforms="drm,x11"  \
            --with-gallium-drivers=$GLL_DRV &&
unset GLL_DRV &&
make

#make -C xdemos DEMOS_PREFIX=$XORG_PREFIX
--------
#make: Entering directory '/xc/mesa-10.6.6/xdemos'
#CC glxgears
#CC glxinfo
#make: Leaving directory '/xc/mesa-10.6.6/xdemos'
--------

make install

#make -C xdemos DEMOS_PREFIX=$XORG_PREFIX install
--------
#make: Entering directory '/xc/mesa-10.6.6/xdemos'
#test -e /usr/bin || install -dm755 /usr/bin
#test -e /usr/share/man/man1 || install -dm755 /usr/share/man/man1
#install -m755 glxgears glxinfo /usr/bin
#install -m644 glxgears.1 glxinfo.1 /usr/share/man/man1
#make: Leaving directory '/xc/mesa-10.6.6/xdemos'
--------

install -v -dm755 /usr/share/doc/mesa-10.6.6 &&
cp -rfv docs/* /usr/share/doc/mesa-10.6.6

cd /xc &&
rm -rf mesa-10.6.6

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/data/xbitmaps-1.1.1.tar.bz2
md5sum xbitmaps-1.1.1.tar.bz2 
7444bbbd999b53bec6a60608a5301f4c  xbitmaps-1.1.1.tar.bz2
7444bbbd999b53bec6a60608a5301f4c

tar -xf xbitmaps-1.1.1.tar.bz2 &&
cd xbitmaps-1.1.1 &&
./configure $XORG_CONFIG

make install

cd /xc &&
rm -rf cd xbitmaps-1.1.1

--------------------------------------------------------------------------------------

cat > app-7.7.md5 << "EOF"
53a48e1fdfec29ab2e89f86d4b7ca902  bdftopcf-1.0.5.tar.bz2
25dab02f8e40d5b71ce29a07dc901b8c  iceauth-1.0.7.tar.bz2
c4a3664e08e5a47c120ff9263ee2f20c  luit-1.1.1.tar.bz2
18c429148c96c2079edda922a2b67632  mkfontdir-1.0.7.tar.bz2
9bdd6ebfa62b1bbd474906ac86a40fd8  mkfontscale-1.1.2.tar.bz2
e238c89dabc566e1835e1ecb61b605b9  sessreg-1.1.0.tar.bz2
2c47a1b8e268df73963c4eb2316b1a89  setxkbmap-1.3.1.tar.bz2
3a93d9f0859de5d8b65a68a125d48f6a  smproxy-1.0.6.tar.bz2
f0b24e4d8beb622a419e8431e1c03cd7  x11perf-1.6.0.tar.bz2
7d6003f32838d5b688e2c8a131083271  xauth-1.0.9.tar.bz2
0066f23f69ca3ef62dcaeb74a87fdc48  xbacklight-1.2.1.tar.bz2
9956d751ea3ae4538c3ebd07f70736a0  xcmsdb-1.0.5.tar.bz2
b58a87e6cd7145c70346adad551dba48  xcursorgen-1.0.6.tar.bz2
8809037bd48599af55dad81c508b6b39  xdpyinfo-1.3.2.tar.bz2
fceddaeb08e32e027d12a71490665866  xdriinfo-1.0.5.tar.bz2
249bdde90f01c0d861af52dc8fec379e  xev-1.2.2.tar.bz2
90b4305157c2b966d5180e2ee61262be  xgamma-1.0.6.tar.bz2
f5d490738b148cb7f2fe760f40f92516  xhost-1.0.7.tar.bz2
305980ac78a6954e306a14d80a54c441  xinput-1.6.1.tar.bz2
0012a8e3092cddf7f87b250f96bb38c5  xkbcomp-1.3.0.tar.bz2
c747faf1f78f5a5962419f8bdd066501  xkbevd-1.1.4.tar.bz2
502b14843f610af977dffc6cbf2102d5  xkbutils-1.0.4.tar.bz2
0ae6bc2a8d3af68e9c76b1a6ca5f7a78  xkill-1.0.4.tar.bz2
5dcb6e6c4b28c8d7aeb45257f5a72a7d  xlsatoms-1.1.2.tar.bz2
9fbf6b174a5138a61738a42e707ad8f5  xlsclients-1.1.3.tar.bz2
2dd5ae46fa18abc9331bc26250a25005  xmessage-1.0.4.tar.bz2
723f02d3a5f98450554556205f0a9497  xmodmap-1.0.9.tar.bz2
6101f04731ffd40803df80eca274ec4b  xpr-1.0.4.tar.bz2
fae3d2fda07684027a643ca783d595cc  xprop-1.2.2.tar.bz2
441fdb98d2abc6051108b7075d948fc7  xrandr-1.4.3.tar.bz2
b54c7e3e53b4f332d41ed435433fbda0  xrdb-1.1.0.tar.bz2
a896382bc53ef3e149eaf9b13bc81d42  xrefresh-1.0.5.tar.bz2
dcd227388b57487d543cab2fd7a602d7  xset-1.2.3.tar.bz2
7211b31ec70631829ebae9460999aa0b  xsetroot-1.1.1.tar.bz2
558360176b718dee3c39bc0648c0d10c  xvinfo-1.1.3.tar.bz2
6b5d48464c5f366e91efd08b62b12d94  xwd-1.0.6.tar.bz2
b777bafb674555e48fd8437618270931  xwininfo-1.1.3.tar.bz2
3025b152b4f13fdffd0c46d0be587be6  xwud-1.0.4.tar.bz2
EOF

mkdir app &&
cd app &&
grep -v '^#' ../app-7.7.md5 | awk '{print $2}' | wget -i- -c \
    -B http://ftp.x.org/pub/individual/app/ &&
md5sum -c ../app-7.7.md5

as_root()
{
  if   [ $EUID = 0 ];        then $*
  elif [ -x /usr/bin/sudo ]; then sudo $*
  else                            su -c \\"$*\\"
  fi
}

export -f as_root

bash -e

for package in $(grep -v '^#' ../app-7.7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  case $packagedir in
    luit-[0-9]* )
      line1="#ifdef _XOPEN_SOURCE"
      line2="#  undef _XOPEN_SOURCE"
      line3="#  define _XOPEN_SOURCE 600"
      line4="#endif"

      sed -i -e "s@#ifdef HAVE_CONFIG_H@$line1\n$line2\n$line3\n$line4\n\n&@" sys.c
      unset line1 line2 line3 line4
    ;;
    sessreg-* )
      sed -e 's/\$(CPP) \$(DEFS)/$(CPP) -P $(DEFS)/' -i man/Makefile.in
    ;;
  esac
  ./configure $XORG_CONFIG
  make
  as_root make install
  popd
  rm -rf $packagedir
done

---------------------------------------------------------
#/bin/mkdir: cannot create directory '/usr/lib/X11': Too many levels of symbolic links
#Makefile:584: recipe for target 'install-dist_x11perfcompSCRIPTS' failed
#make[2]: *** [install-dist_x11perfcompSCRIPTS] Error 1
#make[2]: Leaving directory '/xc/app/x11perf-1.6.0'
#Makefile:967: recipe for target 'install-am' failed
#make[1]: *** [install-am] Error 2
#make[1]: Leaving directory '/xc/app/x11perf-1.6.0'
#Makefile:664: recipe for target 'install-recursive' failed
#make: *** [install-recursive] Error 1
---------------------------------------------------------
rm /usr/lib/X11
--------

exit

rm -f $XORG_PREFIX/bin/xkeystone

cd /xc

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/data/xcursor-themes-1.0.4.tar.bz2
md5sum xcursor-themes-1.0.4.tar.bz2 
fdfb0ad9cfceed60e3bfe9f18765aa0d  xcursor-themes-1.0.4.tar.bz2
fdfb0ad9cfceed60e3bfe9f18765aa0d

tar -xf xcursor-themes-1.0.4.tar.bz2 &&
cd xcursor-themes-1.0.4 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xcursor-themes-1.0.4

--------------------------------------------------------------------------------------

cat > font-7.7.md5 << "EOF"
23756dab809f9ec5011bb27fb2c3c7d6  font-util-1.3.1.tar.bz2
0f2d6546d514c5cc4ecf78a60657a5c1  encodings-1.0.4.tar.bz2
1347c3031b74c9e91dc4dfa53b12f143  font-adobe-100dpi-1.0.3.tar.bz2
6c9f26c92393c0756f3e8d614713495b  font-adobe-75dpi-1.0.3.tar.bz2
66fb6de561648a6dce2755621d6aea17  font-adobe-utopia-100dpi-1.0.4.tar.bz2
e99276db3e7cef6dccc8a57bc68aeba7  font-adobe-utopia-75dpi-1.0.4.tar.bz2
fcf24554c348df3c689b91596d7f9971  font-adobe-utopia-type1-1.0.4.tar.bz2
6d25f64796fef34b53b439c2e9efa562  font-alias-1.0.3.tar.bz2
cc0726e4a277d6ed93b8e09c1f195470  font-arabic-misc-1.0.3.tar.bz2
9f11ade089d689b9d59e0f47d26f39cd  font-bh-100dpi-1.0.3.tar.bz2
565494fc3b6ac08010201d79c677a7a7  font-bh-75dpi-1.0.3.tar.bz2
c8b73a53dcefe3e8d3907d3500e484a9  font-bh-lucidatypewriter-100dpi-1.0.3.tar.bz2
f6d65758ac9eb576ae49ab24c5e9019a  font-bh-lucidatypewriter-75dpi-1.0.3.tar.bz2
e8ca58ea0d3726b94fe9f2c17344be60  font-bh-ttf-1.0.3.tar.bz2
53ed9a42388b7ebb689bdfc374f96a22  font-bh-type1-1.0.3.tar.bz2
6b223a54b15ecbd5a1bc52312ad790d8  font-bitstream-100dpi-1.0.3.tar.bz2
d7c0588c26fac055c0dd683fdd65ac34  font-bitstream-75dpi-1.0.3.tar.bz2
5e0c9895d69d2632e2170114f8283c11  font-bitstream-type1-1.0.3.tar.bz2
e452b94b59b9cfd49110bb49b6267fba  font-cronyx-cyrillic-1.0.3.tar.bz2
3e0069d4f178a399cffe56daa95c2b63  font-cursor-misc-1.0.3.tar.bz2
0571bf77f8fab465a5454569d9989506  font-daewoo-misc-1.0.3.tar.bz2
6e7c5108f1b16d7a1c7b2c9760edd6e5  font-dec-misc-1.0.3.tar.bz2
bfb2593d2102585f45daa960f43cb3c4  font-ibm-type1-1.0.3.tar.bz2
a2401caccbdcf5698e001784dbd43f1a  font-isas-misc-1.0.3.tar.bz2
cb7b57d7800fd9e28ec35d85761ed278  font-jis-misc-1.0.3.tar.bz2
143c228286fe9c920ab60e47c1b60b67  font-micro-misc-1.0.3.tar.bz2
96109d0890ad2b6b0e948525ebb0aba8  font-misc-cyrillic-1.0.3.tar.bz2
6306c808f7d7e7d660dfb3859f9091d2  font-misc-ethiopic-1.0.3.tar.bz2
e3e7b0fda650adc7eb6964ff3c486b1c  font-misc-meltho-1.0.3.tar.bz2
c88eb44b3b903d79fb44b860a213e623  font-misc-misc-1.1.2.tar.bz2
56b0296e8862fc1df5cdbb4efe604e86  font-mutt-misc-1.0.3.tar.bz2
e805feb7c4f20e6bfb1118d19d972219  font-schumacher-misc-1.1.2.tar.bz2
6f3fdcf2454bf08128a651914b7948ca  font-screen-cyrillic-1.0.4.tar.bz2
beef61a9b0762aba8af7b736bb961f86  font-sony-misc-1.0.3.tar.bz2
948f2e07810b4f31195185921470f68d  font-sun-misc-1.0.3.tar.bz2
829a3159389b7f96f629e5388bfee67b  font-winitzki-cyrillic-1.0.3.tar.bz2
3eeb3fb44690b477d510bbd8f86cf5aa  font-xfree86-type1-1.0.4.tar.bz2
EOF

mkdir font &&
cd font &&
grep -v '^#' ../font-7.7.md5 | awk '{print $2}' | wget -i- -c \
    -B http://ftp.x.org/pub/individual/font/ &&
md5sum -c ../font-7.7.md5

as_root()
{
  if   [ $EUID = 0 ];        then $*
  elif [ -x /usr/bin/sudo ]; then sudo $*
  else                            su -c \\"$*\\"
  fi
}

export -f as_root

bash -e

for package in $(grep -v '^#' ../font-7.7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  ./configure $XORG_CONFIG
  make
  as_root make install
  popd
  as_root rm -rf $packagedir
done

exit

install -v -d -m755 /usr/share/fonts                               &&
ln -svfn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF &&
ln -svfn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF

cd /xc

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/data/xkeyboard-config/xkeyboard-config-2.15.tar.bz2
md5sum xkeyboard-config-2.15.tar.bz2 
4af1deeb7c5f4cad62e65957d98d6758  xkeyboard-config-2.15.tar.bz2
4af1deeb7c5f4cad62e65957d98d6758

tar -xf xkeyboard-config-2.15.tar.bz2 &&
cd xkeyboard-config-2.15 &&
./configure $XORG_CONFIG --with-xkb-rules-symlink=xorg &&
make

make install

cd /xc &&
rm -rf xkeyboard-config-2.15

--------------------------------------------------------------------------------------1

wget http://cairographics.org/releases/pixman-0.32.6.tar.gz
md5sum pixman-0.32.6.tar.gz 
3a30859719a41bd0f5cccffbfefdd4c2  pixman-0.32.6.tar.gz
3a30859719a41bd0f5cccffbfefdd4c2

tar -xf pixman-0.32.6.tar.gz &&
cd pixman-0.32.6 &&
./configure --prefix=/usr --disable-static &&
make

make install

cd /xc &&
rm -rf pixman-0.32.6

--------------------------------------------------------------------------------------2.1

wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.20.tar.bz2
md5sum libgpg-error-1.20.tar.bz2 
9997d9203b672402a04760176811589d  libgpg-error-1.20.tar.bz2
9997d9203b672402a04760176811589d

tar -xf libgpg-error-1.20.tar.bz2 &&
cd libgpg-error-1.20 &&
./configure --prefix=/usr --disable-static &&
make

make install &&
install -v -m644 -D README /usr/share/doc/libgpg-error-1.20/README

cd /xc &&
rm -rf libgpg-error-1.20

--------------------------------------------------------------------------------------2.2

wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.6.3.tar.bz2
md5sum libgcrypt-1.6.3.tar.bz2 
4262c3aadf837500756c2051a5c4ae5e  libgcrypt-1.6.3.tar.bz2
4262c3aadf837500756c2051a5c4ae5e

tar -xf libgcrypt-1.6.3.tar.bz2 &&
cd libgcrypt-1.6.3 &&
./configure --prefix=/usr &&
make

#make -j1 -C doc pdf ps html &&
#makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi &&
#makeinfo --plaintext       -o doc/gcrypt.txt           doc/gcrypt.texi
-------------------------------
#make: Entering directory '/xc/libgcrypt-1.6.3/doc'
#TEXINPUTS="../build-aux:$TEXINPUTS" \
#MAKEINFO='/bin/sh /xc/libgcrypt-1.6.3/build-aux/missing makeinfo   -I .' \
#texi2dvi --pdf --batch  --build-dir=gcrypt.t2p -o gcrypt.pdf  \
#gcrypt.texi
#You don't have a working TeX binary (tex) installed anywhere in
#your PATH, and texi2dvi cannot proceed without one.  If you want to use
#this script, you'll need to install TeX (if you don't have it) or change
#your PATH or TEX environment variable (if you do).  See the --help
#output for more details.

#For information about obtaining TeX, please see http://tug.org/texlive,
#or do a web search for TeX and your operating system or distro.
#Makefile:464: recipe for target 'gcrypt.pdf' failed
#make: *** [gcrypt.pdf] Error 1
#make: Leaving directory '/xc/libgcrypt-1.6.3/doc'
-----------------------------

make install &&
install -v -dm755   /usr/share/doc/libgcrypt-1.6.3 &&
install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
                    /usr/share/doc/libgcrypt-1.6.3

#install -v -dm755   /usr/share/doc/libgcrypt-1.6.3/html &&
#install -v -m644 doc/gcrypt.html/* \
#                    /usr/share/doc/libgcrypt-1.6.3/html &&
#install -v -m644 doc/gcrypt_nochunks.html \
#                    /usr/share/doc/libgcrypt-1.6.3 &&
#install -v -m644 doc/gcrypt.{pdf,ps,dvi,txt,texi} \
#                    /usr/share/doc/libgcrypt-1.6.3
---------------------------
#install: creating directory '/usr/share/doc/libgcrypt-1.6.3/html'
#install: cannot stat 'doc/gcrypt.html/*': No such file or directory
---------------------------

cd /xc &&
rm -rf libgcrypt-1.6.3

--------------------------------------------------------------------------------------3

wget https://github.com/anholt/libepoxy/releases/download/v1.3.1/libepoxy-1.3.1.tar.bz2
md5sum libepoxy-1.3.1.tar.bz2 
96f6620a9b005a503e7b44b0b528287d  libepoxy-1.3.1.tar.bz2
96f6620a9b005a503e7b44b0b528287d

tar -xf libepoxy-1.3.1.tar.bz2 &&
cd libepoxy-1.3.1 &&
./configure --prefix=/usr &&
make

make install

cd /xc &&
rm -rf libepoxy-1.3.1

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/xserver/xorg-server-1.17.2.tar.bz2
wget http://www.linuxfromscratch.org/patches/blfs/7.8/xorg-server-1.17.2-add_prime_support-1.patch
md5sum xorg-server-1.17.2.tar.bz2 
397e405566651150490ff493e463f1ad  xorg-server-1.17.2.tar.bz2
397e405566651150490ff493e463f1ad 

tar -xf xorg-server-1.17.2.tar.bz2 &&
cd xorg-server-1.17.2 &&
patch -Np1 -i ../xorg-server-1.17.2-add_prime_support-1.patch &&
./configure $XORG_CONFIG            \
           --enable-glamor          \
           --enable-install-setuid  \
           --enable-suid-wrapper    \
           --disable-systemd-logind \
           --with-xkb-output=/var/lib/xkb &&
make

make install

mkdir -pv /etc/X11/xorg.conf.d &&
cat >> /etc/sysconfig/createfiles << "EOF"
/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root
EOF

cd /xc &&
rm -rf xorg-server-1.17.2

--------------------------------------------------------------------------------------

#lspci

#wget https://ftp.kernel.org/pub/software/utils/pciutils/pciutils-3.4.0.tar.xz
wget  ftp://ftp.kernel.org/pub/software/utils/pciutils/pciutils-3.4.0.tar.xz
md5sum pciutils-3.4.0.tar.xz 
69c9edeb6761f2a822e4eb36187b75d6  pciutils-3.4.0.tar.xz
69c9edeb6761f2a822e4eb36187b75d6 

tar -xf pciutils-3.4.0.tar.xz &&
cd pciutils-3.4.0 &&
make PREFIX=/usr              \
     SHAREDIR=/usr/share/misc \
     SHARED=yes

make PREFIX=/usr              \
     SHAREDIR=/usr/share/misc \
     SHARED=yes               \
     install install-lib      &&
chmod -v 755 /usr/lib/libpci.so

cd /xc &&
rm -rf pciutils-3.4.0

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

logout

chroot "$LFS" /usr/bin/env -i              \
    HOME=/root TERM="$TERM"                \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin     \
    /bin/bash --login


MAKEFLAGS='-j 5'
cd /xc

tar -xf linux-4.2.tar.xz &&
cd linux-4.2

make mrproper

#make defconfig
cp -v /boot/config-4.2 .config

make LANG=POSIX LC_ALL= menuconfig

make

21:42---21:50

make modules_install

mkdir -v /boot/back
cp -v /boot/vmlinuz-4.2-lfs-7.8 /boot/back/
cp -v /boot/System.map-4.2 /boot/back/
cp -v /boot/config-4.2 /boot/back/
rm -v /boot/{vmlinuz-4.2-lfs-7.8,System.map-4.2,config-4.2}
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
  INSTALL crypto/echainiv.ko
  INSTALL drivers/hid/hid-generic.ko
  INSTALL drivers/hid/hid-ntrig.ko
  INSTALL drivers/hid/hid-sony.ko
  INSTALL drivers/hid/i2c-hid/i2c-hid.ko
  INSTALL drivers/hid/usbhid/usbhid.ko
  INSTALL drivers/hid/usbhid/usbkbd.ko
  INSTALL drivers/hid/usbhid/usbmouse.ko
  INSTALL drivers/thermal/x86_pkg_temp_thermal.ko
  INSTALL fs/efivarfs/efivarfs.ko
  INSTALL net/ipv4/netfilter/ipt_MASQUERADE.ko
  INSTALL net/ipv4/netfilter/iptable_nat.ko
  INSTALL net/ipv4/netfilter/nf_log_arp.ko
  INSTALL net/ipv4/netfilter/nf_log_ipv4.ko
  INSTALL net/ipv4/netfilter/nf_nat_ipv4.ko
  INSTALL net/ipv4/netfilter/nf_nat_masquerade_ipv4.ko
  INSTALL net/ipv6/netfilter/nf_log_ipv6.ko
  INSTALL net/netfilter/nf_log_common.ko
  INSTALL net/netfilter/nf_nat.ko
  INSTALL net/netfilter/nf_nat_ftp.ko
  INSTALL net/netfilter/nf_nat_irc.ko
  INSTALL net/netfilter/nf_nat_sip.ko
  INSTALL net/netfilter/xt_LOG.ko
  INSTALL net/netfilter/xt_addrtype.ko
  INSTALL net/netfilter/xt_mark.ko
  INSTALL net/netfilter/xt_nat.ko
  DEPMOD  4.2.0

mkdir -v ~/rapoo
cd ~/rapoo
#wget rapoo.tar.gz
tar -xf rapoo.tar.gz
make
make install
./installdriver.sh
#cp -v hid-rapoo.ko /lib/modules/4.2.0/kernel/drivers/hid/
#cp -v hid-rapoo.ko /lib64/modules/4.2.0/kernel/drivers/hid/

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

export XORG_PREFIX="/usr" &&
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc \
    --localstatedir=/var --disable-static" &&
cd /xc

#Device Drivers  --->
#  Input device support --->
#    <*> Generic input layer (needed for...) [CONFIG_INPUT]
#    <*>   Event interface                   [CONFIG_INPUT_EVDEV]
#    [*]   Miscellaneous devices  --->       [CONFIG_INPUT_MISC]
#      <*>    User level driver support      [CONFIG_INPUT_UINPUT]

wget http://www.freedesktop.org/software/libevdev/libevdev-1.4.4.tar.xz
md5sum libevdev-1.4.4.tar.xz 
b66443bb664cfaf2ba7b3f8c238ea951  libevdev-1.4.4.tar.xz
b66443bb664cfaf2ba7b3f8c238ea951

tar -xf libevdev-1.4.4.tar.xz &&
cd libevdev-1.4.4 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf libevdev-1.4.4

--------------------------------------------------------------------------------------1

wget http://bitmath.org/code/mtdev/mtdev-1.1.5.tar.bz2
md5sum mtdev-1.1.5.tar.bz2 
52c9610b6002f71d1642dc1a1cca5ec1  mtdev-1.1.5.tar.bz2
52c9610b6002f71d1642dc1a1cca5ec1

tar -xf mtdev-1.1.5.tar.bz2 &&
cd mtdev-1.1.5 &&
./configure --prefix=/usr --disable-static &&
make

make install

cd /xc &&
rm -rf mtdev-1.1.5

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/driver/xf86-input-evdev-2.9.2.tar.bz2
md5sum xf86-input-evdev-2.9.2.tar.bz2 
99eebf171e6c7bffc42d4fc430d47454  xf86-input-evdev-2.9.2.tar.bz2
99eebf171e6c7bffc42d4fc430d47454

tar -xf xf86-input-evdev-2.9.2.tar.bz2 &&
cd xf86-input-evdev-2.9.2 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xf86-input-evdev-2.9.2

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/driver/xf86-input-synaptics-1.8.2.tar.bz2
md5sum xf86-input-synaptics-1.8.2.tar.bz2 
8ed68e8cc674dd61adb280704764aafb  xf86-input-synaptics-1.8.2.tar.bz2
8ed68e8cc674dd61adb280704764aafb 

tar -xf xf86-input-synaptics-1.8.2.tar.bz2 &&
cd xf86-input-synaptics-1.8.2 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xf86-input-synaptics-1.8.2

--------------------------------------------------------------------------------------

#Processor type and features --->
#  [*] Symmetric multi-processing support          [CONFIG_SMP]
#  [*] Support for extended (non-PC) x86 platforms [CONFIG_X86_EXTENDED_PLATFORM]
#  [*] ScaleMP vSMP                                [CONFIG_X86_VSMP]
#Device Drivers --->
#  Input device support --->
#    [*] Mice --->                                 [CONFIG_INPUT_MOUSE]
#      <*/M> PS/2 mouse                            [CONFIG_MOUSE_PS2]
#      [*] Virtual mouse (vmmouse)                 [CONFIG_MOUSE_PS2_VMMOUSE]


wget http://ftp.x.org/pub/individual/driver/xf86-input-vmmouse-13.1.0.tar.bz2
md5sum xf86-input-vmmouse-13.1.0.tar.bz2 
85e2e464b7219c495ad3a16465c226ed  xf86-input-vmmouse-13.1.0.tar.bz2
85e2e464b7219c495ad3a16465c226ed

tar -xf xf86-input-vmmouse-13.1.0.tar.bz2 &&
cd xf86-input-vmmouse-13.1.0 &&
./configure $XORG_CONFIG               \
            --without-hal-fdi-dir      \
            --without-hal-callouts-dir \
            --with-udev-rules-dir=/lib/udev/rules.d &&
make

make install

cd /xc &&
rm -rf xf86-input-vmmouse-13.1.0

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/driver/xf86-video-fbdev-0.4.4.tar.bz2
md5sum xf86-video-fbdev-0.4.4.tar.bz2 
3931c0e19d441cc576dc088f9eb9fd73  xf86-video-fbdev-0.4.4.tar.bz2
3931c0e19d441cc576dc088f9eb9fd73

tar -xf xf86-video-fbdev-0.4.4.tar.bz2 &&
cd xf86-video-fbdev-0.4.4 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xf86-video-fbdev-0.4.4


--------------------------------------------------------------------------------------

#Device Drivers  --->
#  Graphics support --->
#    Direct rendering Manager --->
#      <*> Direct Rendering Manager (XFree86 ... support) ---> [CONFIG_DRM]
#      <*> Intel I810                                          [CONFIG_DRM_I810]
#      <*> Intel 8xx/9xx/G3x/G4x/HD Graphics                   [CONFIG_DRM_I915]
#      [*]   Enable modesetting on intel by default            [CONFIG_DRM_I915_KMS]

wget http://ftp.x.org/pub/individual/driver/xf86-video-intel-2.99.917.tar.bz2
md5sum xf86-video-intel-2.99.917.tar.bz2 
fa196a66e52c0c624fe5d350af7a5e7b  xf86-video-intel-2.99.917.tar.bz2
fa196a66e52c0c624fe5d350af7a5e7b

tar -xf xf86-video-intel-2.99.917.tar.bz2 &&
cd xf86-video-intel-2.99.917 &&
./configure $XORG_CONFIG --enable-kms-only --enable-uxa &&
make

make install

cd /xc &&
rm -rf xf86-video-intel-2.99.917

cat >> /etc/X11/xorg.conf.d/20-intel.conf << "EOF"
Section "Device"
        Identifier "Intel Graphics"
        Driver "intel"
        Option "AccelMethod" "uxa"
EndSection
EOF

--------------------------------------------------------------------------------------

#Device Drivers  --->
#  Graphics support  --->
#    Direct Rendering Manager  --->
#      <*> Direct Rendering Manager (XFree86 ... support) --->  [CONFIG_DRM]
#      <*> DRM driver for VMware Virtual GPU                    [CONFIG_DRM_VMWGFX]
#      [*]   Enable framebuffer console under vmwgfx by default [CONFIG_DRM_VMWGFX_FBCON]

wget http://ftp.x.org/pub/individual/driver/xf86-video-vmware-13.1.0.tar.bz2
md5sum xf86-video-vmware-13.1.0.tar.bz2 
0cba22fed4cb639d5c4276f7892c543d  xf86-video-vmware-13.1.0.tar.bz2
0cba22fed4cb639d5c4276f7892c543d

tar -xf xf86-video-vmware-13.1.0.tar.bz2 &&
cd xf86-video-vmware-13.1.0 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xf86-video-vmware-13.1.0

--------------------------------------------------------------------------------------

wget http://www.freedesktop.org/software/vaapi/releases/libva/libva-1.6.0.tar.bz2
md5sum libva-1.6.0.tar.bz2 
3f1241b4080db53c120325932f393f33  libva-1.6.0.tar.bz2
3f1241b4080db53c120325932f393f33 

tar -xf libva-1.6.0.tar.bz2 &&
cd libva-1.6.0 &&
mkdir -p m4 &&
autoreconf -fi           &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf libva-1.6.0

wget http://www.freedesktop.org/software/vaapi/releases/libva-intel-driver/libva-intel-driver-1.6.0.tar.bz2
md5sum libva-intel-driver-1.6.0.tar.bz2 
d7678f7c66cbb135cced82ee2af6d8e8  libva-intel-driver-1.6.0.tar.bz2
d7678f7c66cbb135cced82ee2af6d8e8

tar -xf libva-intel-driver-1.6.0.tar.bz2 &&
cd libva-intel-driver-1.6.0 &&
mkdir -p m4              &&
autoreconf -fi           &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf libva-intel-driver-1.6.0

--------------------------------------------------------------------------------------

wget http://people.freedesktop.org/~aplattner/vdpau/libvdpau-1.1.1.tar.bz2
md5sum libvdpau-1.1.1.tar.bz2 
2fa0b05a4f4d06791eec83bc9c854d14  libvdpau-1.1.1.tar.bz2
2fa0b05a4f4d06791eec83bc9c854d14 

tar -xf libvdpau-1.1.1.tar.bz2 &&
cd libvdpau-1.1.1 &&
./configure $XORG_CONFIG \
            --docdir=/usr/share/doc/libvdpau-1.1.1 &&
make

make install

cd /xc &&
rm -rf libvdpau-1.1.1

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/app/twm-1.0.9.tar.bz2

59a6f076cdacb5f6945dac809bcf4906

tar -xf twm-1.0.9.tar.bz2 &&
cd twm-1.0.9 &&
sed -i -e '/^rcdir =/s,^\(rcdir = \).*,\1/etc/X11/app-defaults,' src/Makefile.in &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf twm-1.0.9

--------------------------------------------------------------------------------------

wget ftp://invisible-island.net/xterm/xterm-320.tgz
md5sum xterm-320.tgz 
0d7f0e6390d132ae59876b3870e5783d  xterm-320.tgz
0d7f0e6390d132ae59876b3870e5783d

tar -xf xterm-320.tgz &&
cd xterm-320 &&
sed -i '/v0/{n;s/new:/new:kb=^?:/}' termcap &&
printf '\tkbs=\\177,\n' >> terminfo &&
TERMINFO=/usr/share/terminfo \
./configure $XORG_CONFIG     \
    --with-app-defaults=/etc/X11/app-defaults &&
make

make install &&
make install-ti

cd /xc &&
rm -rf xterm-320

cat >> /etc/X11/app-defaults/XTerm << "EOF"
*VT100*locale: true
*VT100*faceName: Monospace
*VT100*faceSize: 10
*backarrowKeyIsErase: true
*ptyInitialErase: true

!muse selecting to copy, ctrl-v to paste
XTerm*VT100.Translations: #override \
    Ctrl <KeyPress> V: insert-selection(CLIPBOARD,PRIMARY,CUT_BUFFER0) \n\
    <BtnUp>: select-end(CLIPBOARD,PRIMARY,CUT_BUFFER0) \n\
    <Btn2Down> : insert-selection(CLIPBOARD,PRIMARY,CUT_BUFFER0) \n
EOF
#!Ctrl p to print screen content to file
#    Ctrl <KeyPress> P: print() \n
#!Ctrl c copy
#    Ctrl <KeyPress> C: select-end(CLIPBOARD,PRIMARY,CUT_BUFFER0) \n\

--------------------------------------------------------------------------------------
6f150d063b20d08030b98c45b9bee7af  xclock-1.0.7.tar.bz2
6f150d063b20d08030b98c45b9bee7af 

tar -xf xclock-1.0.7.tar.bz2 &&
cd xclock-1.0.7 &&
./configure $XORG_CONFIG &&
make

make install

cd /xc &&
rm -rf xclock-1.0.7

--------------------------------------------------------------------------------------

wget http://ftp.x.org/pub/individual/app/xinit-1.3.4.tar.bz2
md5sum xinit-1.3.4.tar.bz2 
4e928452dfaf73851413a2d8b8c76388  xinit-1.3.4.tar.bz2
4e928452dfaf73851413a2d8b8c76388

tar -xf xinit-1.3.4.tar.bz2 &&
cd xinit-1.3.4

sed -e '/$serverargs $vtarg/ s/serverargs/: #&/' \
    -i startx.cpp

./configure $XORG_CONFIG \
            --with-xinitdir=/etc/X11/app-defaults &&
make

make install &&
ldconfig

cd /xc &&
rm -rf xinit-1.3.4

--------------------------------------------------------------------------------------1

#Device Drivers --->
#  [*] USB support --->                   [CONFIG_USB_SUPPORT]
#    <*/M> Support for Host-side USB      [CONFIG_USB]
#    (Select any USB hardware device drivers you may need on the same page)

wget http://downloads.sourceforge.net/libusb/libusb-1.0.19.tar.bz2
md5sum libusb-1.0.19.tar.bz2 
f9e2bb5879968467e5ca756cb4e1fa7e  libusb-1.0.19.tar.bz2
f9e2bb5879968467e5ca756cb4e1fa7e

tar -xf libusb-1.0.19.tar.bz2 &&
cd libusb-1.0.19 &&
./configure --prefix=/usr --disable-static &&
make

#make -C doc docs

make install

install -v -d -m755 /usr/share/doc/libusb-1.0.19/apidocs &&
#install -v -m644    doc/html/* \
#                    /usr/share/doc/libusb-1.0.19/apidocs

cd /xc &&
rm -rf libusb-1.0.19

--------------------------------------------------------------------------------------2

wget http://ftp.kernel.org/pub/linux/utils/usb/usbutils/usbutils-008.tar.xz
md5sum usbutils-008.tar.xz 
2780b6ae21264c888f8f30fb2aab1259  usbutils-008.tar.xz
2780b6ae21264c888f8f30fb2aab1259

tar -xf usbutils-008.tar.xz &&
cd usbutils-008 &&
sed -i '/^usbids/ s:usb.ids:hwdata/&:' lsusb.py &&
./configure --prefix=/usr --datadir=/usr/share/hwdata &&
make

make install

cd /xc &&
rm -rf usbutils-008

--------------------------------------------------------------------------------------








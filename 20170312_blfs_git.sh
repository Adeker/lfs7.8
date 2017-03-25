
wget http://curl.haxx.se/download/curl-7.44.0.tar.lzma
md5sum curl-7.44.0.tar.lzma

2f924c80bb7124dff1b39f54ffda3781

tar -xf curl-7.44.0.tar.lzma &&
cd curl-7.44.0 &&
./configure --prefix=/usr              \
            --disable-static           \
            --enable-threaded-resolver &&
make

make install &&
find docs \( -name Makefile\* \
          -o -name \*.1       \
          -o -name \*.3 \)    \
          -exec rm {} \;      &&
install -v -d -m755 /usr/share/doc/curl-7.44.0 &&
cp -v -R docs/*     /usr/share/doc/curl-7.44.0

cd /xc/git &&
rm -rf curl-7.44.0

======================================================================================

mkdir -pv /xc/git
cd /xc/git

wget https://openssl.org/source/openssl-1.0.2d.tar.gz
md5sum openssl-1.0.2d.tar.gz
38dd619b2e77cbac69b99f52a053d25a  openssl-1.0.2d.tar.gz
38dd619b2e77cbac69b99f52a053d25a

tar -xf openssl-1.0.2d.tar.gz &&
cd openssl-1.0.2d &&
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic &&
make

make MANDIR=/usr/share/man MANSUFFIX=ssl install &&
install -dv -m755 /usr/share/doc/openssl-1.0.2d  &&
cp -vfr doc/*     /usr/share/doc/openssl-1.0.2d

cd /xc/git &&
rm -rf openssl-1.0.2d

======================================================================================

wget http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.1p1.tar.gz
md5sum openssh-7.1p1.tar.gz
8709736bc8a8c253bc4eeb4829888ca5  openssh-7.1p1.tar.gz
8709736bc8a8c253bc4eeb4829888ca5

nstall  -v -m700 -d /var/lib/sshd &&
chown    -v root:sys /var/lib/sshd &&
groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd

tar -xf openssh-7.1p1.tar.gz &&
cd openssh-7.1p1 &&
./configure --prefix=/usr                     \
            --sysconfdir=/etc/ssh             \
            --with-md5-passwords              \
            --with-privsep-path=/var/lib/sshd &&
make

make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&
install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-7.1p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-7.1p1

cd /xc/git &&
rm -rf openssh-7.1p1

#To start the SSH server at system boot, 
#install the /etc/rc.d/init.d/sshd init script included in the blfs-bootscripts-20150924 package. 
#make install-sshd

======================================================================================

wget https://www.kernel.org/pub/software/scm/git/git-2.5.0.tar.xz
md5sum git-2.5.0.tar.xz
f108b475a0aa30e9587be4295ab0bb09  git-2.5.0.tar.xz
f108b475a0aa30e9587be4295ab0bb09

wget https://www.kernel.org/pub/software/scm/git/git-manpages-2.5.0.tar.xz
wget https://www.kernel.org/pub/software/scm/git/git-htmldocs-2.5.0.tar.xz

tar -xf git-2.5.0.tar.xz &&
cd git-2.5.0 &&
./configure --prefix=/usr --with-gitconfig=/etc/gitconfig &&
make

#make html
#make man

make install

#make install-man

tar -xf ../git-manpages-2.5.0.tar.xz \
    -C /usr/share/man --no-same-owner --no-overwrite-dir

mkdir -vp   /usr/share/doc/git-2.5.0 &&
tar   -xf   ../git-htmldocs-2.5.0.tar.xz \
      -C    /usr/share/doc/git-2.5.0 --no-same-owner --no-overwrite-dir &&
find        /usr/share/doc/git-2.5.0 -type d -exec chmod 755 {} \; &&
find        /usr/share/doc/git-2.5.0 -type f -exec chmod 644 {} \;

mkdir -vp /usr/share/doc/git-2.5.0/man-pages/{html,text}         &&
mv        /usr/share/doc/git-2.5.0/{git*.txt,man-pages/text}     &&
mv        /usr/share/doc/git-2.5.0/{git*.,index.,man-pages/}html &&
mkdir -vp /usr/share/doc/git-2.5.0/technical/{html,text}         &&
mv        /usr/share/doc/git-2.5.0/technical/{*.txt,text}        &&
mv        /usr/share/doc/git-2.5.0/technical/{*.,}html           &&
mkdir -vp /usr/share/doc/git-2.5.0/howto/{html,text}             &&
mv        /usr/share/doc/git-2.5.0/howto/{*.txt,text}            &&
mv        /usr/share/doc/git-2.5.0/howto/{*.,}html

cd /xc/git &&
rm -rf git-2.5.0

#!/bin/bash
set -e
set +h
wget https://nchc.dl.sourceforge.net/project/wqy/wqy-zenhei/0.9.45%20%28Fighting-state%20RC1%29/wqy-zenhei-0.9.45.tar.gz
tar -xf wqy-zenhei-0.9.45.tar.gz
cd wqy-zenhei
mkdir -pv /usr/share/fonts/wenquanyi/wqy-zenhei
cp -v wqy-zenhei.ttc /usr/share/fonts/wenquanyi/wqy-zenhei
cd /usr/share/fonts/wenquanyi/wqy-zenhei
mkfontscale
mkfontdir
fc-cache -fv

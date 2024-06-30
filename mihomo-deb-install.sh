#!/bin/bash

## bash <(curl -fsSL https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/mihomo-deb-install.sh)

set -e -o pipefail

ARCH_RAW=$(uname -m)
case "${ARCH_RAW}" in
    'x86_64')    ARCH='amd64';;
    'x86' | 'i686' | 'i386')     ARCH='386';;
    'aarch64' | 'arm64') ARCH='arm64';;
    'armv7l')   ARCH='armv7';;
    's390x')    ARCH='s390x';;
    *)          echo "Unsupported architecture: ${ARCH_RAW}"; exit 1;;
esac
echo  "当前设备架构${ARCH_RAW}"

VERSION=$(curl -L "https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt")

echo  "获取到的版本:${VERSION}"

curl -Lo mihomo.deb "https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-${ARCH}-${VERSION}.deb"
echo "${VERSION}下载完成,开始安装"

sudo dpkg -i mihomo.deb

echo "安装完成,清理安装包"

rm mihomo.deb

systemctl daemon-reload
systemctl restart mihomo
echo "重启服务完成"

#!/bin/bash
#
###
##### 一键安装 wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/install-passwall.sh | sh -s -- -v

set -e -o pipefail

echo "换源"
sed -i 's/downloads.openwrt.org/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' /etc/opkg/distfeeds.conf
opkg update
opkg install unzip curl nano kmod-nft-socket 
#

echo "获取信息"
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

VERSION=$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall/releases?per_page=1&page=0" \
    | grep tag_name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//')

echo  "获取到的版本:${VERSION}"


VE2=$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall/releases?per_page=1&page=0" |grep luci-23.05_luci-app-passwall \
    | grep name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//')

echo  "获取到的VE2:${VE2}"


ZHIPK=$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall/releases?per_page=1&page=0" | grep luci-i18n-passwall-zh-cn_git- \
    | grep name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//')


mkdir pass && cd pass
echo "下载"

wget https://github.com/xiaorouji/openwrt-passwall/releases/download/${VERSION}/passwall_packages_ipk_${ARCH_RAW}_generic.zip -O passwall_packages_ipk_${ARCH_RAW}_generic.zip

wget https://github.com/xiaorouji/openwrt-passwall/releases/download/${VERSION}/${VE2} -O ${VE2}

wget  https://github.com/xiaorouji/openwrt-passwall/releases/download/${VERSION}/${ZHIPK} -O ${ZHIPK}

echo "解压缩"
unzip passwall_packages_ipk_aarch64_generic.zip

echo "安装"

opkg install *.ipk
opkg haproxy haproxy-nossl
echo "清理安装包"
cd .. && rm -r pass
echo "清理完成"
#
echo "结束，准备重启openwrt"
reboot

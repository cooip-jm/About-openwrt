#!/bin/bash
#
###
##### 一键安装 wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/install-passwall.sh | sh -s -- -v

echo "仅限Arm系统"

echo "换源"
sed -i 's/downloads.openwrt.org/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' /etc/opkg/distfeeds.conf
opkg update
opkg install unzip curl nano kmod-nft-socket 
#
mkdir pass && cd pass
echo "下载"
wget https://github.com/xiaorouji/openwrt-passwall/releases/download/4.77-5/passwall_packages_ipk_aarch64_generic.zip -O passwall_packages_ipk_aarch64_generic.zip

wget https://github.com/xiaorouji/openwrt-passwall/releases/download/4.77-5/luci-23.05_luci-app-passwall_4.77-5_all.ipk -O luci-23.05_luci-app-passwall_4.77-5_all.ipk


wget  https://github.com/xiaorouji/openwrt-passwall/releases/download/4.77-5/luci-23.05_luci-i18n-passwall-zh-cn_git-24.119.58706-854231b_all.ipk -O luci-23.05_luci-i18n-passwall-zh-cn_git-24.119.58706-854231b_all.ipk

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

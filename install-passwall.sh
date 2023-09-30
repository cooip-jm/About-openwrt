#!/bin/bash
#
###
echo "仅限Arm系统"

echo "换源"
sed -i 's/downloads.openwrt.org/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' /etc/opkg/distfeeds.conf
opkg update
#
echo "下载"
wget https://github.com/xiaorouji/openwrt-passwall/releases/download/4.70-10/passwall_packages_ipk_aarch64_generic.zip -O passwall_packages_ipk_aarch64_generic.zip

wget https://github.com/xiaorouji/openwrt-passwall/releases/download/4.70-10/luci-app-passwall_4.70-10_all.ipk -O luci-app-passwall_4.70-10_all.ipk


wget https://github.com/xiaorouji/openwrt-passwall/releases/download/4.70-10/luci-i18n-passwall-zh-cn_git-23.263.27645-0fab584_all.ipk -O luci-i18n-passwall-zh-cn_git-23.263.27645-0fab584_all.ipk

echo "解压缩"
unzip passwall_packages_ipk_aarch64_generic.zip

echo "安装"

opkg install *.ipk

#
echo "结束，准备重启openwrt"
reboot

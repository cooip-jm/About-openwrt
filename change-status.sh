#!/bin/bash
#
###
echo "openwrt lede换首页状态,来自@Z-ane-E(Demons)"

echo "换源"
sed -i 's/downloads.openwrt.org/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' /etc/opkg/distfeeds.conf
opkg update
#
echo "安装依赖"


opkg install perl-http-date

opkg install perlbase-file


wget https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/index.htm -O index.htm



echo "备份"
mv /usr/lib/lua/luci/view/admin_status/index.htm /usr/lib/lua/luci/view/admin_status/back-index.htm
echo "安装"
cp index.htm /usr/lib/lua/luci/view/admin_status/index.htm

#
echo "结束，准备重启openwrt，完成后ctrl+F5刷新下网页"
reboot

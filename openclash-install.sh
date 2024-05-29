#!/bin/bash
#官方openwrt安装Openclash、中文、和设置时区脚本。
#或者打自己单行复制粘贴执行。
### wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/openclash-install.sh | sh -s -- -v
#不限制系统架构，Openclash 版本更新自行替换脚本内下载地址
echo "换源"
sed -i 's/downloads.openwrt.org/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' /etc/opkg/distfeeds.conf
#
echo "安装openclash依赖"
#mv /etc/config/dhcp /etc/config/dhcp.bak
opkg remove dnsmasq
opkg update
opkg install luci-i18n-base-zh-cn coreutils-nohup bash dnsmasq-full curl ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base
#
echo "下载openclash"
wget https://github.com/vernesong/OpenClash/releases/download/v0.46.011-beta/luci-app-openclash_0.46.011-beta_all.ipk -O luci-app-openclash_0.46.011-beta_all.ipk

opkg install luci-app-openclash_0.46.001-beta_all.ipk

#
echo "openclash安装完成，更新时区"
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system

#
echo "结束，准备重启openwrt"
reboot

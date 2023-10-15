#!/bin/bash
#基础环境
#官方openwrt安装中文、和设置时区和一些基础环境的，脚本。
##运行
### wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/bash.sh | sh -s -- -v
### 

#或者打自己单行复制粘贴执行。
#不限制系统架构

#
echo "配置时区"
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system

echo "换源"
sed -i 's/downloads.openwrt.org/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' /etc/opkg/distfeeds.conf
opkg update
#
echo "安装中文以及一些基础工具"
opkg remove dnsmasq
opkg install luci-i18n-base-zh-cn  bash dnsmasq-full curl ca-certificates  unzip nano iperf3
#
echo "基础环境安装完成"

#
echo "结束，准备重启openwrt"
reboot

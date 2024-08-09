#!/bin/bash
#基础环境
#Alpine设置时区和一些基础环境的，脚本。
##运行
###  apk add wget
### wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/alpine-bash.sh | sh -s -- -v
### 

#或者打自己单行复制粘贴执行。
#不限制系统架构
echo "换国内源"
sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
apk update
echo "修正时区/安装curl nano"
apk add tzdata  curl  nano
date
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" > /etc/timezone
date
echo "完成"

#!/bin/bash
#### 仅限debian/ubuntu LXC/VM/物理机使用，架构不限
#### 自用脚本 
if [[ $(curl -s http://sub-store-singbox订阅地址) ]]; then
    curl http://http://sub-store-singbox订阅地址  > /etc/sing-box/config.json
    systemctl restart sing-box
fi
VERSION=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases?per_page=1&page=0" \
    | grep tag_name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//')
Ver2=$(sing-box version | grep version | cut -d " " -f3)
echo  "当前运行版本:${Ver2}"
echo  "Github仓库最新版本:${VERSION}"
if [ "$Ver2" != "$VERSION" ]; then
echo "发现新版本，开始更新"
    git -C /var/lib/sing-box/ui pull -r
    bash <(curl -fsSL https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/sing-box-deb-install.sh)
fi

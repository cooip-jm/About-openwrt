### archlinux rootfs local、添加国内源一键脚本

### wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/update_arch.sh | sh -s -- -v



#!/bin/bash
echo "换源"
# 添加 mirror 到 mirrorlist 文件
sed -i '1s/^/Server = https:\/\/mirrors.bfsu.edu.cn\/archlinuxarm\/$arch\/$repo\n/' /etc/pacman.d/mirrorlist

# 执行 pacman -Syy
pacman -Syy
echo "修复local提示"

# 去掉/etc/locale.gen中的#en_US.UTF-8 UTF-8行首的 # 注释符
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

# 重新生成locale
sudo locale-gen

# 设置locale为en_US.UTF-8
sudo localectl set-locale LANG=en_US.UTF-8

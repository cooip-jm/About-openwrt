#!/bin/bash

# Fedora LXC 桌面环境配置脚本
# 条件有限，未测试BSP linux kernel
# 目前仅测试了RK3588 Rock5B,但也默认支持X86设备
# 适用于 Arm 设备，支持 MATE、XFCE、LXQt、LXDE、KDE、GNOME、MATE+Compiz、Cinnamon
# rootfs 建议下载地址https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/

### 自动脚本
### dnf install -y wget
### wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/fedora-desktop-plan-B.sh | sh -s -- -v


# 宿主系统推荐挂载
# mp0: /mnt/ssd/smb,mp=/share
# lxc.cgroup2.devices.allow: c 226:* rwm
# lxc.mount.entry: /dev/dri dev/dri none bind,create=dir
# lxc.cgroup2.devices.allow: c 250:* rwm
# lxc.mount.entry: /dev/dma_heap dev/dma_heap none bind,create=dir


echo "=== Fedora LXC 桌面环境配置脚本 ==="

# 0. 交互选择镜像源
echo "请选择镜像源（适用于中国用户加速下载）："
echo "1. mirrors.tuna.tsinghua.edu.cn (清华大学)"
echo "2. mirrors.cernet.edu.cn (教育网)"
echo "3. 不修改（使用默认源）"
read -p "请输入选择 (1/2/3): " mirror_choice

case $mirror_choice in
    1)
        mirror_url="https://mirrors.tuna.tsinghua.edu.cn/fedora"
        ;;
    2)
        mirror_url="https://mirrors.cernet.edu.cn/fedora"
        ;;
    3)
        mirror_url=""
        ;;
    *)
        echo "无效选择，使用默认源"
        mirror_url=""
        ;;
esac

if [ -n "$mirror_url" ]; then
    echo "正在配置国内镜像源: $mirror_url ..."
    sed -e 's|^metalink=|#metalink=|g' \
        -e "s|^#baseurl=http://download.example/pub/fedora/linux|baseurl=$mirror_url|g" \
        -i.bak \
        /etc/yum.repos.d/fedora.repo \
        /etc/yum.repos.d/fedora-updates.repo
fi

dnf makecache

# 1. 确保 D-Bus 系统服务运行
echo "检查并启用 D-Bus 系统服务..."
dnf install -y dbus-daemon
if ! systemctl is-active --quiet dbus; then
    systemctl enable --now dbus || {
        echo "警告: 无法启动 D-Bus 系统服务，可能因 LXC 限制。请在宿主系统检查 /run/dbus 挂载。"
    }
fi
if [ -S /run/dbus/system_bus_socket ]; then
    echo "D-Bus 系统总线正常运行"
else
    echo "警告: D-Bus 套接字 /run/dbus/system_bus_socket 不可用，可能影响 timedatectl 或桌面环境。"
fi

# 2. 更新系统（排除内核更新）
echo "正在更新系统（排除内核）..."
dnf update -y --exclude=kernel* || {
    echo "警告: 系统更新失败，继续执行后续步骤..."
}

# 3. 安装基础工具
echo "正在安装基础工具..."
dnf install -y --skip-broken nano btop fastfetch curl sudo bash openssl timedatectl dbus-x11 xorg-x11-xauth || {
    echo "警告: 部分基础工具安装失败，继续执行..."
}

# 4. 安装GPU驱动程序 (RK3588 Mali GPU支持，包括Panthor开源驱动的用户空间部分)
echo "正在安装GPU驱动程序..."
dnf install -y --skip-broken mesa-dri-drivers mesa-va-drivers mesa-vulkan-drivers || {
    echo "警告: 部分GPU驱动安装失败，可能需在宿主系统配置GPU设备权限"
}

# 5. 创建cooip用户并添加到wheel组
echo "正在创建用户账户..."
if ! id "cooip" &>/dev/null; then
    useradd -m -G wheel,video -s /bin/bash -c "Desktop User" cooip
    echo "cooip:password" | chpasswd  # 请安装后及时更改密码
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.d/wheel
    chmod 0440 /etc/sudoers.d/wheel
else
    echo "用户cooip已存在，跳过创建"
fi

# 将用户添加到必要的组
usermod -a -G video cooip
usermod -a -G input cooip

# 6. 交互选择桌面环境
echo "请选择桌面环境："
echo "1. MATE"
echo "2. XFCE"
echo "3. LXQt"
echo "4. LXDE"
echo "5. KDE"
echo "6. GNOME"
echo "7. MATE+Compiz"
echo "8. Cinnamon"
read -p "请输入选择 (1-8): " desktop_choice

case $desktop_choice in
    1)
        desktop_group="@mate-desktop"
        session_cmd="mate-session"
        xrdp_session="mate-session"
        dm="lightdm"
        force_x11=false
        ;;
    2)
        desktop_group="@xfce-desktop xfce4-panel xfdesktop"
        session_cmd="xfce4-session"
        xrdp_session="xfce4-session"
        dm="lightdm"
        force_x11=false
        ;;
    3)
        desktop_group="@lxqt-desktop"
        session_cmd="startlxqt"
        xrdp_session="startlxqt"
        dm="sddm"
        force_x11=false
        ;;
    4)
        desktop_group="@lxde-desktop lxsession openbox-lxde"
        session_cmd="startlxde"
        xrdp_session="startlxde"
        dm="lightdm"
        force_x11=false
        ;;
    5)
        desktop_group="@kde-desktop plasma-workspace-x11"
        session_cmd="startplasma-x11"
        xrdp_session="startplasma-x11"
        dm="sddm"
        force_x11=true
        ;;
    6)
        desktop_group="@gnome-desktop gnome-session metacity"
        session_cmd="gnome-session --session=gnome-xorg"
        xrdp_session="gnome-session"
        dm="gdm"
        force_x11=true
        ;;
    7)
        desktop_group="@mate-desktop compiz compiz-plugins-main ccsm"
        session_cmd="mate-session"
        xrdp_session="mate-session"
        dm="lightdm"
        force_x11=false
        ;;
    8)
        desktop_group="@cinnamon-desktop"
        session_cmd="cinnamon-session"
        xrdp_session="cinnamon-session"
        dm="gdm"
        force_x11=true
        ;;
    *)
        echo "无效选择，使用默认MATE"
        desktop_group="@mate-desktop"
        session_cmd="mate-session"
        xrdp_session="mate-session"
        dm="lightdm"
        force_x11=false
        ;;
esac

echo "正在安装选择的桌面环境: $desktop_group ..."
dnf install -y --skip-broken $desktop_group || {
    echo "警告: 部分桌面环境包不可用，已跳过。继续配置..."
}

# 安装 openbox 和 xterm 作为 VNC 回退
echo "安装 VNC 回退工具 (openbox 和 xterm)..."
dnf install -y --skip-broken openbox xterm || {
    echo "警告: openbox 或 xterm 安装失败，可能影响 VNC 回退机制"
}

# 额外的桌面环境特定配置
if [ "$desktop_choice" = "7" ]; then
    echo "正在配置MATE+Compiz..."
    sudo -u cooip bash -c "mkdir -p ~/.config/compiz/compizconfig"
    if command -v ccsm >/dev/null 2>&1; then
        sudo -u cooip bash -c "ccsm --replace &> /dev/null || true"
    else
        echo "警告: ccsm 未安装，请手动运行 'ccsm' 配置Compiz效果"
    fi
    sudo -u cooip bash -c "gsettings set org.mate.session.required-components windowmanager compiz"
fi

# 强制X11如果需要（针对Wayland桌面）
if [ "$force_x11" = true ]; then
    echo "配置显示管理器为X11..."
    if [ "$dm" = "gdm" ]; then
        mkdir -p /etc/gdm
        if [ ! -f /etc/gdm/custom.conf ]; then
            echo "[daemon]" > /etc/gdm/custom.conf
        fi
        sed -i '/^#WaylandEnable=false/s/^#//' /etc/gdm/custom.conf
        if ! grep -q "WaylandEnable=false" /etc/gdm/custom.conf; then
            echo "WaylandEnable=false" >> /etc/gdm/custom.conf
        fi
    elif [ "$dm" = "sddm" ]; then
        mkdir -p /etc/sddm.conf.d
        echo "[General]" > /etc/sddm.conf.d/x11.conf
        echo "DisplayServer=x11" >> /etc/sddm.conf.d/x11.conf
    fi
fi

# 7. 安装中文字体和支持
echo "正在安装中文字体..."
dnf install -y --skip-broken google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts || {
    echo "警告: 部分字体包安装失败，继续执行..."
}

# 设置中文环境和时区（添加 D-Bus 失败回退）
echo "export LANG=zh_CN.UTF-8" >> /etc/profile
echo "export LANGUAGE=zh_CN:zh" >> /etc/profile
echo "设置时区为 Asia/Shanghai..."
if timedatectl set-timezone Asia/Shanghai; then
    echo "时区设置成功"
else
    echo "警告: timedatectl 失败（可能因 D-Bus 不可用），尝试回退方法..."
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime || echo "错误: 无法设置时区，请手动检查"
fi

# 8. 安装和配置xrdp
echo "正在安装和配置xrdp..."
dnf install -y xrdp tigervnc-server || {
    echo "警告: xrdp 或 tigervnc-server 安装失败，继续执行..."
}

# 配置xrdp使用选择的桌面
echo "$xrdp_session" > /home/cooip/.Xclients
chown cooip:cooip /home/cooip/.Xclients
chmod +x /home/cooip/.Xclients

# 配置xrdp使用标准端口3389
cat > /etc/xrdp/xrdp.ini << EOF
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
crypt_level=low
channel_code=1

[xrdp1]
name=sesman-Xvnc
lib=libvnc.so
username=ask
password=ask
ip=0.0.0.0
port=-1
EOF

# 启用并启动xrdp服务
systemctl enable xrdp
systemctl start xrdp || {
    echo "警告: xrdp 服务启动失败，请检查日志: journalctl -u xrdp"
}

# 9. 配置VNC服务器（改进版本）
echo "正在配置VNC服务器..."

# 确保VNC目录存在
mkdir -p /home/cooip/.vnc
chown cooip:cooip /home/cooip/.vnc

# 设置VNC密码（使用更健壮的方法）
echo "设置VNC密码..."
if sudo -u cooip vncpasswd -f <<< "password" > /home/cooip/.vnc/passwd 2>/dev/null; then
    chmod 600 /home/cooip/.vnc/passwd
    echo "VNC密码设置成功"
else
    echo "警告: VNC密码设置失败，将尝试手动设置"
    # 手动设置VNC密码
    sudo -u cooip bash -c "mkdir -p ~/.vnc && echo 'password' | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd" || \
    echo "错误: 无法设置VNC密码，请稍后手动设置"
fi

# 创建VNC启动脚本
cat > /home/cooip/.vnc/xstartup << EOF
#!/bin/bash
export XDG_SESSION_TYPE=x11
export DISPLAY=:1
exec $session_cmd
EOF

chmod +x /home/cooip/.vnc/xstartup
chown cooip:cooip /home/cooip/.vnc/xstartup

# 创建VNC服务文件
cat > /etc/systemd/system/vncserver@:1.service << 'EOF'
[Unit]
Description=Remote Desktop Service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=cooip
Group=cooip

WorkingDirectory=/home/cooip
PIDFile=/home/cooip/.vnc/%H%i.pid
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver %i -geometry 1440x900 -depth 24
ExecStop=/usr/bin/vncserver -kill %i

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动VNC服务
systemctl daemon-reload
systemctl enable vncserver@:1.service

# 尝试启动VNC服务，但即使失败也不停止脚本执行
if systemctl start vncserver@:1.service; then
    echo "VNC服务启动成功"
else
    echo "警告: VNC服务启动失败，将在脚本末尾提供手动启动指南"
fi

# 10. 安装SSHD服务
echo "正在安装和配置SSHD..."
dnf install -y openssh-server || {
    echo "警告: openssh-server 安装失败，继续执行..."
}
systemctl enable --now sshd || {
    echo "警告: sshd 服务启动失败，请检查日志: journalctl -u sshd"
}

# 11. 安装Chromium浏览器
echo "正在安装Chromium浏览器..."
dnf install -y --skip-broken chromium || {
    echo "警告: chromium 安装失败，继续执行..."
}

# 12. 安装额外的应用程序
echo "正在安装额外应用程序..."
dnf install -y --skip-broken firefox vlc eom || {
    echo "警告: 部分应用程序安装失败，继续执行..."
}

# 13. 安装输入法框架
echo "正在安装输入法..."
dnf install -y --skip-broken ibus ibus-libpinyin || {
    echo "警告: 部分输入法包安装失败，继续执行..."
}

# 14. 安装GPU测试工具
echo "正在安装GPU测试工具..."
dnf install -y --skip-broken mesa-demos libva-utils || {
    echo "警告: 部分GPU测试工具安装失败，继续执行..."
}

# 15. 创建GPU测试脚本
cat > /home/cooip/test_gpu.sh << EOF
#!/bin/bash
echo "=== GPU 测试 ==="
echo "DRI 设备:"
ls -l /dev/dri/ 2>/dev/null || echo "无法访问/dev/dri，可能需在宿主系统配置权限"
echo ""
echo "OpenGL 信息:"
if command -v glxinfo >/dev/null 2>&1; then
    export DISPLAY=:1
    export XAUTHORITY=/home/cooip/.Xauthority
    glxinfo | grep -E "OpenGL|renderer|vendor" 2>/dev/null || echo "glxinfo 运行失败，可能缺乏GPU支持"
else
    echo "glxinfo 未安装"
fi
echo ""
echo "VA-API 测试:"
if command -v vainfo >/dev/null 2>&1; then
    vaininfo 2>/dev/null || echo "vainfo 运行失败，可能缺乏GPU支持"
else
    echo "vainfo 未安装"
fi
EOF

chmod +x /home/cooip/test_gpu.sh
chown cooip:cooip /home/cooip/test_gpu.sh

# 16. 修改文件权限
chown -R cooip:cooip /home/cooip

# 17. 配置防火墙（如果启用）
if systemctl is-active --quiet firewalld; then
    echo "配置防火墙..."
    firewall-cmd --permanent --add-port=22/tcp   # SSH
    firewall-cmd --permanent --add-port=3389/tcp  # RDP
    firewall-cmd --permanent --add-port=5901/tcp  # VNC
    firewall-cmd --reload
fi

# 18. 显示安装完成信息
echo ""
echo "=== 安装完成! ==="
echo ""
echo "远程桌面服务:"
echo "  - SSH: 端口 22"
echo "  - xrdp (RDP): 端口 3389"
echo "  - VNC: 端口 5901"
echo ""
echo "用户信息:"
echo "  - 用户名: cooip"
echo "  - 密码: password (请及时更改)"
echo ""
echo "GPU测试:"
echo "  - 运行 /home/cooip/test_gpu.sh 测试GPU功能"
echo ""
echo "连接方式:"
echo "  - SSH: ssh cooip@<容器IP>"
echo "  - RDP: 使用RDP客户端连接 <容器IP>:3389"
echo "  - VNC: 使用VNC客户端连接 <容器IP>:5901"
echo ""
echo "服务管理:"
echo "  - 查看sshd状态: systemctl status sshd"
echo "  - 查看xrdp状态: systemctl status xrdp"
echo "  - 查看VNC状态: systemctl status vncserver@:1.service"
echo "  - 查看D-Bus状态: systemctl status dbus"
echo ""
echo "注意事项:"
echo "  1. 首次连接可能需要几分钟时间加载桌面环境"
echo "  2. 建议安装后立即更改cooip用户的密码"
echo "  3. 如果VNC显示黑屏，请尝试手动启动: su - cooip -c 'vncserver :1 -geometry 1440x900 -depth 24'"
echo "  4. 如果xrdp有问题，检查日志: journalctl -u xrdp 或 /var/log/xrdp.log"
echo "  5. 时区已设置为Asia/Shanghai（若失败，请检查 D-Bus 状态）"

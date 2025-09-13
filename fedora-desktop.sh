#!/bin/bash

# Fedora LXC 桌面环境配置脚本
# 适用于 Arm 设备,X86未测试
# 使用 MATE 桌面环境

### dnf install -y wget
### wget -O - https://raw.githubusercontent.com/cooip-jm/About-openwrt/main/fedora-desktop.sh | sh -s -- -v



set -e  # 遇到错误立即退出

echo "=== Fedora LXC 桌面环境配置脚本 ==="

# 1. 配置国内镜像源
echo "正在配置国内镜像源..."
sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora|g' \
    -i.bak \
    /etc/yum.repos.d/fedora.repo \
    /etc/yum.repos.d/fedora-updates.repo

dnf makecache
#sed -e 's|^metalink=|#metalink=|g' \
#    -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.cernet.edu.cn/fedora|g' \
#    -i.bak \
#    /etc/yum.repos.d/fedora.repo \
#    /etc/yum.repos.d/fedora-updates.repo




# 2. 更新系统（排除内核更新）
echo "正在更新系统（排除内核）..."
dnf update -y --exclude=kernel*

# 3. 安装基础工具
echo "正在安装基础工具..."
dnf install -y nano btop fastfetch curl sudo bash openssl

# 4. 安装GPU驱动程序 (RK3588 Mali GPU支持)
echo "正在安装GPU驱动程序..."
dnf install -y mesa-dri-drivers mesa-va-drivers mesa-vulkan-drivers

# 5. 创建cooip用户并添加到wheel组
echo "正在创建用户账户..."
if ! id "cooip" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash -c "Desktop User" cooip
    echo "cooip:password" | chpasswd  # 请安装后及时更改密码
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
else
    echo "用户cooip已存在，跳过创建"
fi

# 将用户添加到必要的组
usermod -a -G video cooip
usermod -a -G input cooip

# 6. 安装MATE桌面环境
echo "正在安装MATE桌面环境..."
dnf install -y @mate-desktop-environment --exclude=kernel*

# 7. 安装中文字体和支持
echo "正在安装中文字体..."
dnf install -y google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts

# 设置中文环境
echo "export LANG=zh_CN.UTF-8" >> /etc/profile
echo "export LANGUAGE=zh_CN:zh" >> /etc/profile

# 8. 安装和配置xrdp
echo "正在安装和配置xrdp..."
dnf install -y xrdp tigervnc-server

# 配置xrdp使用Mate
echo "mate-session" > /home/cooip/.Xclients
chown cooip:cooip /home/cooip/.Xclients

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
systemctl start xrdp

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
cat > /home/cooip/.vnc/xstartup << 'EOF'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export DISPLAY=:1
exec mate-session
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

# 10. 安装Chromium浏览器
echo "正在安装Chromium浏览器..."
dnf install -y chromium

# 11. 安装额外的应用程序
echo "正在安装额外应用程序..."
dnf install -y firefox vlc eom

# 12. 安装输入法框架
echo "正在安装输入法..."
dnf install -y ibus ibus-libpinyin

# 13. 安装GPU测试工具
echo "正在安装GPU测试工具..."
dnf install -y mesa-demos libva-utils

# 14. 创建GPU测试脚本
cat > /home/cooip/test_gpu.sh << 'EOF'
#!/bin/bash
echo "=== GPU 测试 ==="
echo "DRI 设备:"
ls -l /dev/dri/
echo ""
echo "OpenGL 信息:"
if command -v glxinfo >/dev/null 2>&1; then
    export DISPLAY=:1
    glxinfo | grep -E "OpenGL|renderer|vendor"
else
    echo "glxinfo 未安装"
fi
echo ""
echo "VA-API 测试:"
if command -v vainfo >/dev/null 2>&1; then
    vainfo
else
    echo "vainfo 未安装"
fi
EOF

chmod +x /home/cooip/test_gpu.sh
chown cooip:cooip /home/cooip/test_gpu.sh

# 15. 修改文件权限
chown -R cooip:cooip /home/cooip

# 16. 配置防火墙（如果启用）
if systemctl is-active --quiet firewalld; then
    echo "配置防火墙..."
    firewall-cmd --permanent --add-port=3389/tcp  # RDP
    firewall-cmd --permanent --add-port=5901/tcp  # VNC
    firewall-cmd --reload
fi

# 17. 显示安装完成信息
echo ""
echo "=== 安装完成! ==="
echo ""
echo "远程桌面服务:"
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
echo "  - RDP: 使用RDP客户端连接 <容器IP>:3389"
echo "  - VNC: 使用VNC客户端连接 <容器IP>:5901"
echo "  - SSH: ssh cooip@<容器IP>"
echo ""
echo "服务管理:"
echo "  - 查看xrdp状态: systemctl status xrdp"
echo "  - 查看VNC状态: systemctl status vncserver@:1.service"
echo ""
echo "注意事项:"
echo "  1. 首次连接可能需要几分钟时间加载桌面环境"
echo "  2. 建议安装后立即更改cooip用户的密码"
echo "  3. 如果VNC服务启动失败，请尝试手动启动:"
echo "     su - cooip -c 'vncserver :1 -geometry 1440x900 -depth 24'"
echo "  4. 如果遇到连接问题，请检查服务状态: systemctl status xrdp"

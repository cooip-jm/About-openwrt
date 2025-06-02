#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" != "0" ]; then
    echo "错误：请以 root 权限运行此脚本"
    exit 1
fi

# 检查是否在 LXC 容器中运行
if command -v virt-what >/dev/null 2>&1; then
    if virt-what | grep -q "lxc"; then
        echo "警告：检测到 LXC 容器环境，无法直接启用 BBR。请在宿主机上运行此脚本。"
        echo "在容器内检查 BBR 状态："
        sysctl net.ipv4.tcp_congestion_control
        exit 1
    fi
fi

# 检查 BBR 状态
echo "=== 检查 BBR 状态 ==="
echo "1. 检查可用拥塞控制算法："
sysctl net.ipv4.tcp_available_congestion_control
if sysctl net.ipv4.tcp_available_congestion_control | grep -q "bbr"; then
    echo "BBR 模块可用"
else
    echo "BBR 模块不可用，可能需要加载"
fi

echo "2. 检查当前拥塞控制算法："
sysctl net.ipv4.tcp_congestion_control
if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "当前已使用 BBR"
else
    echo "当前未使用 BBR，使用的是 $(sysctl -n net.ipv4.tcp_congestion_control)"
fi

echo "3. 检查默认队列规则："
if sysctl net.core.default_qdisc >/dev/null 2>&1; then
    sysctl net.core.default_qdisc
    if sysctl net.core.default_qdisc | grep -q "fq"; then
        echo "队列规则已设置为 fq（BBR 推荐）"
    else
        echo "队列规则为 $(sysctl -n net.core.default_qdisc)，建议设置为 fq"
    fi
else
    echo "无法检查队列规则，可能在容器环境中"
fi

echo "4. 检查 BBR 模块是否加载："
if lsmod | grep -q "tcp_bbr"; then
    echo "tcp_bbr 模块已加载"
else
    echo "tcp_bbr 模块未加载"
fi
echo

# 启用 BBR
echo "=== 启用 BBR ==="
# 加载 BBR 模块
if ! lsmod | grep -q "tcp_bbr"; then
    echo "加载 tcp_bbr 模块..."
    modprobe tcp_bbr
    if [ $? -eq 0 ]; then
        echo "tcp_bbr 模块加载成功"
    else
        echo "错误：无法加载 tcp_bbr 模块，请检查内核是否支持"
        exit 1
    fi
else
    echo "tcp_bbr 模块已加载，无需重复加载"
fi

# 设置模块开机自动加载
if ! grep -q "tcp_bbr" /etc/modules-load.d/modules.conf 2>/dev/null; then
    echo "将 tcp_bbr 添加到开机加载..."
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
else
    echo "tcp_bbr 已存在于 /etc/modules-load.d/modules.conf"
fi

# 配置 sysctl 参数
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null; then
    echo "设置 net.core.default_qdisc=fq..."
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
else
    echo "net.core.default_qdisc=fq 已存在于 /etc/sysctl.conf"
fi

if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null; then
    echo "设置 net.ipv4.tcp_congestion_control=bbr..."
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
else
    echo "net.ipv4.tcp_congestion_control=bbr 已存在于 /etc/sysctl.conf"
fi

# 应用 sysctl 配置，忽略无效参数
echo "应用 sysctl 配置..."
if sysctl -p >/dev/null 2>&1; then
    echo "sysctl 配置应用成功"
else
    echo "警告：sysctl 配置应用时遇到错误，可能存在无效参数"
    echo "尝试忽略无效参数重新应用..."
    grep -v "nf_conntrack_helper" /etc/sysctl.conf > /tmp/sysctl_temp.conf
    sysctl -p /tmp/sysctl_temp.conf
    if [ $? -eq 0 ]; then
        echo "忽略无效参数后 sysctl 配置应用成功"
        mv /tmp/sysctl_temp.conf /etc/sysctl.conf
        echo "已更新 /etc/sysctl.conf，移除了无效参数"
    else
        echo "错误：sysctl 配置仍失败，请手动检查 /etc/sysctl.conf"
        exit 1
    fi
fi
echo

# 验证 BBR 是否启用
echo "=== 验证 BBR 配置 ==="
echo "1. 验证可用拥塞控制算法："
sysctl net.ipv4.tcp_available_congestion_control
if sysctl net.ipv4.tcp_available_congestion_control | grep -q "bbr"; then
    echo "验证通过：BBR 模块可用"
else
    echo "验证失败：BBR 模块不可用"
    exit 1
fi

echo "2. 验证当前拥塞控制算法："
sysctl net.ipv4.tcp_congestion_control
if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "验证通过：当前使用 BBR"
else
    echo "验证失败：当前未使用 BBR"
    exit 1
fi

echo "3. 验证默认队列规则："
if sysctl net.core.default_qdisc >/dev/null 2>&1; then
    sysctl net.core.default_qdisc
    if sysctl net.core.default_qdisc | grep -q "fq"; then
        echo "验证通过：队列规则为 fq"
    else
        echo "验证失败：队列规则不是 fq"
        exit 1
    fi
else
    echo "无法验证队列规则，可能在容器环境中"
fi

echo "4. 验证 BBR 模块加载："
if lsmod | grep -q "tcp_bbr"; then
    echo "验证通过：tcp_bbr 模块已加载"
else
    echo "验证失败：tcp_bbr 模块未加载"
    exit 1
fi

echo
echo "BBR 已成功启用！建议重启系统以确保配置持久生效："
echo "sudo reboot"
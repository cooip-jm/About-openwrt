// 节点去重复、异常字符节点过滤脚本——已验证

const existingProxies = [];

// 检查给定服务器和端口是否已存在于现有代理列表中
function isDuplicate(server, port) {
    return existingProxies.some(p => p.server === server && p.port === port);
}

// 检查字符串是否是 ASCII 字符串
function isAscii(str) {
    var pattern = /^[\x00-\x7F]+$/;
    return pattern.test(str);
}

// 过滤代理列表，同时添加新代理到现有代理列表中
function filter(proxies) {
    return proxies.map(p => {
        if (isDuplicate(p.server, p.port)) {
            return false; // 已存在的代理，返回false
        } else {
            if ((p.cipher && !isAscii(p.cipher)) || (p.password && !isAscii(p.password))) {
                return false; // 密码或者加密方式不是ASCII，直接返回false
            } else {
                existingProxies.push({ server: p.server, port: p.port });
                return true; // 新的代理，返回true
            }
        }
    });
}

# one-click-ss-libev-mu
shadowsocks-libev 与 ss-libev-mu 的一键脚本

与之前的python版本相差很大，且强制使用systemd作为进程守护服务。

## 安装

安装之前请务必保持系统纯净，假如之前安装过shadowsocks，可能会导致安装失败

为了安全，一键脚本还会安装caddy来代理api，请添加相关参数来执行自动安装

目前支持Centos/Fedora/Redhat/Debian/Ubuntu

一键命令：
```
wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/one-click-ss-libev-mu/main/install.sh && bash install.sh
```

参数：
```
k: 认证代码
r：安装完成后运行
c: 安装caddy
u: API域名，需提前绑定到服务器，不安装caddy可不填
e: 电子邮箱，为了申请SSL证书，不安装caddy可不填
```

不提供参数的情况下，将会自行生成32位Key，安装最后一句显示

## 升级
一键命令：
```
wget --no-check-certificate -O ./upgrade.sh https://raw.githubusercontent.com/misakanetwork2018/one-click-ss-libev-mu/main/upgrade.sh && bash upgrade.sh
```

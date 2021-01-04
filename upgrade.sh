#!/bin/sh
mu_download_url=`curl -s https://api.github.com/repos/misakanetwork2018/ss-libev-mu/releases/latest | jq -r ".assets[] | select(.name) | .browser_download_url"`

echo "upgrade ss-libev-mu only"
systemctl stop shadowsocks-mu
wget --no-check-certificate -O /usr/bin/ss-libev-mu $mu_download_url
chmod a+x /usr/bin/ss-libev-mu
systemctl restart shadowsocks
systemctl start shadowsocks-mu
echo "Everything is OK!"

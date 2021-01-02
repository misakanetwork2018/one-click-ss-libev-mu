#!/bin/sh

GETOPT_ARGS=`getopt -o k::r -l key::,run -- "$@"`
eval set -- "$GETOPT_ARGS"
OLD_IFS="$IFS"
IFS=" "
arguments=($*)
IFS="$OLD_IFS"
key=`head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 32`
run=false

#获取参数
while [ -n "$1" ]
do
	case "$1" in
		-k|--key) key=$OPTARG;shift 2;;
		-r|--run) run=true;shift 1;;
		--) shift 1;;
        esac
done

#获得系统类型
Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        SYSTEM_VER=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
        if [[ $systemver -ge 8 ]]; then
            PM='dnf' 
        else 
            PM='yum' 
        fi
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='dnf'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    else
        DISTRO='unknow'
    fi
}

#安装依赖
function instdpec()
{
	if [ "$1" == "CentOS" ] || [ "$1" == "CentOS7" ];then
		$PM -y groupinstall "Development Tools"
		$PM -y install epel-release
		$PM -y install wget jq
		$PM -y install pcre-devel \
mbedtls-devel \
libev-devel \
c-ares-devel
	elif [ "$1" == "Debian" ] || [ "$1" == "Raspbian" ] || [ "$1" == "Ubuntu" ];then
		$PM update
		$PM -y install wget jq
		$PM -y install build-essential
		$PM -y install libpcre3-dev \
libmbedtls-dev \
libev-dev \
libc-ares-dev
	else
		echo "The shell can be just supported to install ssr on Centos, Ubuntu and Debian."
		exit 1
	fi
}

Get_Dist_Name

echo "Your OS is $DISTRO"

echo -e "\033[42;34mInstall dependent packages\033[0m"
instdpec $DISTRO;

# config
ss_download_url=`curl -s https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | jq -r ".assets[] | select(.name) | .browser_download_url"`
mu_download_url=`curl -s https://api.github.com/repos/misakanetwork2018/ss-libev-mu/releases/latest | jq -r ".assets[] | select(.name) | .browser_download_url"`
work_dir=/usr/src
ss_install_dir=/usr/local/shadowsocks-libev


# install shadowsocks-libev
echo -e "\033[42;34mInstall Shadowsocks-libev\033[0m"
wget -c -O $work_dir/ss-libev.tar.gz $ss_download_url
tar zxf $work_dir/ss-libev.tar.gz
cd ss-libev
./configure --prefix=$ss_install_dir --disable-documentation
make && make install
if [ $? -ne 0 ]; then
    echo "Failed to install Shadowsocks-libev. Please try again later."
    exit 1
fi
# link bin
# others should link by yourself
ln -s $ss_install_dir/bin/ss-server /usr/bin/ss-server
ln -s $ss_install_dir/bin/ss-manager /usr/bin/ss-manager

# install ss-mu-go
wget -c -O /usr/bin/ss-libev-mu $ss_download_url
chmod a+x /usr/bin/ss-libev-mu
# set systemd service
cat > /etc/systemd/system/shadowsocks.service <<EOF
[Unit]
Description=Shadowsocks libev
After=network.target
Wants=network.target

[Service]
Restart=on-failure
Type=simple
PIDFile=/var/run/ss-manager.pid
ExecStart=/usr/bin/ss-manager --manager-address /var/run/shadowsocks-manager.sock -s :: -s 0.0.0.0 -t 360

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/shadowsocks-mu.service <<EOF
[Unit]
Description=Shadowsocks libev manyuser manager
After=network.target
Wants=network.target

[Service]
Restart=on-failure
Type=simple
PIDFile=/var/run/ss-libev-mu.pid
ExecStart=/usr/bin/ss-libev-mu -c /etc/ss_mu.json

[Install]
WantedBy=multi-user.target
EOF

# write config file

cat > /etc/ss_mu.json <<EOF
{
    "manager_address": "/var/run/shadowsocks-manager.sock",
    "bind_address": "/var/run/ss-libev-mu.sock",
    "key": "${key}",
    "address": "127.0.0.1:8080"
}
EOF

echo "4. Run"
systemctl daemon-reload
systemctl enable shadowsocks.service
systemctl enable shadowsocks-mu.service

# If run
if [ $run ]
then
systemctl start shadowsocks.service
systemctl start shadowsocks-mu.service
fi

# Disable and stop firewalld
if [ "$1" == "CentOS" ] || [ "$1" == "CentOS7" ];then
systemctl disable firewalld
systemctl stop firewalld
fi

echo "Install successfully. Your key is ${key}"


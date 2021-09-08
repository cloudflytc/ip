#! /bin/bash

sudo apt install openresolv

echo "检测wireguard安装情况" 

modprobe wireguard

if lsmod | grep wireguard ; then
    echo "wireguard 已安装"
else
    echo "wireguard 未安装"
    echo "请根据官网教程安装: https://www.wireguard.com/install/"
    exit
fi

mkdir netflixjs
cd netflixjs


wget -O wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.2/wgcf_2.2.2_linux_amd64
chmod +x wgcf
./wgcf register
./wgcf generate

if ls -l wgcf-profile.conf;then
    echo "注册成功"
else
    echo "warp注册失败"
    echo "请进入netflxjs文件夹 输入"
    echo "./wgcf register"
    echo "./wgcf generate"
    echo "来获取warp的wg文件"
    exit
fi

if ls -l netflixjs.conf; then
    rm -rf netflixjs.conf
fi

if ls -l netflix.txt; then
    rm -rf netflix.txt
fi

wget https://raw.githubusercontent.com/cloudflytc/ip/main/netflix.txt
var=$(cat netflix.txt)
if ls -l netflixjs.conf; then
    rm -rf netflixjs.conf
fi

cat wgcf-profile.conf | while read line
do
    if [ "$line"x = "AllowedIPs = 0.0.0.0/0"x ]; then
       echo "AllowedIPs = $var" >> netflixjs.conf
    else
        echo $line >> netflixjs.conf
    fi
done

rm -rf netflix.txt

mv netflixjs.conf /etc/wireguard/netflixjs.conf

wg-quick up netflixjs

result=`curl -m 10 -o /dev/null -s -w %{http_code} https://www.netflix.com/title/70143836`;
if [ "$result"x = "301"x ];then
    echo "***************"
    echo "解锁成功"
    echo "如果想开机启动请输入"
    echo "systemctl enable wg-quick@netflixjs.service"
    echo "***************"
else
    echo "解锁失败"
fi

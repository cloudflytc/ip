#! /bin/bash

echo "安装wireguard" 
yum install oraclelinux-developer-release-el7
yum-config-manager --disable ol7_developer
yum-config-manager --enable ol7_developer_UEKR6
yum-config-manager --save --setopt=ol7_developer_UEKR6.includepkgs='wireguard-tools*'
yum install wireguard-tools


mkdir netflixjs
cd netflixjs

get_arch=`arch`
if [[ $get_arch =~ "x86_64" ]];then
    os="amd64"
elif [[ $get_arch =~ "aarch64" ]];then
    os="armv7"
elif [[ $get_arch =~ "mips64" ]];then
    os="mips_softfloat"
else
    echo "unknown!!"
fi

url_first="https://github.com/ViRb3/wgcf/releases/download/v2.2.3/wgcf_2.2.3_linux_"
url=$url_first$os

wget -O wgcf $url
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
    result=$(echo $line | grep ":") 
    if [ -n "$result" ]; then
        if [ "$line"x = "Endpoint = engage.cloudflareclient.com:2408"x ]; then
            echo $line >> warp.conf
        else
            echo "去除v6地址"
        fi
    else
        echo $line >> warp.conf
    fi
done

cat warp.conf | while read line
do
    if [ "$line"x = "AllowedIPs = 0.0.0.0/0"x ]; then
       echo "AllowedIPs = $var" >> netflixjs.conf
    else
        echo $line >> netflixjs.conf
    fi
done

rm -rf netflix.txt
rm -rf warp.conf
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

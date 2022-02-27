#! /bin/bash
cd /root

sys_bit=$(uname -m)

case $sys_bit in
i[36]86)
        ARCH="latest"
        caddy_arch="386"
        ;;
'amd64' | x86_64)
        ARCH="latest"
        caddy_arch="amd64"
        ;;
*aarch64* | *armv8*)
        ARCH="arm64"
        caddy_arch="arm64"
        ;;
*)
        echo -e " 
        哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

        备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
        " && exit 1
        ;;
esac

apt-get install wireguard -y
apt-get install docker.io -y

echo "检测wireguard安装情况" 

modprobe wireguard



if lsmod | grep wireguard ; then
    echo "wireguard 已安装"
else
    echo "wireguard 未安装"
    echo "请根据官网教程安装: https://www.wireguard.com/install/"
    exit
fi

echo "检测docker安装情况" 

modprobe docker

echo "检查Docker......"
docker -v
if [ $? -eq  0 ]; then
    echo "检查到Docker已安装!"
else
    echo "安装docker环境..."
    curl -sSL https://get.daocloud.io/docker | sh
    echo "安装docker环境...安装完成!"
    echo "再次检查Docker......"
    docker -v
    if [ $? -eq  0 ]; then
    	echo "检查到Docker已安装!"
    else
    	echo "docker安装失败"
    	exit
fi
fi



service docker start

mkdir warp-docker
cd warp-docker

if ls -l warp.conf; then
    rm -rf warp.conf
fi

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
echo | ./wgcf register
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
rm -rf wgcf-profile.conf

#! /bin/bash


uuid=$(cat /proc/sys/kernel/random/uuid)
ciphers=(
	aes-128-cfb
	aes-256-cfb
	chacha20
	chacha20-ietf
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)
v2ray_port_config() {
	case $v2ray_transport in
	4 | 5 | 33)
		tls_config
		;;
	*)
		local random=$(shuf -i20001-65535 -n1)
		while :; do
			echo -e "请输入 "$yellow"V2Ray"$none" docker内部端口 ["$magenta"1-65535"$none"]"
			read -p "$(echo -e "(默认端口: ${cyan}${random}$none):")" v2ray_port
			[ -z "$v2ray_port" ] && v2ray_port=$random
			case $v2ray_port in
			[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
				echo
				echo
				echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			*)
				error
				;;
			esac
		done
		if [[ $v2ray_transport -ge 18 && $v2ray_transport -ne 33 ]]; then
			v2ray_dynamic_port_start
		fi
		;;
	esac
}

shadowsocks_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" docker内部端口 ["$magenta"1-65535"$none"]，不能和 "$yellow"V2Ray"$none" 端口相同"
		read -p "$(echo -e "(默认端口: ${cyan}${random}$none):") " ssport
		[ -z "$ssport" ] && ssport=$random
		case $ssport in
		$v2ray_port)
			echo
			echo " 不能和 V2Ray 端口一毛一样...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == [45] ]]; then
				local tls=ture
			fi
			if [[ $tls && $ssport == "80" ]] || [[ $tls && $ssport == "443" ]]; then
				echo
				echo -e "由于你已选择了 "$green"WebSocket + TLS $none或$green HTTP/2"$none" 传输协议."
				echo
				echo -e "所以不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
				error
			elif [[ $v2ray_dynamic_port_start_input == $ssport || $v2ray_dynamic_port_end_input == $ssport ]]; then
				local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
				echo
				echo " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：$multi_port"
				error
			elif [[ $v2ray_dynamic_port_start_input -lt $ssport && $ssport -le $v2ray_dynamic_port_end_input ]]; then
				local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
				echo
				echo " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：$multi_port"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks 端口 = $cyan$ssport$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done
}
shadowsocks_password_config() {

	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 密码"
		read -p "$(echo -e "(默认密码: ${cyan}233blog.com$none)"): " sspass
		[ -z "$sspass" ] && sspass="233blog.com"
		case $sspass in
		*[/$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks 密码 = $cyan$sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done

	shadowsocks_ciphers_config
}
shadowsocks_ciphers_config() {

	while :; do
		echo -e "请选择 "$yellow"Shadowsocks"$none" 加密协议 [${magenta}1-${#ciphers[*]}$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(默认加密协议: ${cyan}${ciphers[6]}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && ssciphers_opt=7
		case $ssciphers_opt in
		[1-7])
			ssciphers=${ciphers[$ssciphers_opt - 1]}
			echo
			echo
			echo -e "$yellow Shadowsocks 加密协议 = $cyan${ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
}

get_ip() {
	ip=$(curl -s https://ipinfo.io/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
	[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
	[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
	[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && echo -e "\n$red 这垃圾小鸡扔了吧！$none\n" && exit
}


error() {

	echo -e "\n$red 输入错误！$none\n"

}
v2ray_port_config
shadowsocks_port_config
shadowsocks_password_config
get_ip



if ls -l config.json; then
    rm -rf config.json
fi

wget https://raw.githubusercontent.com/cloudflytc/wireguard-proxy/main/wireguard-v2ray/config-mb.json

cat config-mb.json | while read line
do
  result=$(echo $line | grep "48424") 
  result2=$(echo $line | grep "1130fa2c-498d-4766-8d2a-197bc65ba84d")
  result3=$(echo $line | grep "35734") 
  result4=$(echo $line | grep "aes-256-gcm") 
  result5=$(echo $line | grep "password") 
  if [ -n "$result" ]; then
	echo '"port": '${v2ray_port}',' >> config.json
  elif [ -n "$result2" ]; then
  	echo '"id": "'${uuid}'",' >> config.json
  elif [ -n "$result3" ]; then
  	echo '"port": '${ssport}',' >> config.json
  elif [ -n "$result4" ]; then
  	echo '"method": "'${ssciphers}'",' >> config.json
  elif [ -n "$result5" ]; then
	echo '"password": "'${sspass}'",' >> config.json
  else 
  	echo $line >> config.json
  fi
done
rm -rf config-mb.json

docker run -d --restart=always --cap-add=NET_ADMIN \
     --privileged \
    --name wireguard-v2ray-warp \
    --volume /root/warp-docker:/etc/wireguard/:ro \
    --volume /root/warp-docker:/etc/v2ray \
    -p $ssport:$ssport \
    -p $ssport:$(ssport)/udp \
    -p $v2ray_port:$v2ray_port \
    -p $v2ray_port:$(v2ray_port)/udp \
    cloudfly23/wireguard-proxy-v2ray:$ARCH
docker ps -a




ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#ss_${ip}"
json="{\"v\": \"2\",\"ps\": \"\",\"add\": \"${ip}\",\"port\": \"$v2ray_port\",\"id\": \"$uuid\",\"aid\": \"0\",\"net\": \"ws\",\"type\": \"none\",\"host\": \"\",\"path\": \"\",\"tls\": \"\"}"

v2ray="vmess://$(echo -n "${json}" | base64 -w 0)"
echo
echo
echo -e "ss链接："
echo $ss
echo
echo
echo -e "v2ray链接："
echo $v2ray

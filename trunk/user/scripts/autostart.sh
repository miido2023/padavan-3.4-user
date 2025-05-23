#!/bin/sh
#nvram set ntp_ready=0
self_name="autostart.sh"
logger -t "${self_name}" "开始运行"

if [ $(nvram get sdns_enable) = 1 ] ; then
   if [ -f "$smartdns_conf" ] ; then
       sed -i '/去广告/d' $smartdns_conf
       sed -i '/adbyby/d' $smartdns_conf
       sed -i '/no-resolv/d' "$dnsmasq_Conf"
       sed -i '/server=127.0.0.1#'"$sdns_portd"'/d' "$dnsmasq_Conf"
       sed -i '/port=0/d' "$dnsmasq_Conf"
       rm  -f "$smartdns_Ini"
   fi
logger -t "自动启动" "正在启动 SmartDNS..."
/etc/storage/smartdns.sh start
fi

if [ $(nvram get caddy_enable) = 1 ] ; then
logger -t "${self_name}" "自动启动 正在启动文件管理"
/usr/bin/caddy.sh start
fi
smartdns_conf="/etc/storage/smartdns_custom.conf"
dnsmasq_Conf="/etc/storage/dnsmasq/dnsmasq.conf"
smartdns_Ini="/etc/storage/smartdns_conf.ini"
sdns_port=$(nvram get sdns_port)

logger -t "${self_name}" "自动启动 正在检查路由是否已连接互联网！"
count=0
while :
do
												 
						 
	   
   
	ping -c 1 -W 1 -q 223.5.5.5 1>/dev/null 2>&1
	if [ "$?" == "0" ]; then
		break
	fi
	sleep 5
	ping -c 1 -W 1 -q baidu.com 1>/dev/null 2>&1
						 
	   
   
										   
	if [ "$?" == "0" ]; then
		break
	fi
	sleep 5
	count=$((count+1))
	if [ $count -gt 18 ]; then
		break
	fi
done

if [ $(nvram get adbyby_enable) = 1 ] ; then
logger -t "${self_name}" "自动启动 正在启动adbyby plus+"
/usr/bin/adbyby.sh start
fi

if [ $(nvram get aliddns_enable) = 1 ] ; then
logger -t "${self_name}" "自动启动 正在启动阿里ddns"
/usr/bin/aliddns.sh start
fi

if [ $(nvram get ddnsto_enable) = 1 ] ; then
logger -t "自动启动" "正在启动 ddnsto..."
/usr/bin/ddnsto.sh start
fi

if [ $(nvram get ss_enable) = 1 ] ; then
logger -t "${self_name}" "自动启动 正在启动科学上网"
/usr/bin/shadowsocks.sh start
fi

if [ $(nvram get adg_enable) = 1 ] ; then
logger -t "${self_name}" "自动启动 正在启动adguardhome"
/etc/storage/adguardhome.sh start
fi

if [ $(nvram get zerotier_enable) = 1 ] ; then
logger -t "${self_name}" "自动启动 正在启动zerotier"
/usr/bin/zerotier.sh start
fi
if [ $(nvram get frpc_enable) = 1 ] ; then
logger -t "自动启动" "正在启动frp client..."
/usr/bin/frp.sh start
fi

if [ $(nvram get aliyundrive_enable) = 1 ] ; then
logger -t "自动启动" "正在启动阿里云盘..."
/etc/storage/aliyundrive-webdav.sh start
fi

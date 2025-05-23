#!/bin/sh

self_name="opt-mount.sh"

logger -t "${self_name}" "开始检查OptWare服务..."

# check params
[ -z "$1" ] || [ -z "$2" ] && exit 1


mtd_device=`echo "$1" | egrep '^/dev/mtd|^/dev/ubi'`


if [ -z "$mtd_device" ] ; then
	optw_enable=`nvram get optw_enable`
	[ "$optw_enable" != "1" ] && (logger -t "${self_name}" "OptWare配置未开启！") && exit 0
fi


# check /opt already mounted then exit
mountpoint -q /opt && (logger -t "${self_name}" "/opt目录已挂载！") && exit 0


# check dir "opt" exist on the drive root
[ ! -d "$2/opt" ] && exit 0


logger -t "${self_name}" "starting... [$@] "


# mount /opt (bind only)
mount -o bind "$2/opt" /opt
if [ $? -ne 0 ] ; then
	logger -t "${self_name}" "挂载 $2/opt 到 /opt 失败！"
	exit 1
fi

logger -t "${self_name}" "已挂载USB $2/opt 到系统根目录/opt"

# 如果不存在/opt/bin/opkg二进制文件，则启动安装sh
if [ ! -f /opt/bin/opkg ] ; then
	logger -t "${self_name}" "未检测到/opt/bin/opkg二进制文件，开始安装..."
	/usr/bin/opt-opkg-upd.sh
	exit 1
fi

# check opt profile exist
if [ ! -f /opt/etc/profile ] ; then
	cat > /opt/etc/profile <<EOF

# If running interactively, then
if [ "\$PS1" ] ; then

    export TERM=xterm
    export LANG=en_US.UTF-8
    export TMP=/opt/tmp
    export TEMP=/opt/tmp
 
fi;

EOF
fi


# check swap file exist
if [ -z "$mtd_device" ] && [ -f /opt/.swap ] ; then
	swap_part=`cat /proc/swaps | grep 'partition' 2>/dev/null`
	swap_file=`cat /proc/swaps | grep 'file' 2>/dev/null`
	if [ -z "$swap_part" ] && [ -z "$swap_file" ] ; then
		swapon /opt/.swap
		[ $? -eq 0 ] && logger -t "${self_name}" "Activate swap file /opt/.swap SUCCESS!"
	fi
fi

# create system tweak script
system_init_d="/opt/etc/init.d/S01system"
if [ ! -f "$system_init_d" ]  ; then
	cat > "$system_init_d" <<EOF
#!/bin/sh

### Custom user script for system tweak

func_start()
{
	echo "Start system tweak"
	# insert your custom code below
}

func_stop()
{
	echo "Stop system tweak"
	# insert your custom code below
}

case "\$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
restart)
	func_stop
	func_start
	;;
*)
	echo "Usage: \$0 {start|stop|restart}"
	exit 1
	;;
esac

EOF
	chmod 755 "$system_init_d"
fi

# create iptables update script
iptables_script="/opt/bin/update_iptables.sh"
iptables_init_d="/opt/etc/init.d/S10iptables"
if [ ! -f "$iptables_script" ]  ; then
	cat > "$iptables_script" <<EOF
#!/bin/sh

### Custom user script for post-update iptables
### This script auto called after internal firewall restart
### First param is:
###  "start" (call at start optware),
###  "stop" (call before stop optware),
###  "update" (call after internal firewall restart).
### Include you custom rules for iptables below:

case "\$1" in
start|update)
	# add iptables custom rules
	echo "firewall started"
	;;
stop)
	# delete iptables custom rules
	echo "firewall stopped"
	;;
*)
	echo "Usage: \$0 {start|stop|update}"
	exit 1
	;;
esac

EOF
	chmod 755 "$iptables_script"
fi

if [ ! -L "$iptables_init_d" ]  ; then
	ln -sf "$iptables_script" "$iptables_init_d"
fi

# create script for WPS button events handling
wps_script="/opt/bin/on_wps.sh"
if [ ! -f "$wps_script" ]  ; then
	cat > "$wps_script" <<EOF
#!/bin/sh

### Custom user script for WPS button events handling

case "\$1" in
1)
	# WPS short pressed
	echo "WPS button short pressed!"
	;;
2)
	# WPS long pressed
	echo "WPS button long pressed!"
	;;
esac

EOF
	chmod 755 "$wps_script"
fi

# create script for printer hotplug event handling
lph_script="/opt/bin/on_hotplug_printer.sh"
if [ ! -f "$lph_script" ]  ; then
	cat > "$lph_script" <<EOF
#!/bin/sh

[ -z "\$1" ] && exit 1

### Custom user script for printer hotplug event handling
### First param is /dev/usb/lp[0-9]

### Example: load firmware to printer HP LJ1020
lpfw="/opt/share/firmware/sihp1020.dl"
if [ -r "\$lpfw" ] ; then
	cat "\$lpfw" > "\$1"
fi

EOF
	chmod 755 "$lph_script"
fi

# mark opt needed start
if [ -z "$mtd_device" ] ; then
	nvram settmp usb_opt_start=1
	exit 0
fi

logger -t "${self_name}" "call /opt/etc/init.d" "启动USB已安装的服务(S***开头的服务)"

# extend path to /opt
export PATH=/opt/sbin:/opt/bin:/usr/sbin:/usr/bin:/sbin:/bin

# start all services S* in /opt/etc/init.d
for i in `ls /opt/etc/init.d/S??* 2>/dev/null` ; do
	[ ! -x "${i}" ] && continue
	${i} start
done

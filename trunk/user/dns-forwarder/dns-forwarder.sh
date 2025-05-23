#!/bin/sh

NAME=dns-forwarder
BIN=$(test -e /usr/bin/$NAME && echo /usr/bin/$NAME || echo /opt/bin/$NAME)
bind_address=$(nvram get dns_forwarder_bind)
bind_port=$(nvram get dns_forwarder_port)
server=$(nvram get dns_forwarder_server)

func_start(){
	start-stop-daemon -S -b -x $BIN -- -b "$bind_address" -p "$bind_port" -s "$server"
 	logger -t "DNSForwarder" "已经启动！"
}

func_stop(){
	killall -q dns-forwarder
 	logger -t "DNSForwarder" "已经停止！"
}

case "$1" in
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
    echo "Usage: $0 { start | stop | restart }"
    exit 1
    ;;
esac

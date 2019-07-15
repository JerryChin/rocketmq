#!/bin/bash

#此脚本的全路径
daemon_scrip=$(readlink -f $0)

#工作目录, 即此脚本所在的目录,
work_dir=$(dirname ${daemon_scrip})

daemon_log=$work_dir/daemon.log

start_script=$work_dir/start.sh

flag="background"

if [[ "$1" != "stop" && "$1" != "start" && "$1" != "status" ]] ; then
	echo "failed, miss param"
	echo "usage ./daemon.sh start|stop|status"
	exit
fi

if [ "$1" == "stop" ] ; then
	daemon_pid=`ps -C "bash" -f --width 1000 | grep -E "$daemon_scrip\s+start\s+$flag" | awk '{print $2}'`
	echo "daemon pid: $daemon_pid"
	if [ -z "$daemon_pid" ] ; then
		echo "daemon not running, do nothing"
	else
		echo "daemon is running, try to stop it..."
		kill -9 $daemon_pid
	fi
	echo "success"
	exit 0
elif [ "$1" == "status" ] ; then
	daemon_pid=`ps -C "bash" -f --width 1000 | grep -E "$daemon_scrip\s+start\s+$flag" | awk '{print $2}'`
	if [ -z "$daemon_pid" ] ; then
		echo "[WARN] daemon not running"
	else
		echo "[OK] daemon is running"
	fi
	exit
else
	if [ "$2" == "$flag" ] ; then
		echo "starting..."
		while true
		do
			sleep 60
			start_pid=`ps -C java -f --width 1000 | grep "$start_script" | awk '{print $2}'`
			if [ -z "$start_pid" ] ; then
				echo "[`date`] detected: $start_script not running, try to start again" >>$daemon_log
				bash $start_script
			else
				echo "$start_script is running"
			fi
		#检查my.pid中的进程是否在运行
		done
	else
		daemon_pid=`ps -C "bash" -f --width 1000 | grep -E "$daemon_scrip\s+start\s+$flag" | awk '{print $2}'`
		if [ ! -z "$daemon_pid" ] ; then
			echo "$daemon_scrip is running, stop first!!!!"
			exit 1
		fi
		echo "starting..."
		nohup bash $daemon_scrip "$1" "$flag" >/dev/nul &
		sleep 1
		daemon_pid=`ps -C "bash" -f --width 1000 | grep -E "$daemon_scrip\s+start\s+$flag" | awk '{print $2}'`
		if [ -z "$daemon_pid" ] ; then
			echo "start failed"
		else
			echo "start success"
		fi
	fi
fi
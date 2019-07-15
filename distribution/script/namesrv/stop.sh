#!/bin/sh

stop_script=$(readlink -f $0)
echo "stop scrip path: $stop_script"

work_dir=$(dirname ${stop_script})
echo "work dir: $work_dir"

start_script=$work_dir/start.sh
echo "start script path: $start_script"

daemon_script=$work_dir/daemon.sh
echo "daemon script path: $daemon_script"

bash $daemon_script "stop"

pid=`ps -C java -f --width 1000| grep "$start_script" | awk '{print $2}'`
if [ -z "$pid" ] ; then
        echo "$start_script is not running, do nothing!!!"
        exit 0
else
        echo "$start_script is running, pid: ${pid}, stopping..."
fi

kill -15 $pid

while kill -0 $pid  2>/dev/null ; do
    printf '.'
    sleep 1
done

printf '\n'

pid=`ps -C java -f --width 1000| grep "$start_script" | awk '{print $2}'`
if [ -z "$pid" ] ; then
        echo "stop success"
else
        echo "error: stop failed!!!!!!"
fi
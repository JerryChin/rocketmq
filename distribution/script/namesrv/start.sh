#!/bin/sh

start_script=$(readlink -f $0)
echo "scrip path: $start_script"

#工作目录, 即此脚本所在的目录,
work_dir=$(dirname ${start_script})
echo "work dir: $work_dir"

#存储pid的文件
pid_file=$work_dir/my.pid
echo "pid file: $pid_file"

daemon_script=$work_dir/daemon.sh

conf_file=$work_dir/conf/namesrv.conf
echo "conf file: $conf_file"

#存储java垃圾回收的日志
gc_log_file=$work_dir/gc.log
echo "java gc log file: $gc_log_file"

#jvm启动参数, 文档https://docs.oracle.com/cd/E19159-01/819-3681/6n5srlhqs/index.html
# -server 服务器模式, 开启这个参数之后, 可以启用-X之类的jvm配置
# -Xmx<size> 设置最大 Java 堆大小
# -Xms<size> 设置初始 Java 堆大小, 在服务器上, 一般设置成与-Xmx一样大, 防止影响效率
# -Xmn<size> 年轻代的大小, 官网资料上没这参数, 只有百度上N年前的文章才有这玩意, 不再使用
# -XX:NewRatio=N 年老代与年轻代内存大小比率, 默认为2, 即2:1
# -MaxPermSize 持久代的大小, jdk8已经弃用这个参数了, 不需要设置. 好像这块内存使用的是
#              虚拟机堆外的内存
# -XX:SurvivorRatio=N Eden区与单个Survivor区的比率大小, 默认为8, 即8:1. Eden区与Survivor共同组成年轻代
#            当Eden满,导致allocate失败时, 将进行Minor GC, 将生存下来的对象移动到survivor区.
#            survivor区分为两部分s1, s2, 在进行Minor GC时, survivor中的对象会在两个s1,s2之间移动.
#            经过多次移动仍存活的对象(MaxTenuringThreshold), 将被移动到年老代,  如果年老代满, 则
#            进行Major GC(耗时较长).
# -XX:MaxTenuringThreshold=N 对象在s1区与s2区交换N次后, 移动到年老代.
# -XX:+UseConcMarkSweepGC 开启并行垃圾回收
# -Xloggc:<filename> 将垃圾回收日志打印到文件
# -XX:+PrintGCDetails 开启垃圾回收日志
# -XX:+PrintGCTimeStamps 打印时间
# -XX:NumberOfGClogFiles=3  日志文件数量
#
JAVA_OPTS="-server -Xmx200m -Xmx200m  \
-Xloggc:${gc_log_file} \
-XX:MaxGCPauseMillis=250 -XX:SurvivorRatio=2 -XX:NewRatio=2 \
-XX:+PrintFlagsFinal -XX:ParallelGCThreads=4 -XX:MaxTenuringThreshold=15 -XX:+UseConcMarkSweepGC \
-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=3 -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:GCLogFileSize=2048K "
echo "java opt: $JAVA_OPTS"

#gc的日志时间戳使用北京时间, 使用GMT+8没有效果
export TZ="Asia/Shanghai"

#使用-D定义的java系统变量
#用于进程判断, 没有其它作用
JAVA_ARGS=" -Duser.timezone=GMT+8 -Djava.awt.headless=true -Dscript=$start_script"
echo "args: $JAVA_ARGS"

export JAVA_OPTS+=${JAVA_ARGS}


pid=`ps -C java -f --width 1000| grep "$start_script" | awk '{print $2}'`
if [ -z "$pid" ] ; then
        echo "$start_script is not running, try to start...."
else
        echo "$start_script is running, please stop it first!!!!"
        exit 1
fi


if [ "$1" = "debug" ] ; then
bin/mqnamesrv -c $conf_file
echo "stopped!!!"
exit 0
else
rm -rf ${pid_file}
nohup bin/mqnamesrv -c $conf_file &
sleep 1
fi

pid=`ps -C java -f --width 1000| grep "$start_script" | awk '{print $2}'`
echo "started , pid: $pid"
echo $pid >$pid_file

#禁止被oom杀死
echo -17 > /proc/$pid/oom_adj

#要求oom 关闭导致OOM的进程
echo 1 > /proc/sys/vm/oom_kill_allocating_task

echo "start daemon"
bash $daemon_script "start"
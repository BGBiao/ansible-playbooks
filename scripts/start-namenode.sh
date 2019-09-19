#!/bin/bash
su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start namenode'

sleep 3
su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start zkfc'
sleep 3
su - hadoop -c 'sh /opt/app/hadoop/sbin/yarn-daemon.sh start resourcemanager'
sleep 3
su - hadoop -c 'sh /opt/app/hbase/bin/hbase-daemon.sh start hmaster'

# restart the ganglia and jmxtrans
#systemctl restart gmond gmetad httpd
#systemctl restart jmxtrans

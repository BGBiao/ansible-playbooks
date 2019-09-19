#!/bin/bash
su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start journalnode'
sleep 3
su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start datanode'
sleep 3

su - hadoop -c 'sh /opt/app/hadoop/sbin/yarn-daemon.sh start nodemanager'
sleep 3
su - hadoop -c 'sh /opt/app/hbase/bin/hbase-daemon.sh start regionserver'

systemctl restart gmond
systemctl restart jmxtrans

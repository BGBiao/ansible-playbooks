## ganglia监控Hbase和Hadoop

###  安装ganglia集群监控

```
# master节点
$ yum install ganglia-web ganglia-gmetad ganglia-gmond -y

$ # cat  /etc/ganglia/gmetad.conf  | grep data_source | grep -v ^#
data_source "haiwaiim-hbase" localhost

$ systemctl restart gmond gmetad httpd

$ cat /etc/httpd/conf.d/ganglia.conf
#
# Ganglia monitoring system php web frontend
#

Alias /ganglia /usr/share/ganglia

<Location /ganglia>
   Options FollowSymLinks
   Require all granted
   AllowOverride None
   Order deny,allow
   Allow from all
   Satisfy all
  #Require local
  # Require ip 10.1.2.3
  # Require host example.org
</Location>

# 访问gmetad的localhost/ganglia


# node节点
yum install ganglia-gmond -y

# 配置每个node节点的gmond.conf 将自己的监控数据通过gmond的8649上报的gmtead的8049端口


# 部署每个gmond节点
## 需要制定gmetadip和cluster
$ ansible-playbook -i hosts -e host=all hbase-ganglia.yml



```

### 配置Hadoop监控


```
# 同步hadoop和hbase的ganglia配置
$  ansible-playbook -i hosts -e host=all hbase-ganglia.yml --tags=config

cat hadoop-metrics2.properties | grep -v ^# | grep -v ^$
*.sink.file.class=org.apache.hadoop.metrics2.sink.FileSink
*.period=10
namenode.sink.ganglia.servers=10.0.0.226:8649,10.0.0.227:8649
datanode.sink.ganglia.servers=10.0.0.226:8649,10.0.0.227:8649
resourcemanager.sink.ganglia.servers=10.0.0.226:8649,10.0.0.227:8649
nodemanager.sink.ganglia.servers=10.0.0.226:8649,10.0.0.227:8649
mrappmaster.sink.ganglia.servers=10.0.0.226:8649,10.0.0.227:8649
jobhistoryserver.sink.ganglia.servers=10.0.0.226:8649,10.0.0.227:8649


# 挨个重启一遍

sh /opt/app/hadoop/sbin/hadoop-daemon.sh stop namenode && sh /opt/app/hadoop/sbin/hadoop-daemon.sh start  namenode
sh /opt/app/hadoop/sbin/hadoop-daemon.sh stop datanode && sh /opt/app/hadoop/sbin/hadoop-daemon.sh start  datanode

```

### 配置Hbase监控


```

$ cat /opt/app/hbase/conf/hadoop-metrics2-hbase.properties
*.sink.ganglia.class=org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31
*.sink.ganglia.period=10
hbase.sink.ganglia.period=10
hbase.sink.ganglia.servers=10.0.0.226:8649 



# 挨个重启一遍
sh /opt/app/hbase/bin/hbase-daemon.sh stop  master && sh /opt/app/hbase/bin/hbase-daemon.sh start  master
sh /opt/app/hbase/bin/hbase-daemon.sh stop  regionserver && sh /opt/app/hbase/bin/hbase-daemon.sh start  regionserver
```

`注意:在配置完hbase和hadoop的监控后，除了要重启hadoop和hbase，gmond也需要进行重启才能生效`

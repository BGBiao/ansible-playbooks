## hadoop基础监控

**准备工作**

```
# 被控主机生成公私钥
$ ansible -i hosts all -m ping -k
$ ansible -i hosts all -m shell -a 'ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa' -k

# 扫描key认证信息到主控端
$ ssh-keyscan `cat hosts` >> /root/.ssh/known_hosts

# 生成认证key
ansible -i hosts all -m authorized_key -a "user=root state=present key=\"{{ lookup('file    ', '/root/.ssh/id_rsa.pub') }}\"" -k


# 测试免密执行
$ ansible -i hosts all -m ping
```



### Hadoop 集群的基础监控

`注意:Hadoop集群的基础监控使用prometheus的node_exporter进行监控`

```
http://172.29.202.140/soul/docker-18.09.6.tgz

registry.cn-hangzhou.aliyuncs.com/bj-ops/node-exporter:190730

ansible -i hosts  all -m shell -a "docker pull registry.cn-hangzhou.aliyuncs.com/bj-ops/node-exporter:190730"
ansible -i hosts  all -m shell -a "docker run -itd --name prometheus-node  --restart=always --net=host --pid=host -v '/:/host:ro,rslave' registry.cn-hangzhou.aliyuncs.com/bj-ops/node-exporter:190730 --path.rootfs /host"
ansible -i hosts  all -m shell -a "docker ps -l && curl localhost:9100/metrics"



cat hosts  | grep -oP '(\d{1,3}\.){1,3}(\d{1,3})'
10.0.0.226
10.0.0.227
10.0.0.228
10.0.0.229
10.0.0.230

```

### HDFS集群监控

`注意:HDFS集群的监控将采用hdfs-web本身提供的jmx进行暴露端口服务`

`http://10.0.0.226:50070/jmx`


### HBase集群监控

`注意:Hbase集群的监控将采用hbase的jmx暴露的指标进行监控数据`
	
`http://10.0.0.226:16010/jmx`

采用`jmxtrans+influxdb+grafana监控hbase数据`

`注意:jmxtrans默认是一分钟采一次样`

```
# hbase中需要暴露jmx端口(master:10101 region:10102)
cat hbase-conf/hbase-env.sh
#!/bin/bash
export JAVA_HOME=/opt/servers/jdk1.8.0_191
export HBASE_MANAGES_ZK=false
export HBASE_OPTS="$HBASE_OPTS -XX:+UseConcMarkSweepGC"

export HBASE_HEAPSIZE=5G

export HBASE_JMX_BASE="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10101"
export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10102"
export HBASE_THRIFT_OPTS="$HBASE_THRIFT_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10103"
export HBASE_ZOOKEEPER_OPTS="$HBASE_ZOOKEEPER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10104"
export HBASE_REST_OPTS="$HBASE_REST_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10105"
export HBASE_LIBRARY_PATH=/opt/servers/hadoop-2.7.7/lib/native/


# master 的jmx端口为10101(hmaster部署在namenode节点)
ansible-playbook -i hosts -e host=namenode -e role=master -e jmxport=10101 hbase-monitor.yml --tags=config

# region 的jmx端口为10102(hregionserver部署在datanode节点)
ansible-playbook -i hosts -e host=datanode -e role=region -e jmxport=10102 hbase-monitor.yml

# influxdb查看数据

> use hbase;
Using database hbase
> select numRegionServers,hostname from hbase_master_server  where hostname = '10.10.4.226';
name: hbase_master_server
time                     numRegionServers hostname
----                     ---------------- --------
2019-07-30T12:19:50.106Z 3                10.10.4.226
2019-07-30T12:20:50.028Z 3                10.10.4.226
2019-07-30T12:23:16.897Z 3                10.10.4.226
2019-07-30T12:24:16.832Z 3                10.10.4.226
2019-07-30T12:25:16.824Z 3                10.10.4.226
2019-07-31T01:34:18.363Z 3                10.10.4.226
2019-07-31T01:35:18.295Z 3                10.10.4.226
2019-07-31T01:36:18.294Z 3                10.10.4.226
2019-07-31T01:37:18.294Z 3                10.10.4.226
2019-07-31T01:38:18.295Z 3                10.10.4.226
2019-07-31T01:39:18.299Z 3                10.10.4.226
2019-07-31T01:40:18.297Z 3                10.10.4.226
2019-07-31T01:41:18.294Z 3                10.10.4.226
2019-07-31T01:42:18.293Z 3                10.10.4.226
2019-07-31T01:43:18.294Z 3                10.10.4.226
2019-07-31T01:44:18.293Z 3                10.10.4.226
2019-07-31T01:45:18.292Z 3                10.10.4.226
2019-07-31T01:46:18.298Z 3                10.10.4.226
2019-07-31T01:47:18.292Z 3                10.10.4.226
2019-07-31T01:48:18.291Z 3                10.10.4.226
2019-07-31T01:49:18.293Z 3                10.10.4.226
>


```

### ganglia 监控

`注意:修改gmetadip和cluster两个信息`

```
# 全局配置
ansible-playbook -i hosts -e host=all hbase-ganglia.yml

# 配置master节点
yum install ganglia-web ganglia-gmetad ganglia-gmond -y
systemctl restart gmond gmetad httpd
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

systemctl restart httpd 




ansible -i hosts all -m shell -a "systemctl restart gmond"

# 访问gmetad的localhost/ganglia 即可看到整个hbase的基本信息

由于hbase和hadoop的监控已经嵌入进去了可以直接使用
```

`注意:script脚本中增加namenode节点和datanode节点的重启脚本`

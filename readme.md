## 使用Ansible快速部署高可用Hbase集群

`注意:Hbase是建立在HDFS纸上的分布式NoSQL数据库，因此各个节点需要部署在已有的Hadoop节点上`


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


**节点规划**

节点 | Hadoop角色 | Hbase角色
--- | --- | --- 
namenode1 | namenode,resourcemanager,zkfc | Hmaster
namenode2 | namenode,resourcemanager,zkfc | Hmaster
datanode1 | datanode,journalnode,nodemanager | HRegionserver
datanode2 | datanode,journalnode,nodemanager | HRegionserver
datanode3 | datanode,journalnode,nodemanager | HRegionserver




**ansible-playbooks初始化集群**

`注意:修改几个地方download_url,zk_cluster,zk_cluster_endpoints`

```
# 初始化集群
$ ansible-playbook -i hosts -e host=all hbase-install.yml
....
....
....

# 查看hbase环境
ansible -i hosts all -m shell -a "ls -l /opt/app/hbase"

```


**启动Hbase集群**


`注意:start-hbase.sh 用来启动整个集群,因为免密配置了`

```
$ ansible -i hosts master[0] -m shell -a "su - hadoop -c 'sh /opt/app/hbase/bin/start-hbase.sh'"
172.29.202.143 | CHANGED | rc=0 >>
running master, logging to /opt/app/hbase/logs/hbase-hadoop-master-namenode1.out
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/opt/servers/hadoop-2.7.7/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/opt/servers/hbase-2.1.5/lib/client-facing-thirdparty/slf4j-log4j12-1.7.25.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]
datanode3: running regionserver, logging to /opt/app/hbase/bin/../logs/hbase-hadoop-regionserver-datanode3.out
datanode1: running regionserver, logging to /opt/app/hbase/bin/../logs/hbase-hadoop-regionserver-namenode2.out
datanode2: running regionserver, logging to /opt/app/hbase/bin/../logs/hbase-hadoop-regionserver-datanode2.out
namenode2: running master, logging to /opt/app/hbase/bin/../logs/hbase-hadoop-master-namenode2.outSLF4J: Class path contains multiple SLF4J bindings.

```

`注意:可以看到在master节点启动之后，会默认将backup master和regionserver全部启动成功`

当前可以访问http://namenode1:16010/ 和http://namenode2:16010/查看hbase集群服务

```
# 查看集群状态
$ ansible -i hbase all -m shell -a "su - hadoop -c 'jps' | grep -E '(HRegionServer|HMaster)'"

```

**测试Hbase集群使用**

```
[hadoop@namenode2 ~]$ hbase shell
.....
Took 0.0019 seconds
# 查看hbase库表
hbase(main):001:0> list
TABLE
0 row(s)
Took 0.4220 seconds
=> []
# 创建表't1'
hbase(main):002:0> create 't1', {NAME => 'f1', VERSIONS => 1}, {NAME => 'f2', VERSIONS => 1}, {NAME => 'f3', VERSIONS => 1}
Created table t1
Took 1.4698 seconds
=> Hbase::Table - t1
hbase(main):003:0> list
TABLE
t1
1 row(s)
Took 0.0114 seconds
=> ["t1"]
# 向表't1'中插入数据
hbase(main):004:0> put 't1', 'r2', 'f2', 'v2'
Took 0.2000 seconds
hbase(main):005:0> put 't1', 'r3', 'f3', 'v3'
Took 0.0090 seconds
# 扫描表't1'中的数据
hbase(main):006:0> scan 't1'
ROW                            COLUMN+CELL
 r2                            column=f2:, timestamp=1564380876616, value=v2
 r3                            column=f3:, timestamp=1564380880884, value=v3
2 row(s)

# 手工吧memstore写入hfile
hbase(main):002:0> flush 't1'
Took 0.5676 seconds

# 删除hbase中的表(先disable再drop)
hbase(main):003:0> disable 't1'
Took 0.5558 seconds
hbase(main):004:0> drop 't1'
Took 0.4486 seconds


```


**Phoenix插件安装**

`注意1:Phoenix需要将源码包中的phoenix-5.0.0-HBase-2.0-server.jar 包拷贝到Hbase的lib路径下，然后重启HBase集群`

`注意2:由于hbase集群中默认已经配置了phoenix相关包，因此可以直接进行使用`

```
# 整个集群仅需三步即可完整构建
ansible-playbook -i hosts -e host=all hbase-install.yml
ansible -i hosts master[0] -m shell -a "su - hadoop -c 'sh /opt/app/hbase/bin/start-hbase.sh'"
ansible -i hosts all -m shell -a "ps -ef | grep -E '(HMaster|HRegionServer)' | grep -v grep "

# 测试使用Phoenix(使用phoenix提供的脚本，链接zk实例即可登录)
[hadoop@namenode1 ~]$ /opt/servers/apache-phoenix-5.0.0-HBase-2.0-bin/bin/sqlline.py localhost:2181
.......
.......
Done
sqlline version 1.2.0
0: jdbc:phoenix:localhost:2181> !tables
+------------+--------------+-------------+---------------+----------+------------+----------------------------+------+
| TABLE_CAT  | TABLE_SCHEM  | TABLE_NAME  |  TABLE_TYPE   | REMARKS  | TYPE_NAME  | SELF_REFERENCING_COL_NAME  | REF_ |
+------------+--------------+-------------+---------------+----------+------------+----------------------------+------+
|            | SYSTEM       | CATALOG     | SYSTEM TABLE  |          |            |                            |      |
|            | SYSTEM       | FUNCTION    | SYSTEM TABLE  |          |            |                            |      |
|            | SYSTEM       | LOG         | SYSTEM TABLE  |          |            |                            |      |
|            | SYSTEM       | SEQUENCE    | SYSTEM TABLE  |          |            |                            |      |
|            | SYSTEM       | STATS       | SYSTEM TABLE  |          |            |                            |      |
+------------+--------------+-------------+---------------+----------+------------+----------------------------+------+
0: jdbc:phoenix:localhost:2181> create table user(id varchar primary key,name varchar,age varchar,phone varchar,email varchar);
No rows affected (1.342 seconds)
0: jdbc:phoenix:localhost:2181> select  * from user;
+-----+-------+------+--------+--------+
| ID  | NAME  | AGE  | PHONE  | EMAIL  |
+-----+-------+------+--------+--------+
+-----+-------+------+--------+--------+
No rows selected (0.125 seconds)
0: jdbc:phoenix:localhost:2181> upsert into user values('1001','biaoge','26','18209247280','bgbiao@xxx.com');
1 row affected (0.019 seconds)
0: jdbc:phoenix:localhost:2181> select  * from user;
+-------+---------+------+--------------+-----------------+
|  ID   |  NAME   | AGE  |    PHONE     |      EMAIL      |
+-------+---------+------+--------------+-----------------+
| 1001  | biaoge  | 26   | 18209247280  | bgbiao@xxx.com  |
+-------+---------+------+--------------+-----------------+
1 row selected (0.055 seconds)
0: jdbc:phoenix:localhost:2181>

```

**查看Phoenix相关数据**

```
# hbase查看数据
$ hbase shell
.....
.....
hbase(main):012:0* scan 'USER'
ROW                            COLUMN+CELL

ERROR: Unknown table user!

For usage try 'help "scan"'

Took 0.1109 seconds
ROW                            COLUMN+CELL
 1001                          column=0:\x00\x00\x00\x00, timestamp=1564381973090, value=x
 1001                          column=0:\x80\x0B, timestamp=1564381973090, value=biaoge
 1001                          column=0:\x80\x0C, timestamp=1564381973090, value=26
 1001                          column=0:\x80\x0D, timestamp=1564381973090, value=18209247280
 1001                          column=0:\x80\x0E, timestamp=1564381973090, value=bgbiao@xxx.com
1 row(s)
Took 0.0653 seconds
ROW                            COLUMN+CELL
 1001                          column=0:\x00\x00\x00\x00, timestamp=1564381973090, value=x
 1001                          column=0:\x80\x0B, timestamp=1564381973090, value=biaoge
 1001                          column=0:\x80\x0C, timestamp=1564381973090, value=26
 1001                          column=0:\x80\x0D, timestamp=1564381973090, value=18209247280
 1001                          column=0:\x80\x0E, timestamp=1564381973090, value=bgbiao@xxx.com

# hdfs查看数据
$ hdfs dfs -ls /hbase/data/hbase/meta
Found 3 items
drwxr-xr-x   - hadoop supergroup          0 2019-07-29 14:09 /hbase/data/hbase/meta/.tabledesc
drwxr-xr-x   - hadoop supergroup          0 2019-07-29 14:09 /hbase/data/hbase/meta/.tmp
drwxr-xr-x   - hadoop supergroup          0 2019-07-29 14:33 /hbase/data/hbase/meta/1588230740

```


**注意:hbase的pheonix需要拷贝一个包(拷贝到phoenix包到hbase的家目录)**

```
  - name: "copy the {{ plugin }} to the {{ app }}"
    copy:
      src: "{{ item.src }}"
      dest: "{{ item.dest }}"
      mode: 0755
      owner: hadoop
      group: hadoop
    with_items:
      - { src: "phoenix/phoenix-5.0.0-HBase-2.0-server.jar", dest: "{{ appdir }}{{ app }}/lib/phoenix-5.0.0-HBase-2.0-server.jar" }

```


## 使用ansible快速安装Hadoop高可用集群

**注意事项:**
- 1: hadoop集群推荐使用`普通用户`创建
- 2: 集群之间需要使用普通用户免密登录
- 3: 集群之间各个节点需要通过域名解析
- 4: hadoop-2.7.7的snappy压缩库有问题，需要重新编译对应的库
- 5: 一般hadoop都会使用外置盘进行hdfs的承载

`注意:使用本ansible-playbook快速部署hadoop集群，仅需要修改如下参数即可快速创建`

```
# vars/varsfile.yml 文件
download_url: 为内网http服务，主要供各个节点进行下载相关的软件包，比如jdk,hadoop等相关版本的包
cluster_name: hadop集群名称
zk_cluster: zk集群信息(ip:port,ip:port,ip:port)
namenodeN: namenode节点ip
datanodeN: datanode节点ip
```


### 初始化Ansible环境

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



### 集群初始化

```
# 统一格式化分区并挂载到新分区上
$ ansible -i hadoop datanode -m shell -a "echo -e 'm\nn\np\n\n\n\nt\n83\np\nw\nq\n' | fdisk /dev/vdb && mkfs.ext4 /dev/vdb1 && mkdir /data && mount /dev/vdb1 /data"

# 使用uuid挂载到/etc/fstab
$ blkid /dev/vdb1


# 使用ansible-playbooks进行统一管理和下发集群配置
$ ansible-playbook -i hadoop -e host=all hadoop-install.yml

# 设置主机名
$ ansible -i hadoop  namenode[0] -m shell -a "hostnamectl set-hostname namenode1"
$ ansible -i hadoop  namenode[1] -m shell -a "hostnamectl set-hostname namenode2"
$ ansible -i hadoop  datanode[0] -m shell -a "hostnamectl set-hostname datanode1"
$ ansible -i hadoop  datanode[1] -m shell -a "hostnamectl set-hostname datanode2"
$ ansible -i hadoop  datanode[2] -m shell -a "hostnamectl set-hostname datanode3"

# 创建hadoop用户，并设置集群内部hadoop用户免密登录
$ ansible -i hosts all -m shell -a "useradd hadoop && echo 'hadoop:123456' | passwd --stdin hadoop"

# 拷贝公钥(在单个节点上执行)
$ scp namenode1:~/.ssh/id_rsa.pub .
$ cat id_rsa.pub >> ~/.ssh/authorized_keys
$ scp namenode2:~/.ssh/id_rsa.pub .
$ cat id_rsa.pub >> ~/.ssh/authorized_keys
$ scp datanode1:~/.ssh/id_rsa.pub .
$ cat id_rsa.pub >> ~/.ssh/authorized_keys
$ scp datanode2:~/.ssh/id_rsa.pub .
$ cat id_rsa.pub >> ~/.ssh/authorized_keys
$ scp datanode3:~/.ssh/id_rsa.pub .
$ cat id_rsa.pub >> ~/.ssh/authorized_keys
$ chmod 600 .ssh/authorized_keys

# 将拥有集群全部的认证信息拷贝个集群每个节点，使之可以互相登录(将该节点上的认证信息拷贝到集群全部节点)
$ scp ~/.ssh/authorized_keys namenode1:~/.ssh/authorized_keys
$ scp ~/.ssh/authorized_keys namenode2:~/.ssh/authorized_keys
$ scp ~/.ssh/authorized_keys datanode1:~/.ssh/authorized_keys
$ scp ~/.ssh/authorized_keys datanode2:~/.ssh/authorized_keys
$ scp ~/.ssh/authorized_keys datanode3:~/.ssh/authorized_keys
```

### 启动hadoop集群

**0. 格式化zk节点**

```
# 在namenode1节点上的hadoop用户下执行
$ hdfs zkfc -formatZK
19/07/21 16:10:27 INFO tools.DFSZKFailoverController: Failover controller configured for NameNode NameNode at namenode1/172.29.202.143:8020
19/07/21 16:10:27 INFO zookeeper.ZooKeeper: Client environment:zookeeper.version=3.4.6-1569965, built on 02/20/2014 09:09 GMT
19/07/21 16:10:27 INFO zookeeper.ZooKeeper: Client environment:host.name=namenode1
19/07/21 16:10:27 INFO zookeeper.ZooKeeper: Client environment:java.version=1.8.0_191
19/07/21 16:10:27 INFO zookeeper.ZooKeeper: Client environment:java.vendor=Oracle Corporation
......
......
19/07/21 16:10:27 INFO zookeeper.ClientCnxn: Session establishment complete on server 172.29.202.143/172.29.202.143:2181, sessionid = 0x1004d210ce00001, negotiated timeout = 15000
19/07/21 16:10:27 INFO ha.ActiveStandbyElector: Successfully created /hadoop-ha/bgbiao in ZK.
...

# 看到在zk中成功创建了/hadoop-ha/bgbiao 即成功
```

**1. 启动journalnode**

`注意:journalnode是负载同步整个edits文件的，集群高可用的保障，需要优先启动`

我们配置的是`datanode1,datanode2,datanode3`为journalnode节点，分别登录节点使用Hadoop用户进行启动

```
# datanode1
[hadoop@datanode1 ]$ sh /opt/app/hadoop/sbin/hadoop-daemon.sh start journalnode
starting journalnode, logging to /opt/app/hadoop/logs/hadoop-hadoop-journalnode-datanode1.out

# datanode2
[hadoop@datanode2 ~]$ sh /opt/app/hadoop/sbin/hadoop-daemon.sh start journalnode
starting journalnode, logging to /opt/app/hadoop/logs/hadoop-hadoop-journalnode-datanode2.out

# datanode3
[hadoop@datanode3 ~]$ sh /opt/app/hadoop/sbin/hadoop-daemon.sh start journalnode
starting journalnode, logging to /opt/app/hadoop/logs/hadoop-hadoop-journalnode-datanode3.out

# 检查journalnode启动状态
$ ansible -i hadoop all -m shell -a " su - hadoop -c 'jps'"
 [WARNING]: Consider using 'become', 'become_method', and 'become_user' rather than running su

172.29.202.143 | CHANGED | rc=0 >>
4033 Jps

172.29.202.149 | CHANGED | rc=0 >>
25300 Jps
24445 JournalNode

172.29.202.145 | CHANGED | rc=0 >>
3030 Jps
2199 JournalNode

172.29.202.148 | CHANGED | rc=0 >>
2203 JournalNode
3019 Jps
```


**2. 节点格式化操作(namenode)**

`注意:临时目录hadoop.tmp.dir需要创建`
`注意:在namenode1节点上进行格式化操作(格式化的时候需要连接journalnode进程)`

```
# 在namenode1节点上以hadoop用户格式化hdfs
[hadoop@namenode1 ]$ hdfs namenode -format
19/07/21 16:25:23 INFO namenode.NameNode: STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting NameNode
STARTUP_MSG:   host = namenode1/172.29.202.143
STARTUP_MSG:   args = [-format]
STARTUP_MSG:   version = 2.7.7
.......
.......
19/07/21 16:25:24 INFO util.ExitUtil: Exiting with status 0
19/07/21 16:25:24 INFO namenode.NameNode: SHUTDOWN_MSG:
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at namenode1/172.29.202.143
************************************************************/
```

**3. 启动hadoop集群**

```
# 启动datanode节点
[hadoop@datanode1 ~]$ sh /opt/app/hadoop/sbin/hadoop-daemon.sh start datanode
starting datanode, logging to /opt/app/hadoop/logs/hadoop-hadoop-datanode-datanode1.out

[hadoop@datanode2 ~]$ sh /opt/app/hadoop/sbin/hadoop-daemon.sh start datanode
starting datanode, logging to /opt/app/hadoop/logs/hadoop-hadoop-datanode-datanode2.out

[hadoop@datanode3 ~]$ sh /opt/app/hadoop/sbin/hadoop-daemon.sh start datanode
starting datanode, logging to /opt/app/hadoop/logs/hadoop-hadoop-datanode-datanode3.out

# 或者直接使用ansible批量启动
ansible -i hadoop datanode -m shell -a "su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start datanode'"
 [WARNING]: Consider using 'become', 'become_method', and 'become_user' rather than running su

172.29.202.148 | CHANGED | rc=0 >>
starting datanode, logging to /opt/app/hadoop/logs/hadoop-hadoop-datanode-datanode2.out

172.29.202.145 | CHANGED | rc=0 >>
starting datanode, logging to /opt/app/hadoop/logs/hadoop-hadoop-datanode-datanode3.out

172.29.202.149 | CHANGED | rc=0 >>
starting datanode, logging to /opt/app/hadoop/logs/hadoop-hadoop-datanode-datanode1.out

# 检查datanode进程
$ ansible -i hadoop datanode -m shell -a "su - hadoop -c 'jps'"

172.29.202.145 | CHANGED | rc=0 >>
2199 JournalNode
3162 DataNode
3294 Jps

172.29.202.149 | CHANGED | rc=0 >>
25432 DataNode
25564 Jps
24445 JournalNode

172.29.202.148 | CHANGED | rc=0 >>
3283 Jps
2203 JournalNode
3151 DataNode

# 启动namenode1
ansible -i hadoop namenode[0] -m shell -a "su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start namenode'"
172.29.202.143 | CHANGED | rc=0 >>
starting namenode, logging to /opt/app/hadoop/logs/hadoop-hadoop-namenode-dev-k8s-4.out

# 启动namenode2的bootstrap进程

$ ansible -i hadoop namenode[1] -m shell -a "su - hadoop -c 'hdfs namenode  -bootstrapStandby'"
172.29.202.145 | CHANGED | rc=0 >>
=====================================================
About to bootstrap Standby ID nn2 from:
           Nameservice ID: bgbiao
        Other Namenode ID: nn1
  Other NN's HTTP address: http://namenode1:50070
  Other NN's IPC  address: namenode1/172.29.202.143:8020
             Namespace ID: 328470975
            Block pool ID: BP-1668981010-172.29.202.143-1563697524487
               Cluster ID: CID-d06ff340-3c53-421b-93d7-6c635ef3b20d
           Layout version: -63
       isUpgradeFinalized: true
=====================================================19/07/21 16:32:55 INFO namenode.NameNode: STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting NameNode
STARTUP_MSG:   host = namenode2/172.29.202.145
STARTUP_MSG:   args = [-bootstrapStandby]
STARTUP_MSG:   version = 2.7.7
......
......
************************************************************/
19/07/21 16:32:55 INFO namenode.NameNode: registered UNIX signal handlers for [TERM, HUP, INT]
19/07/21 16:32:55 INFO namenode.NameNode: createNameNode [-bootstrapStandby]
19/07/21 16:32:56 INFO common.Storage: Storage directory /data/hadoop/hdfs/name has been successfully formatted.
19/07/21 16:32:56 INFO namenode.TransferFsImage: Opening connection to http://namenode1:50070/imagetransfer?getimage=1&txid=0&storageInfo=-63:328470975:0:CID-d06ff340-3c53-421b-93d7-6c635ef3b20d
19/07/21 16:32:56 INFO namenode.TransferFsImage: Image Transfer timeout configured to 60000 milliseconds
19/07/21 16:32:56 INFO namenode.TransferFsImage: Transfer took 0.00s at 0.00 KB/s
19/07/21 16:32:56 INFO namenode.TransferFsImage: Downloaded file fsimage.ckpt_0000000000000000000 size 323 bytes.
19/07/21 16:32:56 INFO util.ExitUtil: Exiting with status 0
19/07/21 16:32:56 INFO namenode.NameNode: SHUTDOWN_MSG:
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at namenode2/172.29.202.145
************************************************************/

# 可以看到此时namenode2已经设置了bootstrapStandby

# 此时启动namenode2
$ ansible -i hadoop namenode[1] -m shell -a "su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start namenode'"
172.29.202.145 | CHANGED | rc=0 >>
starting namenode, logging to /opt/app/hadoop/logs/hadoop-hadoop-namenode-dev-k8s-3.out


## 注意:此时namenode1和namenode2均已启动，如果此时访问namenode1:50070和namenode2:50070会发现两个namenode均为standby角色,因为我们是HA模式，namenode初始状态为standby，需要启动zkfc来进行选举

# 在两个namenode节点启动zkfc进程
$ ansible -i hadoop namenode -m shell -a "su - hadoop -c 'sh /opt/app/hadoop/sbin/hadoop-daemon.sh start zkfc'"

172.29.202.145 | CHANGED | rc=0 >>
starting zkfc, logging to /opt/app/hadoop/logs/hadoop-hadoop-zkfc-dev-k8s-3.out

172.29.202.143 | CHANGED | rc=0 >>
starting zkfc, logging to /opt/app/hadoop/logs/hadoop-hadoop-zkfc-dev-k8s-4.out

# 此时再去查看namenodeN:50070就会发现有一个为active，另外一个为standby


```


### Hadoop集群测试使用

**1. 测试HDFS的使用**

```
[hadoop@namenode2 ~]$ hdfs dfs -ls /;
[hadoop@namenode2 ~]$ hdfs dfs -mkdir /bgbiao
[hadoop@namenode2 ~]$ hdfs dfs -ls /;
Found 1 items
drwxr-xr-x   - hadoop supergroup          0 2019-07-17 13:56 /bgbiao

[hadoop@namenode2 ~]$ hostname > hostname.txt
[hadoop@namenode2 ~]$ hdfs dfs -put hostname.txt /bgbiao/
i[hadoop@namenode2 ~]$ hdfs dfs -ls /bgbiao;
Found 1 items
-rw-r--r--   3 hadoop supergroup         10 2019-07-21 17:57 /bgbiao/hostname.txt
[hadoop@namenode2 ~]$ hdfs dfs -cat /bgbiao/hostname.txt;
namenode2

```

**2. 测试主备切换(HA)**

```
# 去namenode1上kill掉namenode进程
[hadoop@namenode1 ~]$ jps
25655 DFSZKFailoverController
25848 Jps
25484 NameNode
[hadoop@namenode1 ~]$ kill -9 25484
[hadoop@namenode1 ~]$ hdfs dfs -cat /bgbiao-sre/hostname.txt;
namenode2

[hadoop@namenode1 ~]$ hdfs dfs -ls /bgbiao-sre;
Found 1 items
-rw-r--r--   3 hadoop supergroup         10 2019-07-17 13:57 /bgbiao-sre/hostname.txt

# namenode1异常后可以进行ha切换，hdfs正常使用


```

**3. 启动resourcemanager和nodemanager**

```
# namenode节点启动resourcemanager
# datanode节点启动nodemanager
$ ansible -i hadoop namenode -m shell -a "su - hadoop -c 'sh /opt/app/hadoop/sbin/yarn-daemon.sh start resourcemanager'"
$ ansible -i hadoop namenode -m shell -a "su - hadoop -c 'sh /opt/app/hadoop/sbin/yarn-daemon.sh start nodemanager'"


```

`http://namenode1:8088/cluster/nodes`


**4.  启动historyserver**

`mapred-site.xml文件中有定义history地址`

```
[hadoop@namenode1 ~]$ sh /opt/app/hadoop/sbin/mr-jobhistory-daemon.sh start historyserver
starting historyserver, logging to /opt/app/hadoop/logs/mapred-hadoop-historyserver-namenode1.out
```

**5. 访问各个服务的页面**

NameNode: http://nn_host:port/ [default http:50070]
ResourceManager: http://rm_host:port/ [default http:8088]
MapReduce JobHistory Server: http://jhs_host:port/ [default http:19888]

**6. 运行官方的wordcount实例**

```
[hadoop@namenode1 ~]$ hdfs dfs -ls /input;
[hadoop@namenode1 ~]$ vim test-words.txt
[hadoop@namenode1 ~]$ hdfs dfs -put test-words.txt /input
[hadoop@namenode1 ~]$ hdfs dfs -ls /input;
Found 1 items
-rw-r--r--   3 hadoop supergroup         38 2019-07-17 14:31 /input/test-words.txt
[hadoop@namenode1 ~]$ hadoop jar /opt/app/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar wordcount /input /output

[hadoop@namenode1 ~]$ cat test-words.txt
bgbiao sre
bgbiao app
bgbiaoapp
hello bgbiao



[hadoop@namenode1 ~]$ hdfs dfs -ls /output;
Found 2 items
-rw-r--r--   3 hadoop supergroup          0 2019-07-17 14:32 /output/_SUCCESS
-rw-r--r--   3 hadoop supergroup         37 2019-07-17 14:32 /output/part-r-00000
[hadoop@namenode1 ~]$ hdfs dfs -cat /output/part-r-00000;
app 1
hello 1
bgbiao  3
bgbiaoapp 1
sre 1

```

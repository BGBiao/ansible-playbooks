## zk集群ansible快速搭建



### 修改相关配置

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


**1. 修改conf/zoo.cfg配置**

`注意:主要是修改server.X={IP} 用于提前规划zk节点`

```
$ cat conf/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir={{ datadir }}{{ app }}
clientPort=2181

server.1=172.29.202.143:2888:3888
server.2=172.29.202.145:2888:3888
server.3=172.29.202.148:2888:3888

```

**2. 修改vars/varfile.yml(heap_mem,download_url)**

`注意:主要是修改download_url和一些标准环境配置(根据需求改)`

```
$ cat vars/varsfile.yml
---
  heap_mem: "8"
  jmx_port: "9999"
  download_url: http://172.29.202.140/
  packagedir: /tmp/
  appdir: /opt/app/
  datadir: /opt/data/
  pkgdir: /opt/packages/
  serverdir: /opt/servers/
  jdk: jdk1.8.0_191
  app: zookeeper
  app_pkg: zookeeper-3.4.14

```

**3. 修改ansible inventry配置**

`注意:其实就是ansible需要操作的主机，也是集群节点`

```
$ cat hosts
[all]
172.29.202.143 
172.29.202.145 
172.29.202.148 

```

### 集群初始化

```
# 初始化集群环境
$ ansible-playbook -i hosts -e host=zk zk-install.yml

# 自定义集群配置
$ ansible -i hosts zk[0] -m shell -a "echo 1 > /opt/data/zookeeper/myid"
$ ansible -i hosts zk[1] -m shell -a "echo 2 > /opt/data/zookeeper/myid"
$ ansible -i hosts zk[2] -m shell -a "echo 3 > /opt/data/zookeeper/myid"

# 确认集群当前环境(确认集群节点和规划节点一直)
$ ansible -i hosts zk -m shell -a "cat /opt/data/zookeeper/myid && ls /opt/app "

```


### 启动集群并测试

`注意:由于JAVA环境是手动配置到/etc/profile的，因此需要提前source一下/etc/profile，才可以启动成功`

**启动并查看集群**

```
$ ansible -i hosts zk -m shell -a "source /etc/profile && sh /opt/app/zookeeper/bin/zkServer.sh start && source /etc/profile && sh /opt/app/zookeeper/bin/zkServer.sh status"

```

**测试使用**

```
$ ansible -i hosts zk -m shell -a "source /etc/profile && sh /opt/app/zookeeper/bin/zkCli.sh -server localhost:2181 ls / | grep -A 1 WatchedEvent"

```

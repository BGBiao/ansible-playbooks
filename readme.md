## ansible快速部署kafka集群

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

**修改核心配置**

`注意:修改var/varfile.yml中的download_url,zk_cluster,heap_mem`

```
# 部署集群
$ ansible-playbook -i hosts  -e host=all[0] -e broker_id=1 kafka-install.yml
$ ansible-playbook -i hosts  -e host=all[1] -e broker_id=2 kafka-install.yml
$ ansible-playbook -i hosts  -e host=all[2] -e broker_id=3 kafka-install.yml



# 启动并检查集群状态
$ ansible -i hosts  kafka -m shell -a "ls /opt/app/kafka && source /etc/profile && sh /opt    /app/kafka/bin/kafka-server-start.sh -daemon /opt/app/kafka/config/server.properties"
$ ansible -i hosts  kafka -m shell -a "netstat -antlp | grep 9092"


```


**测试集群**

```
kafka-topic测试
/opt/app/kafka/bin/kafka-console-producer.sh --broker-list 10.10.4.65:9092 --topic soul-test
>xbascksax
>xabsjcbas
>cbasjkcxaskxb
>xanskxnasx
sh /opt/app/kafka/bin/kafka-console-consumer.sh --bootstrap-server 10.10.4.65:9092 --topic soul-test --from-beginning
xbascksax
xabsjcbas
cbasjkcxaskxb
xanskxnasx


anskxas
^CProcessed a total of 7 messages

```

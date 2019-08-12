## es集群ansible-playbooks快速部署

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

**es集群初始化**

`注意:修改cluster_name,user,heap_mem,es_nodeNx相关配置`

`注意:使用su - user -c 'sh start.sh'这种方式user用户必须能够登陆系统(或者直接使用systemd直接进行启动)`

```
# 初始化
$ ansible-playbook -i hosts -e host=es[0] -e node_name="node1" es-install.yml --skip-tags=start
$ ansible-playbook -i hosts -e host=es[1] -e node_name="node2" es-install.yml --skip-tags=start
$ ansible-playbook -i hosts -e host=es[2] -e node_name="node3" es-install.yml --skip-tags=start

# 启动集群
$ ansible-playbook -i hosts  -e host=es es-install.yml --tags=start

# 进程检测
$ ansible -i hosts es -m shell -a "ps -ef | grep elastic | grep -v grep "



```






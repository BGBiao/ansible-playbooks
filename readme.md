## hosts二进制安装

### 准备条件

**ansible免密准备**

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

**主机初始化准备**

```
# 关闭防火墙
ansible -i hosts  all -m shell -a "systemctl stop firewalld.service && systemctl disable  firewalld.service "


# 关闭selinux
# 确保selinux为disable(/etc/selinux/config )
ansible -i hosts  all -m shell -a "setenforce 0 && getenforce"

# 配置内核参数，开启ip转发
ansible -i hosts all -m copy -a "src=./conf/hosts-sysctl.conf dest=/etc/sysctl.d/hosts-sysctl.conf "

ansible -i hosts all -m copy -a "src=./conf/ipvs.modules dest=/etc/sysconfig/modules/ipvs.modules"

ansible -i hosts  all -m shell -a "sysctl -p && chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4   "
```

**ssl证书工具**

`注意:建议证书工具在独立节点进行配置，证书进行保存和备份`

```
  991  wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
  992  wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  993  wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
  994  ls
  995  chmod a+x *
  996  echo $PATH
  997  mv cfssl_linux-amd64 /usr/local/bin/cfssl
  998  mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  999  mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo

```

### etcd集群搭建

**etcd证书管理**

- etcd证书配置

```
# etcd ca证书配置
$ cat ssl/etcd/ca-config.json
{
  "signing": {
    "default": {
      "expiry": "876000h"
    },
    "profiles": {
      "etcd": {
         "expiry": "876000h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}


# ca证书
$ cat ssl/etcd/ca-csr.json
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}

# etcd -server证书
$ cat ssl/etcd/server-csr.json
{
    "CN": "etcd",
    "hosts": [
    "172.29.202.134",
    "172.29.202.154",
    "172.29.202.174"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}


```

- etcd证书和私钥

```
# 生成证书和私钥

# 初始化ca
$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca
2019/08/04 22:29:28 [INFO] generating a new CA key and certificate from CSR
2019/08/04 22:29:28 [INFO] generate received request
2019/08/04 22:29:28 [INFO] received CSR
2019/08/04 22:29:28 [INFO] generating key: rsa-2048
2019/08/04 22:29:28 [INFO] encoded CSR
2019/08/04 22:29:28 [INFO] signed certificate with serial number 527129369490519631864135982273808457284060952812

# 生成ca-key.pem ca.pem ca.csr
$ ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem  server-csr.json


# 生成server证书
$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd server-csr.json | cfssljson -bare server
2019/08/04 22:31:57 [INFO] generate received request
2019/08/04 22:31:57 [INFO] received CSR
2019/08/04 22:31:57 [INFO] generating key: rsa-2048
2019/08/04 22:31:57 [INFO] encoded CSR
2019/08/04 22:31:57 [INFO] signed certificate with serial number 420229143794406637558944525318516857764928689607
2019/08/04 22:31:57 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").

# 生成server.csr server-key.pem  server.pem 
$ ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem  server.csr  server-csr.json  server-key.pem  server.pem

```

- etcd集群搭建

```
# 使用ansible-playbooks进行统一的集群配置安装
$ ansible-playbook -i hosts -e host=master  etcd-install.yml
....
....

# 启动etcd集群
$ ansible -i hosts master -m shell -a 'systemctl daemon-reload && systemctl start etcd && systemctl enable etcd' -f 3 

# 测试etcd集群状态
$ ansible -i hosts master -m shell -a 'etcdctl --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem --endpoints="https://172.29.202.134:2379,https://172.29.202.154:2379" cluster-health'
172.29.202.154 | CHANGED | rc=0 >>
member 38fb441aaf09e31d is healthy: got healthy result from https://172.29.202.134:2379
member dd4d87c6833f4525 is healthy: got healthy result from https://172.29.202.154:2379
member e68819022bf93a3f is healthy: got healthy result from https://172.29.202.174:2379
cluster is healthy

172.29.202.174 | CHANGED | rc=0 >>
member 38fb441aaf09e31d is healthy: got healthy result from https://172.29.202.134:2379
member dd4d87c6833f4525 is healthy: got healthy result from https://172.29.202.154:2379
member e68819022bf93a3f is healthy: got healthy result from https://172.29.202.174:2379
cluster is healthy

172.29.202.134 | CHANGED | rc=0 >>
member 38fb441aaf09e31d is healthy: got healthy result from https://172.29.202.134:2379
member dd4d87c6833f4525 is healthy: got healthy result from https://172.29.202.154:2379
member e68819022bf93a3f is healthy: got healthy result from https://172.29.202.174:2379
cluster is healthy

# 
```

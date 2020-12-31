# Let's Encrypt Cert Auto Renew
[![license](https://img.shields.io/github/license/KangSpace/lets-encrypt-cert-auto-renew)](LICENSE)

## 介绍
该项目用于实现Let's Encrypt证书签名与自动续签操作；    
目前使用Certbot客户端+DNS验证来生成通配符域名证书,支持多域名签名。

>注意签名的速率限制: [rate-limits](https://letsencrypt.org/docs/rate-limits/)

## 关于 Let's Encrypt
[Let's Encrypt](https://letsencrypt.org/)是一个免费，自动化和开放的证书颁发机构（CA），使用 ACME 协议来验证对给定域名的控制权并颁发证书；  
[官方推荐](https://letsencrypt.org/zh-cn/docs/client-options/)使用[Certbot](https://certbot.eff.org/)客户端，它易于使用，适用于许多操作系统，并且具有丰富的文档。

[Let's Encrypt](https://letsencrypt.org/)签名的证书有效期是90天，需要在3个月内至少续签一次。

## 关于 Certbot
[Certbot](https://certbot.eff.org/about/)是一个免费的开源软件工具，可用于在手动管理的网站上自动使用Let's Encrypt证书来启用HTTPS。

> Certbot的运行依赖于Python2.7+或Python3的环境

## Quick Start 快速开始
### 1. 准备环境
需准备Linux系统, Python环境,Certbot,登录DNS配置管理页。

>示例中使用的环境：  
>OS: CentOS Linux release 7.7.1908 (Core) x86_64  
>Python: Python2.7.15  
>DNS SP: Aliyun DNS

#### 1.1 安装Python环境
<code>
&gt; wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz  

&gt; tar -vxf Python-2.7.15.tgz
cd Python-2.7.15  
&gt; ./configure --prefix=/usr/local/python27  
&gt; make  
&gt; sudo make install  
&gt; cd /usr/local/python27/  
&gt; ln -s /usr/local/python27/bin/python2.7 / usr/bin/python  
&gt; sudo ln -s /usr/local/python27/bin/python2.7 /usr/bin/python  
&gt; python -V  
&gt; wget https://bootstrap.pypa.io/get-pip.py  
&gt; sudo python get-pip.py  
&gt; ln -s /usr/local/python27/bin/pip /usr/bin/pip  
&gt; sudo ln -s /usr/local/python27/bin/pip /usr/bin/pip   
//安装virsualenv  
&gt; sudo pip install virtualenv  
&gt; sudo ln -s /usr/local/python27/bin/virtualenv /usr/bin/virtualenv  
</code>

> 若系统中已存在旧版本的Python，需要将旧版本的Python重命名处理  
> &gt; sudo mv python python2.6

#### 1.2 安装Certbot

<code>
&gt; wget https://dl.eff.org/certbot-auto

&gt; chmod +x certbot-auto
</code>

### 2. 创建证书

为了实现通配符证书，Let’s Encrypt 对 ACME 协议的实现进行了升级，只有 v2 协议才能支持通配符证书。

<code>
&gt; ./certbot-auto certonly --cert-name example.com --no-bootstrap --email example@gmail.com -d *.example.com -d example.com --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory
</code>

> 参数说明:    
> --cert-name:  指定一个证书名称；
>
> certonly:  表示安装模式，Certbot 有安装模式和验证模式两种类型的插件；  
>
> –manual:  表示手动安装插件，Certbot 有很多插件，不同的插件都可以申请证书，用户可以根据需要自行选择；  
>
> -d:  生成证书的主机名，支持多个，最多为100个(见[rate-limits](https://letsencrypt.org/docs/rate-limits/))，如果是通配符，输入 *.example.com (操作时替换为自己的域名)，支持多个-d 配置项；  
>
> –preferred-challenges:  值为 dns，使用 DNS 方式校验域名所有权,只有DNS方式支持通配符域名；  
>
> –server:  Let’s Encrypt ACME v2 版本使用的服务器不同于 v1 版本，需要显示指定,值为 https://acme-v02.api.letsencrypt.org/directory  
>
>更多配置，见 [certbot-commands](https://certbot.eff.org/docs/using.html#certbot-commands)  

命令执行后,若非root用户执行,需要输入sudo 用户密码,然后继续；

Certbot会按-d指定的顺序域名顺序对域名进行验证，要求在置顶域名下添加_acme-challenge开头的TXT记录，如：

> 记录类型: TXT  
> 主机记录: example.com  
> 记录值: 输入要求的值
> TTL: 选择最小的时间

等待DNS配置生效,生效后进行下一个域名验证；

> TXT 记录可设置最小TTL以快速生效;  
> 等待过程中可使用dig命令检查是否已生效  
> &gt; dig TXT _acme-challenge.example.com  | grep 记录值 |wc -l

Certbot执行完成后，会在/etc/letsencrypt/live/example.com/下会生成4个文件:  
cert.pem  - Apache服务器端证书  
chain.pem  - Apache根证书和中继证书  
fullchain.pem  - Nginx所需要ssl_certificate文件  
privkey.pem - 安全证书KEY文件

测试证书:
> &gt; openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -noout -text

生成证书步骤完成。
### 3. 配置Ngxin服务使用证书
将证书和私钥做软链到指定文件:

<code>
$ sudo ln -s /etc/letsencrypt/live/example.com/fullchain.pem /usr.docs.ssl_curr/fullchain.pem  

$ sudo ln -s /etc/letsencrypt/live/example.com/privkey.pem /usr.docs.ssl_curr/privkey.pem
</code>

nginx.conf:  
<code>
listen  80 default;  
listen  443 default ssl;  
#ssl on;   
ssl_prefer_server_ciphers on;  
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;  ssl_ciphers EECDH+CHACHA20:EECDH CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;  ssl_certificate /usr/docs/ssl_curr/fullchain.pem;  
ssl_certificate_key /usr/docs/ssl_curr/privkey.pem;  
</code>

重启Nginx:  
<code>
$ sudo ./nginx -t  
$ sudo ./nginx -t -s reload
</code>

### 4. 续签
续签使用自定义脚本来调用Certbot完成；  

> 原理：
> 1. 执行Certbot续签命令：
<code>
./certbot-auto renew --cert-name example.com --manual-auth-hook /usr/docs/[scripts/manual-auth-hook-aliyundns.sh](scripts/manual-auth-hook-aliyundns.sh) --dry-run
</code>  
>
> 2. 在域名认证过程中，调用阿里云DNS API/Namesilo API来动态添加/删除TXT记录，并使用dig命令扫描TXT记录(重复多次，知道成功)；
> 3. 续签成功后，调用[scripts/deploy-hook-nginx.sh](scripts/deploy-hook-nginx.sh) 重启Nginx
> 4. 执行成功后,调用[scripts/sendmail_server_event.sh](scripts/sendmail_server_event.sh)发送邮件提醒


依赖软件:
* Python2.7+/Python3
* dig 

涉及脚本:

* [certbot-auto-renew.sh](certbot-auto-renew.sh)  
* [scripts/](scripts/)

将以上脚本及目录复制到目标位置。

#### 4.1 修改脚本中的变量
* [certbot-auto-renew.sh](certbot-auto-renew.sh) 修改basePath为目标位置  

* [scripts/manual-auth-hook-aliyundns.sh](scripts/manual-auth-hook-aliyundns.sh) 阿里云DNS验证回调   
修改ALIYUNDNS_KEY 和 ALIYUNDNS_SEC为阿里云对应配置

* 若为namesilo时,修改[scripts/manual-auth-hook-namesilo.sh](scripts/manual-auth-hook-namesilo.sh) 修改NAMESILO_KEY为namesilo对应配置

* [scripts/manual-cleanup-hook-aliyundns.sh](scripts/manual-cleanup-hook-aliyundns.sh) 阿里云DNS清理回调  
修改ALIYUNDNS_KEY 和 ALIYUNDNS_SEC为阿里云对应配置   

* [scripts/manual-cleanup-hook-namesilo](scripts/manual-cleanup-hook-namesilo) Namesilo DNS清理回调  
修改NAMESILO_KEY为namesilo对应配置

* 证书续签成功后处理  
  [scripts/deploy-hook-nginx.sh](scripts/deploy-hook-nginx.sh)为配置续签成功后重启nginx  
  
* 证书续签结果生成邮件通知  
  [scripts/sendmail_server_event.sh](scripts/sendmail_server_event.sh) 为[certbot-auto-renew.sh](certbot-auto-renew.sh)处理完成后，对成功/失败结果进行通知。  
  修改__FROM__变量指定邮件发送人  
  修改__TO__变量指定邮件接收人
   
#### 4.2 验证
可直接执行[certbot-auto-renew.sh](certbot-auto-renew.sh)进行验证  

<code>
$ ./certbot-auto-renew.sh
</code>

执行完成后，检查是否收到邮件，Nginx证书是否更新。

#### 4.3 设置自动执行任务
最后为certbot-auto-renew.sh设置Crontab定时任务；  

<code>
$ crontab -e  

0 1 * * * sh /usr/docs/certbot-auto-renew.sh
</code>

## 参考资料
* [Let's Encrypt (letsencrypt.org)](https://letsencrypt.org)
* [Certbot (certbot.eff.org)](https://certbot.eff.org)

结束。

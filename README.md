# Ubuntu 初始化脚本

## 准备工作
建wp站的话，要看下面wordpress相关的说明！

## 安装方法
### 安装 方法1 （首选）
```
# root 用户登录服务器
sudo su
cd ~ # 一定要使用 /root目录
curl https://raw.githubusercontent.com/gjenjoying/ubuntu-init/master/download.sh | bash  # 如失败 多次几次 网络问题
cd /root/ubuntu-init/
./install.sh
```
安装好后，要看一下 /var/www 是否为 deployer:www-data，如不是，重置服务器，再安装一次！
ls -lah /var

### 安装 方法2 （由于ubuntu-init也需要使用git，所以可以使用这个）

```
# 生成密钥
sudo su
# 看 ~/.ssh 下面是否有 id_rsa 了
cd ~/.ssh 
# 没的话 生成；全部默认回车
ssh-keygen -t rsa -C "rl-xixisys-int-tencent-us@en.xixisys.com"
cat id_rsa.pub
# 将上面的key copy到 github.com, https://github.com/settings/ssh/new

# clone
git clone git@github.com:gjenjoying/ubuntu-init.git 
cd /root/ubuntu-init/
./install.sh
```


### deployer 用户配置

```
# 添加本地的公钥至 deployer 用户中
su - deployer
nano ~/.ssh/authorized_keys # 复制本地公钥至 deployer 用户，用于使用 deployer 的代码部署 在Mac上面运行 cat ~/.ssh/id_rsa.pub | pbcopy

# 测试一下是否可行，在 本地Mac上 执行 ssh deployer@ip 看看能不能连上去

# 将deployer用户的 ssh key 复制到github中
sudo -H -s
cd /root/ubuntu-init
chmod +x ./show_deployer_key.sh
./show_deployer_key.sh
#得到的key 复制到github中 https://github.com/settings/keys
```

## 注意事项

* 适用于 ubuntu 18
* 请在 root 下执行脚本
* 切换php版本：sudo update-alternatives --config php
* nginx mariadb redis 要配置下，分别见：https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04, https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04， https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-redis-on-ubuntu-18-04

具体要做的如下
```
# Nginx
nano /etc/nginx/nginx.conf # server_names_hash_bucket_size 64; 启用；保存退出
unlink /etc/nginx/sites-enabled/default # 通常不启用这个
systemctl restart nginx

# mysql https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04
sudo mysql_secure_installation  # root 需要设置密码（如自己用的最高级密码），其它全部选择 y 即可，注意root不要开romtely访问。不用改为pw 验证方式，创建一个新用户来执行高级权限 如下
sudo mysql
GRANT ALL ON *.* TO 'peter'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION; # 改密码
FLUSH PRIVILEGES;
exit;

sudo systemctl status mysql.service
sudo mysqladmin -p -u root version
mysqladmin -u peter -p version

# redis
sudo nano /etc/redis/redis.conf  #1. 将 supervised no 改为 supervised systemd  #2. 把 bind 127.0.0.1 ::1 关闭（注释掉，#） 
sudo systemctl restart redis
sudo netstat -lnp | grep redis

# memcached
# 默认配置基本不用动了，只要确认 /etc/memcached.conf 存在 -l 127.0.0.1
# 具体见：https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-memcached-on-ubuntu-18-04
```


## 软件列表

* Git
* PHP 7.2
* Nginx
* Sqlite3
* mariadb
* Composer
* Redis
* let's encrypt - certbot
* wormhole

## 新增 Nginx 站点

```
./nginx_add_site.sh
```

根据提示输入站点信息，确认之后将创建对应的 Nginx 配置并重启 Nginx

## 显示 deplpyer 用户的 SSH 公钥

```
./show_deployer_key.sh
```

复制 SSH 公钥至你的代码库用于代码部署

## 腾讯服务器相关脚本
需要先安装 tccli: sudo pip install tccli，tccli --version， tccli configure，见：https://cloud.tencent.com/document/product/440/34011 
API调试使用 API Explorer: https://console.cloud.tencent.com/api/explorer?Product=lighthouse&Version=2020-03-24&Action=DescribeSnapshots&SignVersion=
- remove_tencent_services
- cronjobs里面的 updateImage-cn.sh，updateSnap-cn.sh,updateImage-us.sh，updateSnap-us.sh

## 其他
- check_time_zone.sh，仅用于ubuntu系统，不支持mac （可用mac上的multipass下的ubuntu），用于计算各时区时间

* 脚本参考：[laravel-ubuntu-init](https://github.com/summerblue/laravel-ubuntu-init)
* 推荐阅读：[又一篇 Deployer 的使用攻略](https://overtrue.me/articles/2018/06/deployer-guide.html)

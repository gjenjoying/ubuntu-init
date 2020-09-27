# Ubuntu 初始化脚本

## 准备工作

```
sudo -H -s   #  进入后是 /home/ubuntu
add-apt-repository universe  #这2项本来在install.sh 中可自动执行 卡住了 可能是因为要输入 enter ？ 所以提前先执行好了
add-apt-repository ppa:certbot/certbot
```

## 安装方法
### 安装 方法1 （首选）

ubuntu 用户登录服务器

```
curl https://raw.githubusercontent.com/gjenjoying/ubuntu-init/master/download.sh | bash  # 如失败 多次几次 网络问题
cd /home/ubuntu/ubuntu-init/
./install.sh
```

### 安装 方法2

```
git clone git@github.com:gjenjoying/ubuntu-init.git # 需要先将用户的 ssh public key加到 github中 麻烦一些
cd /home/ubuntu/ubuntu-init/
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
cd /home/ubuntu/ubuntu-init
chmod +x ./show_deployer_key.sh
./show_deployer_key.sh
#得到的key 复制到github中 https://github.com/settings/keys
```

## 注意事项

* 适用于 ubuntu 18
* 请在 root 下执行脚本
* nginx mariadb redis 要配置下，分别见：https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-ubuntu-18-04， https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04， https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-redis-on-ubuntu-18-04

具体要做的如下
```
# Nginx
nano /etc/nginx/nginx.conf # server_names_hash_bucket_size 64; 启用
unlink /etc/nginx/sites-enabled/default # 通常不启用这个

# mariadb
sudo mysql_secure_installation  # root 不要设密码

sudo mysql
GRANT ALL ON *.* TO 'peter'@'localhost' IDENTIFIED BY 'thecareer2020' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit;

sudo systemctl status mariadb
sudo mysqladmin version
mysqladmin -u peter -p version

# redis
sudo nano /etc/redis/redis.conf # supervised systemd   +  # bind 127.0.0.1 ::1
sudo systemctl restart redis
sudo netstat -lnp | grep redis

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

## 其他

* 脚本参考：[laravel-ubuntu-init](https://github.com/summerblue/laravel-ubuntu-init)
* 推荐阅读：[又一篇 Deployer 的使用攻略](https://overtrue.me/articles/2018/06/deployer-guide.html)

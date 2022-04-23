# Ubuntu 初始化脚本

## 准备工作
1. 此脚本必须保存在 /root/ubuntu-init 目录下运行！否则 wp 相关的脚本会出错！
2. 须 创建 .env （用env_example改为 .env，写入对应的值）
3. 需要提前在服务器上安装好 /root/Search-Replace-DB https://github.com/interconnectit/Search-Replace-DB
由于Search-Replace-DB 需要php7.4及出，但此脚本中的laravel/dzq是使用php7.2的，因此，未将Search-Replace-DB集成到此脚本中。
```
sudo su   
cd ~ #  进入后是 /root
add-apt-repository universe  #这2项本来在install.sh 中可自动执行 卡住了 可能是因为要输入 enter ？ 所以提前先执行好了
add-apt-repository ppa:certbot/certbot
```

## 安装方法
### 安装 方法1 （首选）


```
# root 用户登录服务器
curl https://raw.githubusercontent.com/gjenjoying/ubuntu-init/master/download.sh | bash  # 如失败 多次几次 网络问题
cd /root/ubuntu-init/
# 切换成root用户
# sudo su
./install.sh
```
安装好后，要看一下 /var/www 是否为 deployer:www-data，如不是，重置服务器，再安装一次！
ls -lah /var

### 安装 方法2

```
git clone git@github.com:gjenjoying/ubuntu-init.git # 需要先将用户的 ssh public key加到 github中 麻烦一些
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

## wordpress 相关
### templates 里的 wp-config.php
注意！wp-config-example 中涉及到的 AUTH_KEY 等值，与 wordpress.5.9.3-xixisys.sql、wordpress.5.9.3-xixisys-initial.sql 中存的一致
后续如果要换 wordpress.5.9.3-xixisys.sql 这些sql，一定要从 wordpress.5.9.3-xixisys-initial.sql 重新配置一份，再改动，再保存到新的 wordpress.5.9.3-xixisys.sql
这样可以避免改动 .env 中的值。
### 创建 .env
将 env_example 重命名为 .env，写上实际的值。
注意！wp-config-example 中涉及到的 AUTH_KEY 等值，如写在 .env 会导致报错，因为一些特殊字符不能 export到环境里，加上单引号或双引号也不行！

### php 7.4及以上
如果要用此脚本装wp，需要初始时安装php7.4，如已安装7.2，可以新服务器重新装一次，或者，升级php7.2到7.4：
https://www.digitalocean.com/community/questions/how-to-upgrade-php-7-2-to-php-7-4-on-ubuntu-18-04-nginx

### 默认用户名及密码
用户名:xixisys，密码:demo
目前使用的是5.9.3版，中文的，下载地址：
https://cn.wordpress.org/download/#download-install

### 默认项目文件及数据库sql
在服务器上安装后，得到文件夹和对应数据库，导出为wordpress.5.9.3-xixisys 和 wordpress.5.9.3-xixisys.sql

在项目中，有默认的 wordpress.5.9.3-xixisys 文件夹（包含了初始配置的wp-config.php），也包含了wordpress.5.9.3-xixisys.sql(包含了初始配置的数据库)

注：
1. wordpress.5.9.3-xixisys 文件夹 直接copy初始化完成后的网站的项目文件夹即可（整个wordpress）。
2. 导出wordpress.5.9.3-xixisys.sql时，使用 mysqldump 加参数：--no-create-db，例如
`mysqldump -u peter -p --databases wp_wordpress_xixisys_com --no-create-db > wp_wordpress_xixisys_com.sql`
注意：得到sql，要手动删除 USE {DBNAME} 这一行，这样后续才能导入！
3. wordpress 文件夹内，-initial的，是刚刚装好后，只设置了用户名和密码的。而未加-initial的，是设置得比较好的了。保留 -initial 的，是为了方便回到最初未定制的样子。

## 其他

* 脚本参考：[laravel-ubuntu-init](https://github.com/summerblue/laravel-ubuntu-init)
* 推荐阅读：[又一篇 Deployer 的使用攻略](https://overtrue.me/articles/2018/06/deployer-guide.html)

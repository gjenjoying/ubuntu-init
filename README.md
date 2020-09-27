# Ubuntu 初始化脚本

首先执行

```
add-apt-repository universe  #这2项本来在install.sh 中可自动执行 卡住了 可能是因为要输入 enter ？ 所以提前先执行好了
add-apt-repository ppa:certbot/certbot
```


## 安装 方法1 

ubuntu 用户登录服务器

```
curl https://raw.githubusercontent.com/gjenjoying/ubuntu-init/master/download.sh | bash
cd /home/ubuntu/ubuntu-init/
./install.sh
```

## 安装 方法2

```
git clone git@github.com:gjenjoying/ubuntu-init.git
cd /home/ubuntu/ubuntu-init/
./install.sh
```


### 添加本地的公钥至 deployer 用户中

```
su - deployer
vim ~/.ssh/authorized_keys # 复制本地公钥至 deployer 用户，用于使用 deployer 的代码部署
```

## 注意事项

* 适用于 ubuntu 18
* 请在 root 下执行脚本
* nginx mariadb redis 要配置下，分别见：https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-ubuntu-18-04， https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04， https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-redis-on-ubuntu-18-04

## 软件列表

* Git
* PHP 7.4
* Nginx
* Sqlite3
* Composer
* Redis

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

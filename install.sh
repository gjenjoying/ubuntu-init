#!/bin/bash

set -e

DEPLOYER_USER=deployer
WWW_USER=www-data
WWW_USER_GROUP=www-data

echo "==== 开始初始化 Ubuntu 24.04 ===="

export DEBIAN_FRONTEND=noninteractive

# ================================

# 基础环境

# ================================

echo "==> 更新系统"
apt update

echo "==> 安装基础组件"
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg curl

# ================================

# 手动添加 ondrej/php 源（避免卡住）

# ================================

echo "==> 添加 PHP PPA（手动方式）"

mkdir -p /etc/apt/keyrings

curl -fsSL https://ppa.launchpadcontent.net/ondrej/php/ubuntu/KEY.gpg 
| gpg --dearmor -o /etc/apt/keyrings/ondrej-php.gpg

echo "deb [signed-by=/etc/apt/keyrings/ondrej-php.gpg] http://ppa.launchpadcontent.net/ondrej/php/ubuntu noble main" 
> /etc/apt/sources.list.d/ondrej-php.list

apt update

# ================================

# 基础软件

# ================================

echo "==> 安装基础软件"
apt install -y curl git build-essential unzip supervisor jq

# ================================

# PHP 7.4

# ================================

echo "==> 安装 PHP 7.4"
apt install -y php7.4 php7.4-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,memcached,memcache,ssh2,sqlite3,imagick,tidy,xmlrpc,mongodb,intl,soap}

# ================================

# MySQL（恢复交互）

# ================================

echo "==> 安装 MySQL（交互）"
unset DEBIAN_FRONTEND
apt install -y mysql-server

# ================================

# 其他服务

# ================================

echo "==> 安装 Nginx / Redis / Memcached"
apt install -y nginx redis-server memcached libmemcached-tools sqlite3

systemctl enable nginx

# ================================

# Composer v1

# ================================

echo "==> 安装 Composer v1"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
chmod +x /usr/local/bin/composer
composer self-update --1

mkdir -p /var/www/.composer
chown -R www-data:www-data /var/www/.composer

sudo -H -u www-data composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer/

# ================================

# Certbot

# ================================

echo "==> 安装 Certbot"
apt install -y certbot python3-certbot-nginx

# ================================

# deployer 用户

# ================================

echo "==> 创建 deployer 用户"

if id "$DEPLOYER_USER" &>/dev/null; then
echo "用户已存在，跳过"
else
useradd -d /home/${DEPLOYER_USER} -m -s /bin/bash ${DEPLOYER_USER}
fi

usermod -aG ${WWW_USER_GROUP} ${DEPLOYER_USER}

echo "${DEPLOYER_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${DEPLOYER_USER}
chmod 440 /etc/sudoers.d/${DEPLOYER_USER}

mkdir -p /home/${DEPLOYER_USER}/.ssh
chown -R ${DEPLOYER_USER}:${DEPLOYER_USER} /home/${DEPLOYER_USER}/.ssh

sudo -H -u ${DEPLOYER_USER} ssh-keygen -t rsa -b 4096 -N "" -f /home/${DEPLOYER_USER}/.ssh/id_rsa || true

# ================================

# 权限

# ================================

echo "==> 设置 /var/www 权限"
chown -R ${DEPLOYER_USER}.${WWW_USER_GROUP} /var/www/

# ================================

# PHP 配置

# ================================

echo "==> 应用 PHP 配置"

mkdir -p /etc/php/7.4/fpm/conf.d

cat > /etc/php/7.4/fpm/conf.d/99-custom.ini <<EOF
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 512M
EOF

systemctl restart php7.4-fpm

# ================================

# Wormhole

# ================================

echo "==> 安装 wormhole"
apt install -y magic-wormhole

echo "==== 安装完成 ✅ ===="
echo "请手动配置：nginx / mysql / php"

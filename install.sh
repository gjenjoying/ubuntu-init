#!/bin/bash

set -e

DEPLOYER_USER=deployer
WWW_USER=www-data
WWW_USER_GROUP=www-data

echo "==== Ubuntu 24.04 + PHP 7.4 (B方案修复版) ===="

export DEBIAN_FRONTEND=noninteractive

# ================================
# 基础环境
# ================================

echo "==> 更新系统"
apt update -y

echo "==> 安装基础组件"
apt install -y software-properties-common ca-certificates lsb-release \
apt-transport-https gnupg curl unzip git build-essential jq supervisor

# ================================
# PHP PPA（修复 404 + 改用 keyserver）
# ================================

echo "==> 添加 Ondrej PHP PPA（兼容方案）"

mkdir -p /etc/apt/keyrings

# 修复点：不用 launchpadcontent KEY.gpg（已404）
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE5267A6C" \
| gpg --dearmor -o /etc/apt/keyrings/ondrej-php.gpg

# ⚠️关键：用 jammy 源（不是 noble）
echo "deb [signed-by=/etc/apt/keyrings/ondrej-php.gpg] http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" \
> /etc/apt/sources.list.d/ondrej-php.list

apt update -y

# ================================
# PHP 7.4
# ================================

echo "==> 安装 PHP 7.4"

apt install -y \
php7.4 php7.4-fpm php7.4-cli php7.4-common \
php7.4-bcmath php7.4-curl php7.4-gd php7.4-mbstring \
php7.4-mysql php7.4-opcache php7.4-xml php7.4-zip \
php7.4-readline php7.4-sqlite3 php7.4-intl \
php7.4-soap php7.4-redis php7.4-memcached \
php7.4-imagick php7.4-mongodb || true

# ================================
# MySQL（避免交互卡死）
# ================================

echo "==> 安装 MySQL（非交互模式）"

debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

apt install -y mysql-server

# ================================
# Nginx / Redis / Memcached
# ================================

echo "==> 安装 Nginx / Redis / Memcached"
apt install -y nginx redis-server memcached libmemcached-tools sqlite3

systemctl enable nginx

# ================================
# Composer v1（保持旧项目兼容）
# ================================

echo "==> 安装 Composer v1"

curl -sS https://getcomposer.org/installer | php -- \
--install-dir=/usr/local/bin/ --filename=composer

chmod +x /usr/local/bin/composer

composer self-update --1

mkdir -p /var/www/.composer
chown -R www-data:www-data /var/www/.composer

sudo -H -u www-data composer config -g \
repo.packagist composer https://mirrors.cloud.tencent.com/composer/

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

echo "${DEPLOYER_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${DEPLOYER_USER}
chmod 440 /etc/sudoers.d/${DEPLOYER_USER}

mkdir -p /home/${DEPLOYER_USER}/.ssh
chown -R ${DEPLOYER_USER}:${DEPLOYER_USER} /home/${DEPLOYER_USER}/.ssh

sudo -H -u ${DEPLOYER_USER} ssh-keygen -t rsa -b 4096 -N "" \
-f /home/${DEPLOYER_USER}/.ssh/id_rsa || true

# ================================
# /var/www 权限
# ================================

echo "==> 设置 /var/www 权限"
chown -R ${DEPLOYER_USER}:${WWW_USER_GROUP} /var/www/

# ================================
# PHP 配置
# ================================

echo "==> PHP 配置"

mkdir -p /etc/php/7.4/fpm/conf.d

cat > /etc/php/7.4/fpm/conf.d/99-custom.ini <<EOF
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 512M
EOF

systemctl restart php7.4-fpm

# ================================
# wormhole
# ================================

echo "==> 安装 wormhole"
apt install -y magic-wormhole

echo "==== 完成 ✅ ===="
echo "注意：这是 PHP7.4 legacy 环境（Ubuntu 24.04 非官方支持）"

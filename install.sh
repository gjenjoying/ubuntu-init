#!/bin/bash

set -e

DEPLOYER_USER=deployer
WWW_USER=www-data
WWW_USER_GROUP=www-data

echo "==== Ubuntu 24.04 + PHP7.4 SAFE B MODE ===="

export DEBIAN_FRONTEND=noninteractive

# ================================
# base
# ================================

apt update -y

apt install -y \
software-properties-common ca-certificates lsb-release \
apt-transport-https gnupg curl unzip git build-essential jq supervisor

# ================================
# PPA fix
# ================================

mkdir -p /etc/apt/keyrings

curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE5267A6C" \
| gpg --dearmor -o /etc/apt/keyrings/ondrej-php.gpg

echo "deb [signed-by=/etc/apt/keyrings/ondrej-php.gpg] http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" \
> /etc/apt/sources.list.d/ondrej-php.list

apt update -y

# ================================
# PHP 7.4 CORE ONLY (关键修复点)
# ================================

echo "==> Installing PHP7.4 core packages (safe mode)"

apt install -y \
php7.4 php7.4-fpm php7.4-cli php7.4-common \
php7.4-bcmath php7.4-curl php7.4-gd php7.4-mbstring \
php7.4-mysql php7.4-opcache php7.4-xml php7.4-zip \
php7.4-readline php7.4-sqlite3 || true

# ================================
# OPTIONAL EXTENSIONS (不保证成功)
# ================================

echo "==> Installing optional extensions (non-blocking)"

apt install -y php7.4-redis php7.4-memcached || true
apt install -y php7.4-mongodb || true

# ❗关键修复：这些在 24.04 基本装不了，所以允许失败
apt install -y php7.4-imagick || true
apt install -y php7.4-intl || true
apt install -y php7.4-soap || true

# ================================
# MySQL (non-interactive)
# ================================

debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

apt install -y mysql-server

# ================================
# Nginx / Redis
# ================================

apt install -y nginx redis-server memcached sqlite3
systemctl enable nginx

# ================================
# FIX: ensure php exists before composer
# ================================

echo "==> verifying php"
which php || ln -s /usr/bin/php7.4 /usr/bin/php || true

# ================================
# Composer v1
# ================================

echo "==> installing composer"

curl -sS https://getcomposer.org/installer | php -- \
--install-dir=/usr/local/bin --filename=composer

chmod +x /usr/local/bin/composer

composer self-update --1 || true

# ================================
# deploy user
# ================================

if ! id "$DEPLOYER_USER" &>/dev/null; then
  useradd -d /home/$DEPLOYER_USER -m -s /bin/bash $DEPLOYER_USER
fi

usermod -aG www-data $DEPLOYER_USER

echo "$DEPLOYER_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$DEPLOYER_USER
chmod 440 /etc/sudoers.d/$DEPLOYER_USER

# ================================
# PHP config
# ================================

mkdir -p /etc/php/7.4/fpm/conf.d

cat > /etc/php/7.4/fpm/conf.d/99-custom.ini <<EOF
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 512M
EOF

systemctl restart php7.4-fpm || true

# ================================
# wormhole
# ================================

apt install -y magic-wormhole

echo "==== DONE (SAFE MODE) ===="
echo "PHP7.4 installed in degraded mode (no intl/imagick guaranteed)"

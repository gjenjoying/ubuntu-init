#!/bin/bash
set -e

DEPLOYER_USER=deployer
WWW_USER_GROUP=www-data

echo "==== Ubuntu 24.04 SAFE INSTALL FIXED ===="

export DEBIAN_FRONTEND=noninteractive

# ================================
# FIX 1: force IPv4 (CRITICAL)
# ================================
echo "==> forcing IPv4 for apt/network"
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# ================================
# FIX 2: wait apt lock (NO rm lock)
# ================================
echo "==> waiting for apt lock..."

while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
  echo "apt locked, waiting..."
  sleep 2
done

# ================================
# base
# ================================
apt update -y

apt install -y \
software-properties-common ca-certificates lsb-release \
apt-transport-https gnupg curl unzip git build-essential jq supervisor \
openssh-client

# ================================
# PPA (ondrej php) - SAFE MODE
# ================================
mkdir -p /etc/apt/keyrings

curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE5267A6C \
| gpg --dearmor -o /etc/apt/keyrings/ondrej-php.gpg

echo "deb [signed-by=/etc/apt/keyrings/ondrej-php.gpg] http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" \
> /etc/apt/sources.list.d/ondrej-php.list

apt update -y || echo "WARN: PPA update failed, continuing..."

# ================================
# PHP 7.4 (SAFE TRY-CATCH STYLE)
# ================================

echo "==> installing PHP7.4 (may fallback fail-safe)"

apt install -y \
php7.4 php7.4-cli php7.4-fpm php7.4-common \
php7.4-curl php7.4-mbstring php7.4-xml php7.4-zip \
php7.4-mysql php7.4-opcache php7.4-sqlite3 \
php7.4-gd php7.4-bcmath || echo "WARN: PHP7.4 partially failed"

# ================================
# fix php symlink
# ================================
if [ -f /usr/bin/php7.4 ]; then
  ln -sf /usr/bin/php7.4 /usr/bin/php
fi

php -v || echo "WARN: PHP not available"

# ================================
# MySQL
# ================================
apt install -y mysql-server

systemctl enable mysql
systemctl restart mysql

sudo mysql -e "SELECT 'mysql ok';" || true

# ================================
# nginx / redis
# ================================
apt install -y nginx redis-server memcached sqlite3
systemctl enable nginx

# ================================
# composer (ONLY IF PHP EXISTS)
# ================================
if command -v php >/dev/null 2>&1; then
  echo "==> installing composer"
  curl -sS https://getcomposer.org/installer | php -- \
  --install-dir=/usr/local/bin --filename=composer

  chmod +x /usr/local/bin/composer
  composer self-update --1 || true
else
  echo "WARN: skip composer (php missing)"
fi

# ================================
# deploy user (safe idempotent)
# ================================
if ! id "$DEPLOYER_USER" >/dev/null 2>&1; then
  useradd -d /home/$DEPLOYER_USER -m -s /bin/bash $DEPLOYER_USER
fi

usermod -aG $WWW_USER_GROUP $DEPLOYER_USER

echo "$DEPLOYER_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$DEPLOYER_USER
chmod 440 /etc/sudoers.d/$DEPLOYER_USER

# ================================
# SSH key safe
# ================================
sudo -H -u $DEPLOYER_USER bash -c '
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi
'

# ================================
# DONE
# ================================
echo "==== DONE SAFE INSTALL ===="

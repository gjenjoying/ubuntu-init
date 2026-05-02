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
apt-transport-https gnupg curl unzip git build-essential jq supervisor \
openssh-client

# ================================
# PPA fix (PHP 7.4)
# ================================

mkdir -p /etc/apt/keyrings

curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE5267A6C" \
| gpg --dearmor -o /etc/apt/keyrings/ondrej-php.gpg

echo "deb [signed-by=/etc/apt/keyrings/ondrej-php.gpg] http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" \
> /etc/apt/sources.list.d/ondrej-php.list

apt update -y

# ================================
# PHP 7.4 CORE
# ================================

echo "==> Installing PHP7.4 core packages"

apt install -y \
php7.4 php7.4-fpm php7.4-cli php7.4-common \
php7.4-bcmath php7.4-curl php7.4-gd php7.4-mbstring \
php7.4-mysql php7.4-opcache php7.4-xml php7.4-zip \
php7.4-readline php7.4-sqlite3 || true

# ================================
# OPTIONAL EXTENSIONS
# ================================

apt install -y php7.4-redis php7.4-memcached || true
apt install -y php7.4-mongodb || true
apt install -y php7.4-imagick php7.4-intl php7.4-soap || true

# ================================
# MYSQL (FIXED)
# ================================

echo "==> Installing MySQL (auth_socket default preserved)"

apt install -y mysql-server

systemctl enable mysql
systemctl restart mysql

echo "==> verifying mysql access"
sudo mysql -e "SELECT 'mysql ok';" || true

# ================================
# Nginx / Redis
# ================================

apt install -y nginx redis-server memcached sqlite3
systemctl enable nginx

# ================================
# ensure php exists
# ================================

which php || ln -s /usr/bin/php7.4 /usr/bin/php || true

# ================================
# Composer v1
# ================================

echo "==> installing composer"

curl -sS https://getcomposer.org/installer | php -- \
--install-dir=/usr/local/bin --filename=composer

chmod +x /usr/local/bin/composer
composer self-update --1 || true

# =========================================================
# deploy user (MERGED OLD + NEW LOGIC, SAFE VERSION)
# =========================================================

echo "==> setting up deploy user"

if ! id "$DEPLOYER_USER" &>/dev/null; then
  useradd -d /home/${DEPLOYER_USER} -m -s /bin/bash ${DEPLOYER_USER}
fi

# add to www group
usermod -aG ${WWW_USER_GROUP} ${DEPLOYER_USER}

# ------------------------
# bash environment (old logic preserved)
# ------------------------

sudo -H -u ${DEPLOYER_USER} bash -c 'echo "umask 022" >> ~/.bashrc'

# ------------------------
# sudoers (FIXED: avoid overwriting /etc/sudoers)
# ------------------------

echo "${DEPLOYER_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${DEPLOYER_USER}
chmod 440 /etc/sudoers.d/${DEPLOYER_USER}

# ------------------------
# web directory permissions (old logic improved safety)
# ------------------------

mkdir -p /var/www/html

chown -R ${DEPLOYER_USER}:${WWW_USER_GROUP} /var/www/html
chmod -R 775 /var/www/html
chmod g+s /var/www/html

# ------------------------
# SSH key (safe: only generate if missing)
# ------------------------

sudo -H -u ${DEPLOYER_USER} bash -c '
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
'

# =========================================================
# PHP config
# =========================================================

mkdir -p /etc/php/7.4/fpm/conf.d

cat > /etc/php/7.4/fpm/conf.d/99-custom.ini <<EOF
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 512M
EOF

systemctl restart php7.4-fpm || true

# ================================
# tools
# ================================

apt install -y magic-wormhole

echo "==== DONE ===="
echo "PHP7.4 + MySQL + deploy user ready"

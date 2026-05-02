#!/bin/bash
set -e

DEPLOYER_USER=deployer
WWW_USER_GROUP=www-data

echo "==== Ubuntu 24.04 PHP 7.4 终极安装脚本 ===="

# ================================
# 1. 询问服务器位置
# ================================
read -p "请选择服务器位置 (cn/intl): " LOCATION
LOCATION=$(echo "$LOCATION" | tr '[:upper:]' '[:lower:]')

if [ "$LOCATION" == "intl" ]; then
    echo "==> 还原为官方默认源..."
    cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF
else
    echo "==> 保持当前源设置"
fi

export DEBIAN_FRONTEND=noninteractive

# ================================
# 基础准备
# ================================
echo "==> 基础环境配置..."
apt update -y
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg curl

# ================================
# 2. PHP 7.4 PPA 处理
# ================================
echo "==> 添加 Ondřej Surý PHP PPA..."

# 移除之前可能失败的旧配置
rm -f /etc/apt/sources.list.d/ondrej-php.list
rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-noble.sources

# 使用标准方式添加 PPA
# 即使 24.04 会报错，我们也要先添加它来获取 GPG 密钥
add-apt-repository ppa:ondrej/php -y --no-update

# 【关键点】强制将 noble 替换为 jammy
# 因为 PHP 7.4 官方仅支持到 22.04 (jammy)，所以我们要“骗”一下系统
if [ -f /etc/apt/sources.list.d/ondrej-ubuntu-php-noble.sources ]; then
    sed -i 's/Suites: noble/Suites: jammy/g' /etc/apt/sources.list.d/ondrej-ubuntu-php-noble.sources
fi

apt update -y

# ================================
# 3. 安装 PHP 7.4
# ================================
echo "==> 正在安装 PHP 7.4..."
# 注意：24.04 缺少 libssl1.1，而 PHP 7.4 需要它。
# 如果直接安装报错，脚本会尝试下载 libssl1.1
apt install -y \
php7.4 php7.4-cli php7.4-fpm php7.4-mysql php7.4-curl \
php7.4-xml php7.4-zip php7.4-mbstring php7.4-gd \
php7.4-intl php7.4-bcmath php7.4-sqlite3 php7.4-opcache || {
    echo "==> 补救：安装 libssl1.1 依赖..."
    wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
    dpkg -i libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
    apt install -y php7.4-common php7.4-cli php7.4-fpm ... # 重新尝试
}

# 修正软连接
update-alternatives --set php /usr/bin/php7.4 || true

# ================================
# 4. MySQL, Nginx, Redis
# ================================
echo "==> 安装配套组件..."
apt install -y mysql-server nginx redis-server
systemctl enable --now mysql nginx redis-server

# Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
composer self-update --2.2 || true

# ================================
# 5. 用户与权限
# ================================
if ! id "$DEPLOYER_USER" >/dev/null 2>&1; then
  useradd -d /home/$DEPLOYER_USER -m -s /bin/bash $DEPLOYER_USER
fi
usermod -aG $WWW_USER_GROUP $DEPLOYER_USER
echo "$DEPLOYER_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$DEPLOYER_USER
chmod 440 /etc/sudoers.d/$DEPLOYER_USER

sudo -H -u $DEPLOYER_USER bash -c '
mkdir -p ~/.ssh && chmod 700 ~/.ssh
[ ! -f ~/.ssh/id_rsa ] && ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
'

echo "==== 安装成功！ ===="
php -v

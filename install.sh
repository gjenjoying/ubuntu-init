#!/bin/bash
set -e

DEPLOYER_USER=deployer
WWW_USER_GROUP=www-data

echo "==== Ubuntu 24.04 PHP 7.4 环境安装脚本 ===="

# ================================
# 1. 询问服务器位置
# ================================
read -p "请选择服务器位置 (cn/intl): " LOCATION
LOCATION=$(echo "$LOCATION" | tr '[:upper:]' '[:lower:]')

if [ "$LOCATION" == "intl" ]; then
    echo "==> 检测到国际区域，正在还原为 Ubuntu 官方默认源..."
    # 备份旧源并恢复官方源
    cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF
else
    echo "==> 使用当前预设源（跳过官方源覆盖）"
fi

export DEBIAN_FRONTEND=noninteractive

# ================================
# 基础优化与锁定检查
# ================================
echo "==> 强制 IPv4 优先..."
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

echo "==> 等待 apt 锁释放..."
while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
  echo "apt 锁占用中，等待 2 秒..."
  sleep 2
done

apt update -y

# 安装核心依赖
apt install -y \
software-properties-common ca-certificates lsb-release \
apt-transport-https gnupg curl unzip git build-essential jq supervisor \
openssh-client

# ================================
# 2. 集成 PHP 7.4 安装逻辑
# ================================
echo "==> 配置 Ondřej Surý PHP PPA..."

mkdir -p /etc/apt/keyrings

# 导入 GPG 密钥
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE5267A6C" \
| gpg --dearmor --yes -o /etc/apt/keyrings/ondrej-php.gpg

# 注意：Ubuntu 24.04 (noble) 下安装 PHP 7.4 必须指向 jammy 的库，因为 7.4 未针对 noble 打包
echo "deb [signed-by=/etc/apt/keyrings/ondrej-php.gpg] http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" \
> /etc/apt/sources.list.d/ondrej-php.list

apt update -y || echo "WARN: PPA 更新失败，尝试继续..."

echo "==> 正在安装 PHP 7.4..."
apt install -y \
php7.4 php7.4-cli php7.4-fpm php7.4-common \
php7.4-curl php7.4-mbstring php7.4-xml php7.4-zip \
php7.4-mysql php7.4-opcache php7.4-sqlite3 \
php7.4-gd php7.4-bcmath php7.4-intl || {
  echo "ERROR: PHP 7.4 安装失败。这可能是因为 24.04 缺少部分底层依赖包。"
  exit 1
}

# 修正 PHP 软链接
if [ -f /usr/bin/php7.4 ]; then
  update-alternatives --set php /usr/bin/php7.4
  ln -sf /usr/bin/php7.4 /usr/bin/php
fi

php -v

# ================================
# 3. 其他组件安装
# ================================

# MySQL
echo "==> 安装 MySQL Server..."
apt install -y mysql-server
systemctl enable mysql
systemctl restart mysql

# Nginx / Redis
echo "==> 安装 Nginx / Redis / Memcached..."
apt install -y nginx redis-server memcached sqlite3
systemctl enable nginx

# Composer
if command -v php >/dev/null 2>&1; then
  echo "==> 安装 Composer..."
  curl -sS https://getcomposer.org/installer | php -- \
  --install-dir=/usr/local/bin --filename=composer
  chmod +x /usr/local/bin/composer
  # 强制使用兼容 PHP 7.4 的 Composer 2.2 LTS 版本或 1.x
  composer self-update --2.2 || true
fi

# ================================
# 用户与权限设置
# ================================
echo "==> 配置部署用户 $DEPLOYER_USER..."
if ! id "$DEPLOYER_USER" >/dev/null 2>&1; then
  useradd -d /home/$DEPLOYER_USER -m -s /bin/bash $DEPLOYER_USER
fi

usermod -aG $WWW_USER_GROUP $DEPLOYER_USER

# 免密 sudo
echo "$DEPLOYER_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$DEPLOYER_USER
chmod 440 /etc/sudoers.d/$DEPLOYER_USER

# 生成 SSH Key
sudo -H -u $DEPLOYER_USER bash -c '
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi
'

echo "------------------------------------------------"
echo "==== 安装完成！ ===="
echo "PHP 版本: $(php -v | head -n 1)"
echo "部署用户: $DEPLOYER_USER"
echo "------------------------------------------------"

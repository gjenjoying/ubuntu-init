#!/bin/bash

set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
LOG_PATH="${CURRENT_DIR}/ubuntu-init.log"

source ${CURRENT_DIR}/common.sh

check_root

function init_system {
    apt update
    apt install -y software-properties-common
    apt update
}

function init_repositories {
    add-apt-repository universe -y 
    add-apt-repository ppa:certbot/certbot -y
    add-apt-repository ppa:ondrej/php -y # 同时安装php7.4 需要
    apt update
}

function init_deployer_user {
    useradd -d /home/${DEPLOYER_USER} -m -s /bin/bash ${DEPLOYER_USER}
    usermod -aG ${WWW_USER_GROUP} ${DEPLOYER_USER}

    sudo -H -u ${DEPLOYER_USER} sh -c 'echo "umask 022" >> ~/.bashrc'

    echo "${DEPLOYER_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

    chown ${DEPLOYER_USER}:${WWW_USER_GROUP} /var/www/html
    chmod g+s /var/www/html

    sudo -H -u ${DEPLOYER_USER} sh -c 'ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa'
    chown -R ${DEPLOYER_USER}.${WWW_USER_GROUP} /var/www/
}

function install_basic_softwares {
    apt install -y curl git build-essential unzip supervisor
}

function install_php {
    # php 7.2, 7.3, 7.4 都装吧！老的代码都用得到！sudo update-alternatives --config php 来切换版本
    apt install -y php7.2 php7.2-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,sqlite3,exif,imagick,recode,tidy,wddx,xmlrpc,mongodb,recode,wddx} # 验证方法 sudo systemctl status php7.2-fpm， 7.2也得装 发现没装7.2，直接用7.4的话，en.k-reach.com, en.xixisys.com报502错误！
    apt install -y php7.3 php7.3-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,sqlite3,exif,imagick,recode,tidy,wddx,xmlrpc,mongodb,recode,wddx}  # 7.3 需要的话 也可装！reachkeeper需要7.3
    apt install -y php7.4 php7.4-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,sqlite3,imagick,tidy,xmlrpc,mongodb} # 验证方法 sudo systemctl status php7.4-fpm
}

function install_composer {
    curl https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
    chmod +x /usr/local/bin/composer
    sudo -H -u ${WWW_USER} sh -c  'cd ~ && composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer/'
}

function install_others {
    apt install -y nginx python-certbot-nginx redis-server sqlite3 mysql-server
    chown -R ${WWW_USER}.${WWW_USER_GROUP} /var/www/
    systemctl enable nginx.service
}

function install_wormhole {
    # snap install wormhole # 这个会导致 wormhole receive 经常出现 permission denied
    sudo apt -y install magic-wormhole
}

call_function init_system "正在初始化系统" ${LOG_PATH}
call_function init_repositories "正在初始化系统软件库" ${LOG_PATH}
call_function install_basic_softwares "正在安装基本的软件" ${LOG_PATH}
call_function install_php "正在安装 PHP" ${LOG_PATH}
call_function install_others "正在安装 Nginx Redis Sqlite3 mysql-server" ${LOG_PATH}
call_function install_composer "正在安装 Composer" ${LOG_PATH}
call_function init_deployer_user "正在初始化 deployer 用户" ${LOG_PATH}
call_function install_wormhole "正在安装 Wormhole" ${LOG_PATH}

echo "安装完毕! 请注意 nginx, redis, mysql-server需要做配置"

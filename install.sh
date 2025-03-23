#!/bin/bash

set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
LOG_PATH="${CURRENT_DIR}/ubuntu-init.log"

source ${CURRENT_DIR}/common.sh  # 注意！！这里导入了 common.sh 所以手动执行以下命令时 要把 ${} 变量直接手动写进去！

check_root

function init_system {
    apt update  # 新系统首次 可以再升级下  apt upgrade
    apt install -y software-properties-common
    apt update
}

function init_repositories {
    add-apt-repository universe -y
    add-apt-repository ppa:ondrej/php -y # 同时安装php7.4 在腾讯的上海区 ubuntu 18.04 LTS 安装失败 24.04 LTS成功的
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
    apt install -y curl git build-essential unzip supervisor jq
}

function install_php {
    # php 7.2, 7.3, 7.4 都装吧！老的代码都用得到！sudo update-alternatives --config php 来切换版本  
    # # 验证方法 sudo systemctl status php7.2-fpm， 7.2也得装 发现没装7.2，直接用7.4的话，en.k-reach.com, en.xixisys.com报502错误！
    # 7.3 需要的话 也可装！reachkeeper需要7.3
    # apt install -y php7.2 php7.2-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,memcached,sqlite3,exif,imagick,recode,tidy,wddx,xmlrpc,mongodb,recode,wddx}
    # apt install -y php7.3 php7.3-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,memcached,sqlite3,exif,imagick,recode,tidy,wddx,xmlrpc,mongodb,recode,wddx}
    apt install -y php7.4 php7.4-{bcmath,cli,curl,fpm,gd,mbstring,mysql,opcache,readline,xml,zip,redis,memcached,memcache,ssh2,sqlite3,imagick,tidy,xmlrpc,mongodb,intl,soap}
}

function install_composer {
    curl https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
    chmod +x /usr/local/bin/composer
    sudo -H -u www-data sh -c  'cd ~ && composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer/'  # ${WWW_USER} 在24.04 LTS中读不到，直接写死 www-data好了；另外，执行时提示权限问题
    # 可以手动创建 /var/www/.composer 然后手动执行 chown www-data:www-data /var/www/.composer/ -R 先改为www-data用户先，再执行以上命令
    composer self-update --1  # 降为1版本
}

function install_certbot {
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot  # 创建符号链接
}

function install_others {
    apt install -y nginx redis-server memcached libmemcached-tools sqlite3 mysql-server
    chown -R ${WWW_USER}.${WWW_USER_GROUP} /var/www/
    systemctl enable nginx.service
}

function install_wormhole {
    # snap install wormhole # 这个会导致 wormhole receive 经常出现 permission denied
    sudo apt -y install magic-wormhole
}

function change_php74fpm_config {
    # 改动下php.ini配置
    mv /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.bak
    cp ${CURRENT_DIR}/templates/php.ini.original /etc/php/7.4/fpm/php.ini.original
    cp ${CURRENT_DIR}/templates/php.ini.upload.large /etc/php/7.4/fpm/php.ini.upload.large
    ln -s /etc/php/7.4/fpm/php.ini.original /etc/php/7.4/fpm/php.ini
    service php7.4-fpm restart
}   

call_function init_system "正在初始化系统" ${LOG_PATH}
call_function init_repositories "正在初始化系统软件库" ${LOG_PATH}
call_function install_basic_softwares "正在安装基本的软件" ${LOG_PATH}
call_function install_php "正在安装 PHP" ${LOG_PATH}
call_function install_certbot "正在安装 Certbot" ${LOG_PATH}
call_function install_others "正在安装 Nginx Redis Memcached Sqlite3 mysql-server" ${LOG_PATH}
call_function install_composer "正在安装 Composer" ${LOG_PATH}
call_function init_deployer_user "正在初始化 deployer 用户" ${LOG_PATH}
call_function install_wormhole "正在安装 Wormhole" ${LOG_PATH}
call_function change_php74fpm_config "/etc/php/7.4/fpm/php.ini 下配置做了调整" ${LOG_PATH}

echo "安装完毕! 请注意 nginx, redis, Memcached, mysql-server需要做配置"

#!/bin/bash
# 把.env 导入到环境变量中
export $(xargs <.env)

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/common.sh

# 须 root 用户执行！
check_root

read -r -p "请输入项目名（完整的访问网址（不含https://），如 www.example.com, en.example.com）：" project

[[ $project =~ ^[\.0-9a-zA-Z_\-]+$ ]] || {
    echo "项目名包含非法字符"
    exit 1
}

# 检查项目是否已存在，如已存在，终止脚本，避免带来损失！ 检查 /var/www/${project} 文件夹是否存在！
if [ ! -d "/var/www/${project}" ];then
 echo "成功！项目查重通过，是新项目，请继续下一步"
 else
 echo "失败！此项目已存在，无法创建！如有疑问，请联系管理员处理！脚本终止。"
 exit 1
fi

read -r -p "请输入站点域名（多个域名用空格隔开，完整的网址（不含https://），一般与项目名相同）：" domains

project_dir="/var/www/${project}"

echo "域名列表：${domains}"
echo "项目名：${project}"
echo "项目目录：${project_dir}"

read -r -p "是否确认？ [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        ;;
    *)
        echo "用户取消"
        exit 1
        ;;
esac

read -r -p "请输入项目类型【dzq/laravel/wp】 - dzq/lavavel用php7.2；wp用php7.4：" project_type

cat ${CURRENT_DIR}/templates/${project_type}-nginx_site_conf.tpl |
    sed "s|{{domains}}|${domains}|g" |
    sed "s|{{project}}|${project}|g" |
    sed "s|{{project_dir}}|${project_dir}|g" > /etc/nginx/sites-available/${project}.conf

ln -sf /etc/nginx/sites-available/${project}.conf /etc/nginx/sites-enabled/${project}.conf

echo "配置文件创建成功"

mkdir -p ${project_dir} && chown -R ${DEPLOYER_USER}.${WWW_USER_GROUP} ${project_dir}

systemctl restart nginx.service

echo "Nginx 重启成功"

if [ "$project_type" = "wp" ]; then

    read -r -p "是否导入最新版文件及数据？（y 最新版，N的话初始版） [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            wordpressFiles="wordpress.5.9.3-xixisys"
            wordpressSql="wordpress.5.9.3-xixisys.sql"
            ;;
        *)
            wordpressFiles="wordpress.5.9.3-xixisys-initial"
            wordpressSql="wordpress.5.9.3-xixisys-initial.sql"
            ;;
    esac

    # 部署后 执行手动安装过程  cp 文件到文件夹
    # cp /root/ubuntu-init/wordpress/wordpress-5.9.3-zh_CN.tar.gz ${project_dir}
    # cd ${project_dir} && tar zxvf ./wordpress-5.9.3-zh_CN.tar.gz
    # rm ${project_dir}/wordpress-5.9.3-zh_CN.tar.gz
    
    # 直接把安装后的文件+db一起导入
    cp /root/ubuntu-init/wordpress/${wordpressFiles} ${project_dir}/wordpress -r

    # 把输入的项目名 中的 . 替换为 _，定为db name，如www.example.com 转为 wp_www_example_com
    dbName=wp_${project//./_}

    # 生成 wp-config.php  文件 
    # 注意！wp-config-example 中涉及到的 AUTH_KEY 等值，与 wordpress.5.9.3-xixisys.sql、wordpress.5.9.3-xixisys-initial.sql 中存的一致
    # 后续如果要换 wordpress.5.9.3-xixisys.sql 这些sql，一定要从 wordpress.5.9.3-xixisys-initial.sql 重新配置一份，再改动，再保存到新的 wordpress.5.9.3-xixisys.sql
    cat ${CURRENT_DIR}/templates/wp-config-template.php |
    sed "s|{{dbName}}|${dbName}|g" |
    sed "s|{{dbWordpressUser}}|${dbWordpressUser}|g" |
    sed "s|{{dbWordpressPassword}}|${dbWordpressPassword}|g" > ${project_dir}/wp-config.php

    # 权限开小了，安装不了插件。尝试过，用户得设为www-data:www-data，否则很容易出错。其实所有文件均为755，wp-includes 也为755.
    # 见：https://www.wpdaxue.com/wordpress-file-read-and-write-permission.html 。这里提到的644（无 x），试过都不行。
    chown -R ${WWW_USER_GROUP}.${WWW_USER_GROUP} ${project_dir}/wordpress
    # wp-config.php owner改为 deployer，权限设为 444 (read only)
    chown ${DEPLOYER_USER}.${WWW_USER_GROUP} ${project_dir}/wp-config.php
    chmod -wx ${project_dir}/wp-config.php

    # 固定使用本地存的此版本 以配合后面 初始化数据库 wordpress.5.9.3-xixisys.sql的导入
    echo "成功！copy ${wordpressFiles} 文件复制完成。权限已改为：www-data:www-data"

    # 增加用户，创建数据库，给用户访问数据库权限
    mysql -u ${dbAdminUser} -p${dbAdminPassword} -e "
        create user if not exists '${dbWordpressUser}'@'localhost' identified by '${dbWordpressPassword}';
        create database if not exists ${dbName} default character set utf8mb4 collate utf8mb4_unicode_ci;
        grant all privileges on ${dbName}.* to ${dbWordpressUser}@'localhost' identified by '${dbWordpressPassword}';
        flush privileges;
    "
    # 导入数据
    mysql -u ${dbWordpressUser} -p${dbWordpressPassword} -D${dbName}</root/ubuntu-init/wordpress/${wordpressSql}
    echo "成功！创建数据库：${dbName} 成功，授予${dbWordpressUser}用户完整权限，已导入初始数据 ${wordpressSql}"

    # 替换导入数据库中的url，导入的数据库中是 wp15.xixisys.com  需要提前在服务器上安装好 /root/Search-Replace-DB
    cd /root/ubuntu-init/vendor/interconnectit/search-replace-db && php srdb.cli.php -h localhost -n ${dbName} -u ${dbWordpressUser} -p "${dbWordpressPassword}" -s "wp15.xixisys.com" -r "${project}"
    echo "成功！使用 Search-Replace-DB 将导入的数据sql 中的url 替换。不用理会显示的预警文字，功能正常的。预警文字：results: Incomplete or ill-typed serialization data:: This is usually caused by a plugin storing classes as a
            serialised string which other PHP classes can't then access..."

    read -r -p "是否部署ssl？须提前设置好DNS！ [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            certbot --nginx -d ${domains} ;;
        *)
            echo "取消部署ssl，请配置dns后执行 sudo certbot --nginx -d $domains"
        exit 1
        ;;
    esac
fi
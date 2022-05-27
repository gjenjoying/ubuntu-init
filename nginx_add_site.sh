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

read -r -p "请输入项目类型【dzq/laravel】 - dzq/lavavel用php7.2；wp用php7.4，另外脚本" project_type

cat ${CURRENT_DIR}/templates/${project_type}-nginx_site_conf.tpl |
    sed "s|{{domains}}|${domains}|g" |
    sed "s|{{project}}|${project}|g" |
    sed "s|{{project_dir}}|${project_dir}|g" > /etc/nginx/sites-available/${project}.conf

ln -sf /etc/nginx/sites-available/${project}.conf /etc/nginx/sites-enabled/${project}.conf

echo "配置文件创建成功"

mkdir -p ${project_dir} && chown -R ${DEPLOYER_USER}.${WWW_USER_GROUP} ${project_dir}

systemctl restart nginx.service

echo "Nginx 重启成功"

read -r -p "是否部署ssl？须提前设置好DNS！ [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            certbot --nginx -d ${domains} ;;
        *)
            echo "取消部署ssl，请配置dns后执行 sudo certbot --nginx -d $domains"
        exit 1
        ;;
    esac

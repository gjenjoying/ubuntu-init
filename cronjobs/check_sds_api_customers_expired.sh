#!/bin/bash
# 把.env 导入到环境变量中 需要在项目文件根目录中运行脚本才能读取到此 .env 不能在cronjobs中运行
# cronjob执行时 可以 cd path && cronjobs/xxx.sh 来执行
export $(xargs <.env)

CurrentTime=`date -R`
echo "Today is $CurrentTime"
PATH=/home/deployer/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

# -e 执行 -s 去掉mysql 报文，不然输出的不光是结果了，还是执行的语句 没法使用
expiredApiCustomersCount=$(mysql -u ${dbAdminUser} -p${dbAdminPassword} -se "
    SELECT EXISTS(SELECT 1 FROM xixi.api_customers WHERE (expired_at < date(now()) AND is_active!=2));
    ")
# expiredApiCustomersCount 结果为 0，代表没找到记录（即所有都没过期）；非0时，代表有过期的 需要处理！暂时没做把过期的人显示出来之类的事情，毕竟量很小！直接人工处理即可！
if [ "$expiredApiCustomersCount" == "0" ];then
    echo "无须处理！"
else
    echo "有接入SDS的 API 客户过期了，请查看DB: xixi.api_customers 或 AWS China API gateway"
    # 使用 msmtp 发送邮件到多个收件人
    {
        echo "From: \"XiXisys System\" <peter@reachlinked.com>"
	echo "Subject: SDS API 付费接入客户过期 请尽快联系续费"
        echo "To: revival.wgj@gmail.com, tiffany@xixisys.com, hxd@xixisys.com"
	echo "Content-Type: text/plain; charset=UTF-8"
    	echo "MIME-Version: 1.0"
        echo
        echo "有接入SDS的 API 客户过期了，请查看DB: xixi.api_customers 或 AWS China API gateway。如果要停发邮件提醒，可暂时先把is_active 改成2（代表没续费，但不需要邮件提醒）！"
    } | msmtp -a zoho revival.wgj@gmail.com tiffany@xixisys.com hxd@xixisys.com
fi

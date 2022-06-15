#!/bin/bash 

# 参考：https://blog.kdyzm.cn/post/20
# 先用脚本删除
/usr/local/qcloud/stargate/admin/uninstall.sh
/usr/local/qcloud/YunJing/uninst.sh
/usr/local/qcloud/monitor/barad/admin/uninstall.sh

# 删除 tat_agent
systemctl stop tat_agent
systemctl disable tat_agent
rm -f /etc/systemd/system/tat_agent.service

# 删除 secu-tcs-agent
process=(sap100 secu-tcs-agent sgagent64 barad_agent agent agentPlugInD pvdriver ) 
for i in ${process[@]} 
do
for A in $(ps aux |grep $i |grep -v grep |awk '{print $2}') 
do
kill -9 $A 
done 
done 

ps -A | grep agent check
echo "ps -A | grep agent check 执行后，如无任何显示，则删光了；如有，看看是否是自己的 "
echo "root 用户下，执行 crontab -e，删除腾讯相关的"
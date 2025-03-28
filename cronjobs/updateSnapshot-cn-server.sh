#!/bin/bash
# 创建一个变量来存储所有输出
output=""

# 把.env 导入到环境变量中
export $(xargs <.env)

output+="tencent-cn 服务器更新快照！(脚本在 其它服务器（如tencent-cn）上root用户下crontab中运行)\n\n"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
tccli lighthouse DescribeSnapshots --cli-unfold-argument --region ${tencentRegionCN} --Filters.0.Name instance-id --Filters.0.Values ${tencentInstanceCNid} > snapshots.json


OldestSnapshotId=$(jq .SnapshotSet[-1].SnapshotId snapshots.json)
OldestSnapshotId=${OldestSnapshotId//\"/}
SnapshotTotalCount=$(jq .TotalCount snapshots.json)

leftSnapshotState=$(jq .SnapshotSet[0].SnapshotState snapshots.json)
leftSnapshotState=${leftSnapshotState//\"/}

if [ "$leftSnapshotState" == "NORMAL" ];then
    output+="保留的Snapshot 状态正常！\n\n"
else
    output+="！！！出错！！！保留的Snapshot有问题！请到腾讯后台查看！\n\n"
fi

output+="执行脚本的服务器时间如下：\n"
output+="$(date -R)\n\n"

output+="实际执行了 更新快照、镜像操作的服务器（${tencentRegionCN}）的时间如下：\n"
output+="$(TZ=${tencentRegionCNTZ} date -R)\n\n"

output+="此时英国时间如下：\n"
output+="$(TZ=Europe/London date -R)\n\n"

output+="There're $SnapshotTotalCount snapshots. The Oldest SnapshotId is: $OldestSnapshotId\n\n"

tccli lighthouse DeleteSnapshots --cli-unfold-argument --region ${tencentRegionCN} --SnapshotIds $OldestSnapshotId
output+="Snapshot Id $OldestSnapshotId has been deleted\n\n"

sleep 30s

tccli lighthouse CreateInstanceSnapshot --cli-unfold-argument --region ${tencentRegionCN} --InstanceId ${tencentInstanceCNid} > snapshots.json
output+="$(cat snapshots.json)\n\n"

NewSnapshotId=$(jq .SnapshotId snapshots.json)
output+="New snapshot Id $NewSnapshotId is currently under creating, it may takes some minutes. Please wait a while to proceed other scripts.\n"

# 同时显示到控制台
echo -e "$output"

# 如果脚本执行成功，发送邮件
if [ $? -eq 0 ]; then
    {
    echo "Subject: XiXisys-CN Snapshot Update Success"
    echo "From: peter@reachlinked.com"
    echo "To: revival.wgj@gmail.com"
    echo
    echo -e "$output"
    } | msmtp -a zoho revival.wgj@gmail.com
fi

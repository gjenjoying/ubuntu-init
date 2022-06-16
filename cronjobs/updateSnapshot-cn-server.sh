#!/bin/bash
# 把.env 导入到环境变量中 需要在项目文件根目录中运行脚本才能读取到此 .env 不能在cronjobs中运行
# cronjob执行时 可以 cd path && cronjobs/xxx.sh 来执行
export $(xargs <.env)

echo "tencent-cn 服务器更新快照！(脚本在 其它服务器（如tencent-cn）上root用户下crontab中运行)"

# 需要先安装 tccli https://cloud.tencent.com/document/product/440/34011
# 文档：https://cloud.tencent.com/document/api/1207/54388
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
tccli lighthouse DescribeSnapshots --cli-unfold-argument --region ${tencentRegionCN} > snapshots.json
OldestSnapshotId=$(jq .SnapshotSet[-1].SnapshotId snapshots.json)
OldestSnapshotId=${OldestSnapshotId//\"/}
SnapshotTotalCount=$(jq .TotalCount snapshots.json)

leftSnapshotState=$(jq .SnapshotSet[0].SnapshotState snapshots.json)
leftSnapshotState=${leftSnapshotState//\"/}

if [ "$leftSnapshotState" == "NORMAL" ];then
		echo "保留的Snapshot 状态正常！"
	else
		echo "！！！出错！！！保留的Snapshot有问题！请到腾讯后台查看！"
fi

timedatectl # 显示运行脚本的服务器的时间 时区
echo "实际执行了 更新快照、镜像操作的服务器（${tencentRegionCN}）的时间如下："
TZ=${tencentRegionCNTZ} date -R # 显示实际执行了 更新快照、镜像操作的服务器的时间

echo "There're $SnapshotTotalCount snapshots. The Oldest SnapshotId is: $OldestSnapshotId"

tccli lighthouse DeleteSnapshots --cli-unfold-argument --region ${tencentRegionCN} --SnapshotIds $OldestSnapshotId
echo "Snapshot Id $OldestSnapshotId has been deleted"

sleep 30s

tccli lighthouse CreateInstanceSnapshot --cli-unfold-argument --region ${tencentRegionCN} --InstanceId ${tencentInstanceCNid} > snapshots.json
cat snapshots.json

NewSnapshotId=$(jq .SnapshotId snapshots.json)
echo "New snapshot Id $NewSnapshotId is currently under creating, it may takes some minutes. Please wait a while to proceed other scripts."
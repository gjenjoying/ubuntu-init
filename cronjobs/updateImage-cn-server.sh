#!/bin/bash
timedatectl # 显示当前服务器时区
CurrentTime=`date -R`
echo "tencent-cn 服务器更新镜像！(脚本在 其它服务器（如tencent-cn）上root用户下crontab中运行)"

# 需要先安装 tccli https://cloud.tencent.com/document/product/440/34011
# 文档：https://cloud.tencent.com/document/api/1207/47689
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
tccli lighthouse DescribeBlueprints --cli-unfold-argument --region ap-shanghai --Filters.0.Name blueprint-type --Filters.0.Values PRIVATE > image.json
OldestImageId=$(jq .BlueprintSet[-1].BlueprintId image.json)
OldestImageId=${OldestImageId//\"/}
ImageTotalCount=$(jq .TotalCount image.json)

sleep 1s

tccli lighthouse DeleteBlueprints --cli-unfold-argument --region ap-shanghai --BlueprintIds $OldestImageId

sleep 30s

CurrentTimestamp=`date '+%s'`
tccli lighthouse CreateBlueprint --cli-unfold-argument --region ap-shanghai --BlueprintName $CurrentTimestamp --InstanceId lhins-0p4h990m > image.json
cat image.json

NewImageId=$(jq .BlueprintId image.json)

sleep 120s
tccli lighthouse DescribeBlueprints --cli-unfold-argument --region ap-shanghai --Filters.0.Name blueprint-type --Filters.0.Values PRIVATE --Filters.1.Name blueprint-state --Filters.1.Values NORMAL > image.json
ImageTotalCountValid=$(jq .TotalCount image.json)

echo "!!!$ImageTotalCountValid VALID images!!!Total: $ImageTotalCount images! 如果不是5个，等个5天看看，如果没变成5个，进腾讯后台检查！"
echo "Today is $CurrentTime （注：此为运营此脚本的服务器时间，而非执行快照/脚本更新的服务器时间）"
echo "The Oldest ImageId is: $OldestImageId"
echo "Image Id $OldestImageId has been deleted"
echo "New Image Id $NewImageId is created"
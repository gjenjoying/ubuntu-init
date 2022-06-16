#!/bin/bash

# 此脚本只能在 ubuntu上运行，不能在mac上运行。本地可以打开 multipass 开ubuntu运行
export $(xargs <.env)
echo "当前时间："
date -R
change='-1'
echo "!!改动时间 ${change} 后，如下："
echo "北京:"
date -R -d "${change} hours" 
echo "美国:"
TZ=America/Los_Angeles date -R -d "${change} hours" 
echo "英国:"
TZ=Europe/London date -R -d "${change} hours" 
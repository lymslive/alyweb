#! /bin/bash
# 每天的定时任务

thisdir=/usr/local/nginx/html/tools
logfile=$thisdir/cron.log
# date >> $logfile

cd /usr/local/nginx/html/notebook/
/usr/bin/git pull

# 生成最近博客列表
# perl /usr/local/nginx/html/tools/blog_recent.pl
cd p
/usr/bin/make

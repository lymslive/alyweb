#! /usr/bin/env perl
# 简单合并 js 文件，将命令行参数当作文件名处理，输出处理结果至标准输出
# 所做操作：
# 删除注释
# 替换 /dev/family/ 路径
package mergejs;
use strict;
use warnings;

while (<>) {
	next if /^\s*$/;
	next if m{^\s*//};
	s{\s*//.*$}{};
	s/^\s*//g;
	# s/\s*$//g;
	s{/dev/family/}{/family/}g;
	print;
}


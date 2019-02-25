#! /usr/bin/env perl
package HTML;
use strict;
use warnings;

sub response
{
	my ($Title, $Body) = @_;
	# http header
	print "Content-type:text/html\n\n";

	# http content
	print <<EndOfHTML;
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width" />
		<title> $Title </title>
	</head>
	<body>
		$Body
	</body>
</html>
EndOfHTML

	return 0;
}

sub body
{
	my ($H1, $TableRows) = @_;

	my $Body = <<EndOfHTML;
<h1>$H1</h1>
<div id="family_table">
	<table border="1">
	$TableRows;
	</table>
</div>
<div id = "table_instruction">
	<h2>家谱表简单说明：</h2>
	<ul>
		<li> 收录同一祖先以下的子嗣血脉。祖先设为第 1 代，后续递增。也可收录配偶，代际前加一短横（取负数）以区别。
		<li> 原则上不分男女，都可收录，甚至女儿的后代也算血脉延续。有更多数据后可按需要再筛选。
		<li> 在表的末行可添加新成员。至少要填写所依的父亲或母亲，可填 ID 或姓名（不存在重名时）。
		<li> 新成员可先入库基本信息（姓名与父/母依存关系），后面再修改补充其他信息。
	</ul>
</div>
EndOfHTML

	return $Body;
}

sub table_head
{
	my ($var) = @_;
	
	my $html = <<EndOfHTML;
<tr>
	<td>编号</td>
	<td>姓名</td>
	<td>性别</td>
	<td>代际</td>
	<td>父亲</td>
	<td>母亲</td>
	<td>配偶</td>
	<td>生日</td>
	<td>忌日</td>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
EndOfHTML

	return $html
}

#! /usr/bin/env perl
package HTPL;
use utf8;
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
	$TableRows
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

	return $html;
}

sub table_row
{
	my ($row, $link) = @_;
	my ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday) = @$row;
	my $row_tail = '';
	if ($link) {
		my $modify = qq{<a href="#operate-form">修改</a>};
		my $remove = qq{<a href="?operate=remove&id=$id">删除</a>};
		$row_tail .= qq{	<td>$modify</td>\n};
		$row_tail .= qq{	<td>$remove</td>\n};
	}
	else {
		$row_tail .= qq{	<td>--</td>\n};
		$row_tail .= qq{	<td>--</td>\n};
	}
	my $html = <<EndOfHTML;
<tr>
	<td>$id</td>
	<td>$name</td>
	<td>$sex</td>
	<td>$level</td>
	<td>$father</td>
	<td>$mother</td>
	<td>$partner</td>
	<td>$birthday</td>
	<td>$deathday</td>
	$row_tail
</tr>
EndOfHTML
	return $html;
}

sub table_form
{
	my ($var) = @_;
	
	my $html = <<EndOfHTML;
<form action="view_table.cgi" method="post">
	<tr>
		<td colspan="9"><span id="operate-form">待操作方式：</span>
			新增<input type="radio" name="operate" value="create" checked="checked"/>，
			修改<input type="radio" name="operate" value="modify"/>
		</td>
	</tr>
	<tr>
		<td><input size="3" type="text" name="mine_id"/></td>
		<td><input size="3" type="text" name="mine_name"/></td>
		<td><select name="sex">
				<option value="1">男</option>
				<option value="0">女</option>
			</select></td>
		<td>--</td>
		<td><input size="3" type="text" name="father"/></td>
		<td><input size="3" type="text" name="mother"/></td>
		<td><input size="3" type="text" name="partner"/></td>
		<td><input size="5" type="date" name="birthday"/></td>
		<td><input size="5" type="date" name="deathday"/></td>
		<td><input type="submit" value="提交"/></td>
		<td><input type="reset" value="重置"/></td>
	</tr>
</form>
EndOfHTML

	return $html;
}

1;
__END__

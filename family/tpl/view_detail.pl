#! /usr/bin/env perl
package HTPL;
use utf8;
use strict;
use warnings;

sub response
{
	my ($Title, $Body) = @_;
	$Title ||= '谭氏家谱-成员详情';
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
	my ($H1, $MemberHeader, $MemberRelation, $OperateResult, $TableForm) = @_;
	$H1 ||= '谭氏年浪翁家谱成员细览';

	my $Body = <<EndOfHTML;
<h1>$H1</h1>
<div id="member-header">
	$MemberHeader
</div>
<hr>
<div id="member-relation">
	$MemberRelation
</div>
<div id="operate-form">
	<p> 资料：$OperateResult</p>
	$TableForm
</div>
<div id = "form_tips">
	<h2>修改说明：</h2>
	<ul>
		<li> 成员 ID 已固定，可以修改其他资料
		<li> 父亲、母亲、配偶三项可填姓名，除非有重名必须填 ID
	</ul>
</div>
EndOfHTML

	return $Body;
}

# eg.
# 10025 | 谭水龙 | 第 4 代
sub member_header
{
	my ($id, $name, $level) = @_;
	if ($level > 0) {
		return "$id | $name | 第 $level 直系";
	}
	else {
		return "$id | $name | 第 $level 旁系";
	}
}

# 提供：三个数组列表
sub member_relation
{
	my ($root, $son, $daughter) = @_;
	my $chain = join(' / ', @$root);
	my $html = qq{<p>承袭：$chain</p\n};
	if ($son && scalar(@$son) > 0) {
		my $child = join(' / ', @$son);
		$html .= qq{<p>儿子：$child</p\n};
	}
	if ($daughter && scalar(@$daughter) > 0) {
		my $child = join(' / ', @$daughter);
		$html .= qq{<p>儿子：$child</p\n};
	}
	return $html;
}

sub table_form
{
	my ($row) = @_;
	my ($id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday) = @$row;

	my ($sex_str, $man, $woman);
	if ($sex == 1) {
		$sex_str = '男';
		$man = 'selected';
		$woman = '';
	}
	else{
		$sex_str = '女';
		$man = '';
		$woman = 'selected';
	}

	my $html = <<EndOfHTML;
<form action="?operate=modify&mine_id=$id" method="post">
	<table>
		<tr>
			<td>编号：</td>
			<td>$id</td>
		</tr>
		<tr>
			<td>姓名：</td>
			<td>$name</td>
			<td><input size="3" type="text" name="mine_name" /></td>
		</tr>
		<tr>
			<td>性别：</td>
			<td>$sex_str</td>
			<td>
				<select name="sex">
					<option value="1" selected="$man">男</option>
					<option value="0" selected="$woman">女</option>
				</select>
			</td>
		</tr>
		<tr>
			<td>父亲：</td>
			<td>$father</td>
			<td><input size="3" type="text" name="father"</td>
		</tr>
		<tr>
			<td>母亲：</td>
			<td>$mother</td>
			<td><input size="3" type="text" name="mother"/></td>
		</tr>
		<tr>
			<td>配偶：</td>
			<td>$partner</td>
			<td><input size="3" type="text" name="partner"/></td>
		</tr>
		<tr>
			<td>生日：</td>
			<td>$birthday</td>
			<td><input size="5" type="date" name="birthday"/></td>
		</tr>
		<tr>
			<td>忌日：</td>
			<td>$deathday</td>
			<td><input size="5" type="date" name="deathday"/></td>
		</tr>
		<tr>
			<td></td>
			<td><input type="reset" value="不必修改" /></td>
			<td><input type="submit" value="修改资料" /></td>
		</tr>
	</table>
	简介：<br/>
	<textarea name="desc" rows="10" cols="30" >（暂不保存，敬请期待）</textarea><br/>
</form>
EndOfHTML
	return $html
}

1;
__END__

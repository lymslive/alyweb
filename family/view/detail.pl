#! /usr/bin/env perl
package HTPL;
use utf8;
use strict;
use warnings;

my @sex_mark = qw(♀ ♂);

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '谭氏家谱-成员详情';
	$self->{body} = '';
	$self->{H1} = '谭氏年浪翁家谱成员细览';
	bless $self, $class;
	return $self;
}

sub runout
{
	my ($self, $data, $LOG) = @_;
	$self->generate($data, $LOG);
	return $self->response();
}

sub response
{
	my ($self) = @_;
	print "Content-type:text/html\n\n";

	print <<EndOfHTML;
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width" />
		<script src="js/ctuil.js"></script>
		<title> $self->{title} </title>
	</head>
	<body>
		$self->{body}
	</body>
</html>
EndOfHTML

	return 0;
}

sub body
{
	my ($self, $MemberHeader, $MemberRelation, $OperateResult, $TableForm) = @_;

	my $Body = <<EndOfHTML;
<h1>$self->{H1}</h1>
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

sub generate
{
	my ($self, $data, $LOG) = @_;
	if (!$data || $data->{error}) {
		return on_error('查询成员详情失败');
	}

	my $null = '--';
	my $id = $data->{id};
	my $name = $data->{name};
	my $sex = $data->{sex};
	my $level = $data->{level};
	my $father = $data->{father};
	my $mother = $data->{mother};
	my $partner = $data->{partner};
	my $birthday = $data->{birthday} // $null;
	my $deathday = $data->{deathday} // $null;
	
	my $MemberHeader = s_member_header($id, $name, $level);

	my $root = $data->{root};
	my $child = $data->{child};
	my $MemberRelation = s_member_relation($root, $child, $level);

	my $OperateResult = $data->{operate_result};
	my $TableForm = s_table_form([$id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday]);

	$self->{body} = $self->body($MemberHeader, $MemberRelation, $OperateResult, $TableForm);
	if ($LOG->{debug}) {
		$self->{body} .= s_debug_log($LOG);
	}

	return 0;
}

sub on_error
{
	my ($self, $msg) = @_;
	$self->{body} = $msg;
	return -1;
}

sub s_debug_log
{
	my ($LOG) = @_;
	my $display = ($LOG->{debug} > 0) ? 'inline' : 'none';
	my $log = $LOG->to_webline();
	my $html = <<EndOfHTML;
	<hr>
	<div><a href="javascript:void(0);" onclick="DivHide()">网页日志</a></div>
<div id="debug_log" style="display:$display">
	$log
</div>
EndOfHTML
	return $html;
}

# eg.
# 10025 | 谭水龙 | 第 4 代
sub s_member_header
{
	my ($id, $name, $level) = @_;
	my $left = '';
	if ($level > 0) {
		$left = "$id | $name | 第 +$level 代直系";
	}
	else {
		$left = "$id | $name | 第 $level 代旁系";
	}
	my $right = qq{<a href="view_table.cgi">回列表</a>};
	return "$left -- ($right)";
}

sub s_link_to
{
	my ($member) = @_;
	if ($member && $member->{id} && $member->{name}) {
		return qq{<a href="?mine_id=$member->{id}">$member->{name}</a>};
	}
	return '';
}

# 生成上下级关系
sub s_member_relation
{
	my ($root, $child, $level) = @_;
	my $html = '';
	if ($level > 0) {
		if ($level == 1) {
			$html .= qq{<p>先人：（本支祖先）</p>\n};
		}
		elsif ($root && @$root) {
			my @root_name = ();
			foreach my $parent (@$root) {
				my $html = s_link_to($parent);
				my $sex = $parent->{sex};
				$html .= $sex_mark[$sex];
				push(@root_name, $html);
			}
			
			my $root_name = join(' / ', @root_name);
			$html .= qq{<p>先人：$root_name</p>\n};
		}
		else {
			$html .= qq{<p>先人：（数据错误缺失）</p>\n};
		}
	}
	else {
		$html .= qq{<p>先人：（旁系配偶不记录）</p>\n};
	}

	if ($child && @$child) {
		my @child_name = ();
		foreach my $kid (@$child) {
			my $html = s_link_to($kid);
			my $sex = $kid->{sex};
			$html .= $sex_mark[$sex];
			push(@child_name, $html);
		}
		
		my $child_name = join(' 、 ', @child_name);
		$html .= qq{<p>后人：$child_name</p>\n};
	}

	return $html;
}

sub s_table_form
{
	my ($row) = @_;
	my ($id, $name, $sex, $level, $father_ref, $mother_ref, $partner_ref, $birthday, $deathday) = @$row;

	my $father = s_link_to($father_ref);
	my $mother = s_link_to($mother_ref);
	my $partner = s_link_to($partner_ref);

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
	$sex_str .= $sex_mark[$sex];

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
					<option value="">请选择</option>
					<option value="1">男</option>
					<option value="0">女</option>
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

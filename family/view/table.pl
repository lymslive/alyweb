#! /usr/bin/env perl
package HTPL;
use utf8;
use strict;
use warnings;

# 控制是否显示表格尾列的操作链接
my $OPERATE = 0;
sub show_operate
{
	my ($show) = @_;
	$OPERATE = $show;
}

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '谭氏家谱网-成员列表';
	$self->{body} = '';
	$self->{H1} = '谭氏年浪翁子嗣家谱表';
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
	my ($self, $TableRows) = @_;

	my $Body = <<EndOfHTML;
<h1>$self->{H1}</h1>
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
		<li> 新成员可先入库基本信息（姓名与父/母依存关系），再去修改详情页修改。本页快捷修改须指定编号。
		<li> 删除数据须谨慎。本页地址暂不要外传，操作修改尚未作登陆验证。
		<li> 该页面主要为初步测试服务端 api ，有懂前端会做网页的兄弟可联系我优化与重设计网页。
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

	show_operate($LOG->{debug});

	my $TableRows = s_table($data);
	$self->{body} = $self->body($TableRows);
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

sub s_table
{
	my ($data) = @_;
	
	my $th = s_table_head();
	my @html = ($th);
	foreach my $row (@{$data->{rows}}) {
		push @html, s_table_row($row, 1);
	}

	my $count = scalar(@{$data->{rows}});
	push @html, s_table_sumary($count);

	my ($hot_row, $hot_msg);
	if ($data->{removed}) {
		$hot_row = $data->{removed};
		$hot_msg = '刚删除的行：';
	}
	elsif ($data->{modified}) {
		$hot_row = $data->{modified};
		$hot_msg = '刚修改的行：';
	}
	elsif ($data->{created}) {
		$hot_row = $data->{created};
		$hot_msg = '刚增加的行：';
	}

	if ($hot_row) {
		if ($hot_row->{error}) {
			my $hot_html = s_operate_msg("操作失败：" . $hot_row->{error});
			push @html, $hot_html;
		}
		else {
			my $hot_html = s_operate_msg("操作成功，" . $hot_msg);
			$hot_html .= s_table_row($hot_row);
			push @html, $hot_html;
		}
	}

	push @html, s_table_form();
	push @html, $th;

	return join("\n", @html);
}

sub s_table_head
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
	<td>元配</td>
	<td>生日</td>
	<td>忌日</td>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
EndOfHTML

	return $html;
}

sub s_detail_link
{
	my ($id, $text) = @_;
	my $html = qq{<a href="view_detail.cgi?mine_id=$id">$text<a>};
	return $html;
}

sub s_table_row
{
	my ($row, $link) = @_;
	my $null = '--';
	my $id = $row->{F_id} // $null;
	my $name = $row->{F_name} // $null;
	my $sex = $row->{F_sex} // $null;
	$sex = ($sex == 1 ? '男' : '女');
	my $level = $row->{F_level} // $null;
	my $father = $row->{F_father} // $null;
	my $mother = $row->{F_mother} // $null;
	my $partner = $row->{F_partner} // $null;
	my $birthday = $row->{F_birthday} // $null;
	my $deathday = $row->{F_deathday} // $null;

	my $row_tail = '';
	if ($link) {
		my $modify = qq{<a href="view_detail.cgi?mine_id=$id">详情</a>};
		my $remove = qq{<a href="javascript:void(0)">删除</a>};
		if ($OPERATE) {
			$remove = qq{<a href="?operate=remove&id=$id">删除</a>};
		}
		$row_tail .= qq{	<td>$modify</td>\n};
		$row_tail .= qq{	<td>$remove</td>\n};
	}
	else {
		$row_tail .= qq{	<td>--</td>\n};
		$row_tail .= qq{	<td>--</td>\n};
	}

	if ($level > 0) {
		$level = "+$level";
	}

	# 转换链接
	$id = s_detail_link($id, $id);
	$name = s_detail_link($id, $name);
	if ($row->{F_father} && $row->{father_name}) {
		$father = s_detail_link($row->{F_father}, $row->{father_name});
	}
	if ($row->{F_mother} && $row->{mother_name}) {
		$mother = s_detail_link($row->{F_mother}, $row->{mother_name});
	}
	if ($row->{F_partner} && $row->{partner_name}) {
		$partner = s_detail_link($row->{F_partner}, $row->{partner_name});
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

sub s_table_sumary
{
	my ($count) = @_;
	
	my $html = <<EndOfHTML;
	<tr>
		<td colspan="9"><span id="table-sumary">小计：</span>
		共收录 $count 名家族成员。再接再励！
		</td>
	</tr>
EndOfHTML

	return $html;
}

# 操作失败提示
sub s_operate_msg
{
	my ($msg) = @_;
	my $html = <<EndOfHTML;
<tr>
	<td colspan="9">$msg</td>
</tr>
EndOfHTML
	return $html;
}

sub s_table_form
{
	my ($var) = @_;
	
	my $html = <<EndOfHTML;
<form action="#table-sumary" method="post">
	<tr>
		<td colspan="9"><span id="operate-form">操作：</span>
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

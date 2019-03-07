#! /usr/bin/env perl
package view::table;
use utf8;
use strict;
use warnings;
use parent qw(HTPL);

# 控制是否显示表格尾列的删除链接
my $DEL_LINK = 0;

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '谭氏家谱网-成员列表';
	$self->{body} = '';
	$self->{H1} = '谭氏年浪翁子嗣家谱表';
	$self->{js} = ['js/cutil.js', 'js/table.js'];
	bless $self, $class;
	return $self;
}

sub body
{
	my ($self, $TableRows) = @_;

	return <<EndOfHTML;
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
		<li> 在表的末行可添加新成员。至少要填写所依的父亲或母亲的 ID 或姓名（不存在重名时），且父或母必须先入库。
		<li> 旁系配偶不能直接入库，只能通过修改配偶时自动添加。
		<li> 本页快捷修改资料须指定编号，推荐在个人详情页修改。
	</ul>
</div>
EndOfHTML
}

sub generate
{
	my ($self, $data, $LOG) = @_;
	if (!$data || $data->{error}) {
		return $self->on_error('查询成员详情失败');
	}

	$DEL_LINK = $LOG->{debug};

	my $TableRows = s_table($data);
	$self->{body} = s_login_bar($data);
	$self->{body} .= $self->body($TableRows);
	if ($LOG->{debug}) {
		$self->{body} .= HTPL::LOG($LOG);
	}

	return 0;
}

sub s_login_bar
{
	my ($data) = @_;

	my $login = '';
	if ($data->{COOKIE} && $data->{COOKIE}->{uid}) {
		my $cookie = $data->{COOKIE}->{uid};
		$login = qq{已登陆：<a href="detail.cgi">$cookie</a>};
	}
	else {
		$login = qq{<a href="login.cgi">未登陆</a>};
	}

	return <<EndOfHTML;
	<div id="login-bar">
		<span>$login<span>
	</div>
EndOfHTML
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
			$hot_html .= s_table_row($hot_row->{row});
			push @html, $hot_html;
		}
	}

	push @html, s_table_form();
	push @html, $th;

	return join("", @html);
}

sub s_table_head
{
	my ($var) = @_;
	
	return <<EndOfHTML;
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
</tr>
EndOfHTML
}

sub s_detail_link
{
	my ($id, $text) = @_;
	my $html = qq{<a href="detail.cgi?mine=$id">$text<a>};
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
		my $modify = HTPL::LINK('详情', "detail.cgi?mine=$id");
		my $remove = $DEL_LINK
			? HTPL::LINK('删除', "?operate=remove&id=$id")
			: HTPL::LINK('删除', 0);
		$row_tail = <<EOF
	<td>$modify</td>
	<td>$remove</td>
EOF
	}

	if ($level > 0) {
		$level = "+$level";
	}

	# 转换链接
	my $id_link = s_detail_link($id, $id);
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

	return <<EndOfHTML;
<tr>
	<td>$id_link</td>
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
}

sub s_table_sumary
{
	my ($count) = @_;
	
	return <<EndOfHTML;
	<tr>
		<td colspan="9"><span id="table-sumary">小计：</span>
		共收录 $count 名家族成员。再接再励！
		</td>
	</tr>
EndOfHTML
}

# 操作失败提示
sub s_operate_msg
{
	my ($msg) = @_;
	return <<EndOfHTML;
<tr>
	<td colspan="9">$msg</td>
</tr>
EndOfHTML
}

sub s_table_form
{
	my ($var) = @_;
	
	return <<EndOfHTML;
<form name='operate-form' action="#table-sumary" method="post">
	<tr>
		<td colspan="9"><span>操作：</span>
			新增<input type="radio" name="operate" value="create" checked="checked"/>，
			修改<input type="radio" name="operate" value="modify"/>
			操作口令：<input size="6" type="password" name="operkey" value="123456"/>
			<input type="hidden" name="oper_key" value=""/>
		</td>
	</tr>
	<tr>
		<td><input size="3" type="number" name="mine_id"/></td>
		<td><input size="3" type="text" name="mine_name"/></td>
		<td><select name="sex">
				<option value="">--</option>
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
}

1;
__END__

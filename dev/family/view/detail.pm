#! /usr/bin/env perl
package view::detail;
use utf8;
use strict;
use warnings;
use parent qw(HTPL);

my @sex_mark = qw(♀ ♂);

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '谭氏家谱-成员详情';
	$self->{body} = '';
	$self->{H1} = '谭氏年浪翁家谱成员细览';
	$self->{js} = ['js/cutil.js', 'js/detail.js'];
	bless $self, $class;
	return $self;
}

sub body
{
	my ($self, $OperateResult, $TableForm) = @_;

	return <<EndOfHTML;
<div id="operate-form">
	<p> 资料：$OperateResult</p>
	$TableForm
</div>
<div id = "form_tips">
	<h2>本页说明：</h2>
	<ul>
		<li> 成员资料右侧输入框可对照着修改，不用改的项目不需管
		<li> 父亲、母亲、配偶三项可填姓名，除非有重名必须填 ID
		<li> 旁系配偶不能再录入父母等其他关系
		<li> 提交配偶资料后，在下方点击“扩展：增加子女”可快捷录入后代
		<li> 同一脉的女儿的后代也可入库
		<li> 点击有关系的名字链接，可进入相应的资料页，或在上方直接输入姓名/编号查找
	</ul>
</div>
EndOfHTML
}

sub generate
{
	my ($self, $data, $LOG) = @_;
	if (!$data || $data->{error}) {
		return $self->on_error($data->{error});
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
	
	my $root = $data->{root};
	my $child = $data->{child};

	my $OperateResult = $data->{operate_result};
	if (!$OperateResult) {
		$OperateResult = '（请核对修改）';
	}

	my $TableForm = s_table_form([$id, $name, $sex, $level, $father, $mother, $partner, $birthday, $deathday]);

	$self->{body} = s_login_bar($data);
	$self->{body} .= HTPL::H1($self->{H1});
	$self->{body} .= s_member_header($id, $name, $level);
	$self->{body} .= s_member_relation($root, $child, $level);
	$self->{body} .= $self->body($OperateResult, $TableForm);

	if ($LOG->{debug}) {
		$self->{body} .= HTPL::LOG($LOG);
	}

	return 0;
}

sub s_login_bar
{
	my ($data) = @_;
	
	my $login = '';
	my $login_id = 'login-bar';
	if ($data->{COOKIE} && $data->{COOKIE}->{uid}) {
		my $cookie = $data->{COOKIE}->{uid};
		$login = qq{已登陆：<a href="detail.cgi">$cookie</a>};
	}
	else {
		$login = qq{<a href="login.cgi">未登陆</a>};
		$login_id = 'login-foo';
	}

	my $right = qq{<a href="table.cgi">回列表</a>};
	return <<EndOfHTML;
	<div id="$login_id">
		<span>$login<span>：$right
	</div>
EndOfHTML
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

	return <<EndOfHTML;
	<div id="member-header">
		<form method="get">
			$left | 
			<input type="submit" value="查找其他"/>
			<input size="5" type="text" name="mine" required="required"/>
		</form>
	</div>
	<hr>
EndOfHTML
}

sub s_link_to
{
	my ($member) = @_;
	if ($member && $member->{id} && $member->{name}) {
		return qq{<a href="?mine=$member->{id}">$member->{name}</a>};
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

	return <<EndOfHTML;
	<div id="member-relation">
		$html
	</div>
EndOfHTML
}

sub s_table_form
{
	my ($row) = @_;
	my ($id, $name, $sex, $level, $father_ref, $mother_ref, $partner_ref, $birthday, $deathday) = @$row;

	my $father = s_link_to($father_ref);
	my $mother = s_link_to($mother_ref);
	my $partner = s_link_to($partner_ref);

	my ($sex_str);
	if ($sex == 1) {
		$sex_str = '男';
	}
	else{
		$sex_str = '女';
	}
	$sex_str .= $sex_mark[$sex];

	# 旁系成员（及顶级）不展示父母
	my $parent_row = '';
	if ($level > 1) {
		$parent_row = <<EndOfHTML;
		<tr>
			<td>父亲：</td>
			<td>$father</td>
			<td><input size="5" type="text" name="father"/></td>
		</tr>
		<tr>
			<td>母亲：</td>
			<td>$mother</td>
			<td><input size="5" type="text" name="mother"/></td>
		</tr>
EndOfHTML
	}

	# 有配偶时，扩展增加子女的选项
	my $add_child = '';
	if ($partner) {
		$add_child = <<EOF
<div class="folder">
	<div>
		<a href="javascript:void(0);" onclick="DivHide('add-child-form')" class="fold">扩展：增加子女</a>
	</div>
	<div id="add-child-form" style="display:none" class="foldOn">
		<form name="add-child" action="?mine_id=$id" method="post">
			姓名：<input size="5" type="text" name="child_name" required="required"/>
			<select name="child_sex" required="required">
				<option value="1">儿子</option>
				<option value="0">女儿</option>
			</select><br>
			生于：<input size="5" type="date" name="child_birthday"/> --
			<input size="5" type="date" name="child_deathday"/><br>
			<input type="hidden" name="operate" value="create"/>
			<input type="reset" value="放弃" />
			<input type="submit" value="提交" />
			口令：<input size="6" type="password" name="operkey" value="123456"/>
			<input type="hidden" name="oper_key" value=""/><br>
			<textarea name="child_desc" rows="10" cols="30" >（简介暂未支持）</textarea><br/>
		</form>
	</div>
</div>
EOF
	}

	return <<EndOfHTML;
<form name="modify-mine" action="?mine_id=$id" method="post">
	<table>
		<tr>
			<td>编号：</td>
			<td>$id</td>
		</tr>
		<tr>
			<td>姓名：</td>
			<td>$name</td>
			<td><input size="5" type="text" name="mine_name" /></td>
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
$parent_row
		<tr>
			<td>配偶：</td>
			<td>$partner</td>
			<td><input size="5" type="text" name="partner"/></td>
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
			<td><input type="hidden" name="oper_key" value="" /></td>
			<td>操作口令</td>
			<td><input size="6" type="password" name="operkey" value="123456" /></td>
		</tr>
		<tr>
			<td><input type="hidden" name="operate" value="modify"/></td>
			<td><input type="reset" value="不必修改" /></td>
			<td><input type="submit" value="修改资料" /></td>
		</tr>
	</table>
	<div class="folder">
		<div>
			<a href="javascript:void(0);" onclick="DivHide('mine-desc-inform')" class="fold">扩展：我的简介</a>
		</div>
		<div id="mine-desc-inform" style="display:inline" class="foldOff">
			<textarea name="desc" rows="10" cols="30" >（简介暂未支持）</textarea><br/>
		</div>
	</div>
</form>
$add_child
EndOfHTML
}

1;
__END__

#! /usr/bin/env perl
package view::login;
use strict;
use warnings;

use URI::Escape;

use parent qw(HTPL);
##-- Class --##

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '谭氏家谱网-登陆';
	$self->{body} = '';
	$self->{H1} = '谭氏家谱';
	bless $self, $class;
	return $self;
}

sub generate
{
	my ($self, $data, $LOG) = @_;
	if ($data->{error}) {
		return on_error($data->{error});
	}

	if ($data->{login}) {
		my $uid = $data->{uid};
		my $uname = $data->{uname};
		$uname = uri_escape_utf8($uname);
		$self->set_cookie("uid=$uid-$uname; path=/family");

		my $refresh = qq{<meta http-equiv="refresh" content="0; URL=detail.cgi?mine=$uid">};
		$self->{head} = $self->gen_head() . "\n$refresh";
		$self->{body} = '登陆成功，正在跳转……';
		return 0;
	}

	$self->{body} = HTPL::H1($self->{H1});
	$self->{body} .= s_login_form();
	$self->{body} .= s_login_tips();
	return 0;
}

sub s_login_form
{
	my ($var) = @_;
	return <<EndOfHTML;
	<div id="login-form">
		<form method="post">
			ID/姓名：
			<input type="text" name="uid" required="required"/>
			<input type="submit" value="登陆"/>
		</form>
	</div>
EndOfHTML
}

sub s_login_tips
{
	my ($var) = @_;
	
	return <<EndOfHTML;
	<div id="login-tips">
		<ul>
			<li> 凡入库家谱的名字即可免密登陆，有重名时须用 ID 登陆。
			<li> 登陆后立即浏览自己的页面，修改资料时再要求密码。
			<li> 免登陆直接浏览<a href="table.cgi">家谱</a>：<a href="detail.cgi?mine=10001">谭年浪</a>。
		</ul>
	</div>
EndOfHTML
}

&main(@ARGV) unless defined caller;
1;
__END__

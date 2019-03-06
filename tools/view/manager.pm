#! /usr/bin/env perl
package view::manager;
use utf8;
use strict;
use warnings;
use parent qw(HTPL);

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = '服务器管理工具';
	$self->{body} = '';
	$self->{H1} = '服务器管理工具';
	bless $self, $class;
	return $self;
}


sub generate
{
	my ($self, $st, $LOG) = @_;
	if (!$st || $st->{error}) {
		return $self->on_error($st->{error});
	}

	$self->{body} = HTPL::H1($self->{H1});

	if (!$st->{logined}) {
		$self->{body} .= s_login_form();
	}
	else {
		$self->{body} .= s_list_tool($st);
	}

	if ($LOG->{debug}) {
		$self->{body} .= HTPL::LOG($LOG);
	}

	return 0;
}

sub s_login_form
{
	my ($var) = @_;
	return <<EndOfHTML;
	<div id="login-form">
		<form method="get">
			ID： <input type="text" name="uid" required="required"/><br>
			PW： <input type="password" name="key" required="required"/><br>
			<input type="submit" value="登陆"/>
		</form>
	</div>
EndOfHTML
}

sub s_list_tool
{
	my ($st) = @_;
	my $list = '';
	foreach my $tool (values %{$st->{list}}) {
		my $desc = $tool->{desc};
		my $cgi = $tool->{cgi};
		my $li = <<HTML;
<li><a href="$cgi" target="_blank">$desc</a></li>
HTML
		$list .= $li;
	}
	
	return <<HTML;
<div id="tools">
	<ul>
$list
	</ul>
</div>
HTML
}

1;
__END__

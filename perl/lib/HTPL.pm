#! /usr/bin/env perl
package HTPL;
use strict;
use warnings;

=pod
=h1 Object support
=cut

sub new
{
	my ($class) = @_;
	my $self = {};
	$self->{title} = 'PERL::HTPL 网页模板生成';
	$self->{body} = '';
	bless $self, $class;
	return $self;
}

sub runout
{
	my ($self, $cgi, $LOG) = @_;
	$self->{CGI} = $cgi;
	$self->generate($cgi, $LOG);
	return $self->response();
}

# 默认的极简响应页
sub response_default
{
	my ($self) = @_;
	print "Content-type:text/html\n";
	print "\n";

	print <<EndOfHTML;
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width" />
		<title> $self->{title} </title>
	</head>
		$self->{body}
	<body>
	</body>
</html>
EndOfHTML

	return 0;
}

sub generate
{
	my ($self, $cgi, $LOG) = @_;
	$self->{body} = '生成内容';

	return 0;
}

sub on_error
{
	my ($self, $msg) = @_;
	$self->{body} = $msg;
	return -1;
}

sub response
{
	my ($self) = @_;

	## 响应头
	if ($self->{Header}) {
		# 通用 header ，可预保存为数组、hash 或长串数组
		if (ref($self->{Header}) eq 'ARRAY') {
			foreach my $header (@{$self->{Header}}) {
				print "$header\n";
			}
		}
		elsif (ref($self->{Header}) eq 'HASH') {
			foreach my $header (keys %{$self->{Header}}) {
				my $value = $self->{Header}->{$header};
				print "$header:$value\n";
			}
		}
		else {
			print "$self->{Header}\n";
		}
	}
	else {
		# 只处理常用 header ContentType
		if ($self->{ContentType}) {
			print "Content-type:$self->{ContentType}\n";
		}
		else {
			print "Content-type:text/html\n";
		}
		# SetCookie
		if ($self->{SetCookie}) {
			if (ref($self->{SetCookie}) eq 'ARRAY') {
				foreach my $header (@{$self->{SetCookie}}) {
					print "$header\n";
				}
			}
			else {
				print "$self->{SetCookie}\n";
			}
		}
	}

	# 空行
	print "\n";

	## 响应内容体
	
	# 文档类型
	if (!$self->{ContentType} || $self->{ContentType} !~ /html/i) {
		print "<!DOCTYPE html>\n";
	}

	# html 头
	my $head = $self->{head} || $self->gen_head();
	if (!$head) {
		$head = <<EndOfHTML;
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width" />
		<title> $self->{title} </title>
EndOfHTML
	}

	# html 体
	my $body = $self->{body} || $self->gen_body();

	# 输出整体文档
	print <<EndOfHTML;
<html>
	<head>
$head
	</head>
	<body>
$body
	</body>
</html>
EndOfHTML

	return 0;
}

=item gen_head
	根据一些属性来生成 head 文本
属性：self->
	charset 编码设定
	js => [*.js 文件] 数组
	css => [*.css 文件] 数组
=cut
sub gen_head
{
	my ($self) = @_;
	# return '' if !$self->{head_part};
	my @head = ();

	# 编码声明
	my $charset = 'UTF-8';
	if ($self->{charset}) {
		$charset = $self->{charset};
	}
	push(@head, qq{\t\t<meta charset="$charset" />});

	push(@head, qq{\t\t<meta name="viewport" content="width=device-width" />});

	# 外链 js 脚本
	if ($self->{js}) {
		if (ref($self->{js}) eq "ARRAY") {
			foreach my $js (@{$self->{js}}) {
				push(@head, qq{\t\t<script type="text/javascript" src="$js"></script>});
			}
		}
		else {
			push(@head, qq{\t\t$self->{js}});
		}
	}

	# 外链 css 样式
	if ($self->{css}) {
		if (ref($self->{css}) eq "ARRAY") {
			foreach my $css (@{$self->{css}}) {
				push(@head, qq{\t\t<link rel="stylesheet" type="text/css" href="$css">});
			}
		}
		else {
			push(@head, qq{\t\t$self->{css}});
		}
	}

	# 标题
	my $title = $self->{title} // '';
	push(@head, qq{\t\t<title> $title </title>});

	return join("\n", @head);
}

sub gen_body
{
	my ($self) = @_;
	my @body = ();
	return join("\n", @body);
}

# 添加 cookie ，默认附加一些安全选项，第二参数传 1 抑制额外附加
# 默认未设过期时间，为浏览器会话级
sub set_cookie
{
	my ($self, $cookie, $full) = @_;
	my $default = "; SameSite=strict; HttpOnly";
	my $cookstr = "Set-Cookie: $cookie";
	$cookstr .= $default if !$full;
	if (!$self->{SetCookie}) {
		$self->{SetCookie} = [$cookstr];
	}
	else {
		push(@{$self->{SetCookie}}, $cookstr);
	}
}

=pod
=head1 HTML Fragment Function
都按大写方法名
=cut

=markdown HTML($label, $text, $attr_ref)
	生成 html 标签文本：<$label $attr_str>$text</$label>
	如果 $text 是 undef ，则生成自闭标签如 <br/> <img/>
	$attr_ref 是属性表
=cut
sub HTML
{
	my ($label, $text, $attr_ref) = @_;
	return '' if !$label;

	my $attr = '';
	if ($attr_ref && ref($attr_ref) eq 'HASH') {
		foreach my $key (keys %{$attr_ref}) {
			my $val = $attr_ref->{$key};
			$attr .=  qq{ $key="$val"};
		}
	}

	my $html = defined($text)
		? qq{<$label$attr>$text</$label>}
		: qq{<$label$attr/>};

	return $html;
}

=markdown LINK($msg, $href)
	生成 <a href=""></a> 链接文件
	$href 是链接地址，或详细的 hashref 属性，链接为空时用 void(0)
=cut
sub LINK
{
	my ($msg, $href) = @_;
	$href = {href => $href} unless ref($href);
	$href->{href} = "javascript:void(0)" unless $href->{href};
	return HTML("a", $msg, $href);
}

=markdown H1()
	生成标题 1，默认添加换行。
=cut
sub H1
{
	my ($text) = @_;
	return HTML("H1", $text) . "\n";
}

=sub LOG
  生成日志片断，一般附加在网页末尾，记录 CGI 页面生成的过程。
  依赖 WebLog.pm 模块。网页最好提供 DivHide() js 函数用于隐藏该日志。
=cut
sub LOG
{
	my ($LOG) = @_;
	my $display = ($LOG->{debug} > 0) ? 'inline' : 'none';
	my $log = $LOG->to_webline();
	return <<EndOfHTML;
<hr>
<div class="folder">
	<div>
		<a href="javascript:void(0);" onclick="DivHide('debug-log')" class="fold">CGI Web LOG</a>
	</div>
	<div id="debug-log" style="display:$display" class="foldOff">
$log
	</div>
</div>
EndOfHTML
}

##-- TEST MAIN --##
sub main
{
	my @argv = @_;
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

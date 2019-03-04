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
	my ($self, $data, $LOG) = @_;
	$self->generate($data, $LOG);
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
	my ($self, $data, $LOG) = @_;
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
				push(@head, qq{\t\t<script src="$js" />});
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
	push(@head, qq{<title> $title </title>});

	return join("\n", @head);
}

sub gen_body
{
	my ($self) = @_;
	my @body = ();
	return join("\n", @body);
}

# 设置 key=val 型 cookie ，自动添加一些安全选项
# 默认未设过期时间，为浏览器会话级
sub set_cookie
{
	my ($self, $cookie) = @_;
	if (ref($cookie)) {
		foreach my $key (keys %{$cookie}) {
			my $cookstr = "$key=$cookie->{$key}";
			set_cookie($cookstr);
		}
	}
	else {
		my $cookstr = "Set-Cookie: $cookie; SameSite=strict; HttpOnly";
		if (!$self->{SetCookie}) {
			$self->{SetCookie} = [$cookstr];
		}
		else {
			push(@{$self->{SetCookie}}, $cookstr);
		}
	}
}

=pod
=h1 HTML Fragment Function
=cut

sub HTML
{
	my ($label, $text, $attr_ref) = @_;
	return '' if !$label;

	my $attr = '';
	if ($attr_ref && ref($attr_ref) eq 'HASH') {
		my @attr = ();
		foreach my $key (keys %{$attr_ref}) {
			my $val = $attr_ref->{$key};
			push(@attr, qq{$key="$val"});
		}
		@attr = join(" ", @attr);
	}

	my $html = '';
	if (!defined($text)) {
		$html = qq{<$label $attr/>};
	}
	else {
		if (length($text) > 16) {
			$text = "\n$text\n";
		}
		$html = qq{<$label $attr>$text</$label>};
	}

	return $html;
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

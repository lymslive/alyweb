#! /usr/bin/env perl
package MarkNote;
use strict;
use warnings;

# 构建对象，输入文件路径
sub new
{
	my ($class, $filepath) = @_;
	return undef unless -s $filepath;

	my $self = {};
	$self->{filepath} = $filepath;

	bless $self, $class;
	return $self;
}

# 转化为 html 并返回，解析过程也保存其他信息
# 标题 $title; 标签组 @tags
sub output
{
	my ($self) = @_;

	open(my $fh, '<', $self->{filepath});
	if (!$fh) {
		$self->{error} = "can not open file!";
		return "";
	}
	$self->{filehand} = $fh;

	$self->{lineno} = 0;
	$self->{line} = "";
	$self->{outbuf} = [];
	$self->parse();
	close($fh);

	return join("\n", @{$self->{outbuf}});
}

sub pushout
{
	my ($self, $string) = @_;
	return unless $string;
	push(@{$self->{outbuf}}, $string);
}

# 读取一行文本，保存在 {line} 属性中，返回是否读取成功
sub getline
{
	my ($self) = @_;
	my $fh = $self->{filehand};
	my $line = <$fh>;
	chomp($line) if $line;
	$self->{last} = $self->{line};
	$self->{line} = $line // "";
	$self->{lineno} += 1;
	return defined($line);
}

# 解析 markdown 文件
# 两层 while(<>) 方式，根据首行特征决定不同类型的续行段落
sub parse
{
	my ($self) = @_;
	my @pargraph = ();
	my $tag_line = "";

	while ($self->getline) {
		my $text = $self->{line} or next;

		# 空行
		if ($text =~ /^\s*$/) {
			next;
		}

		# 长线
		if ($text =~ /^---+/) {
			$self->pushout(qq{<hr/>});
			next;
		}

		# 两横线开启 mysql 风格的单行注释
		if ($text =~ /^-- /) {
			next;
		}

		# 忽略注释块
		if ($text =~ /^\s*<!--/) {
			$self->skip_comment();
			next;
		}

		# 保留 html 块
		if ($text =~ /^\s*<(\w+)\b.*?>/) {
			$self->keep_html($1);
			next;
		}

		# 标题行
		if ($text =~ /^\s*(#+)\s*(.+)/) {
			$self->expect_head(length($1), $2);
			next;
		}

		# 代码块
		if ($text =~ /^```(\w)*$/) {
			$self->expect_block($1);
			next;
		}

		# 列表
		if ($text =~ /^([-*+0-9])\.?\s+(.*)/) {
			$self->expect_list($1, $2);
			next;
		}

		# 普通段落
		$self->expect_paragraph();
	}
}

# 忽略注释块
sub skip_comment
{
	my ($self) = @_;
	if ($self->{line} =~ /<!--.*-->/) {
		return;
	}
	while ($self->getline) {
		if ($self->{line} =~ /-->/) {
			return;
		}
	}
}

# 保持 html 代码块
sub keep_html
{
	my ($self, $tag) = @_;
	return unless $tag;
	my $text = $self->{line} or return;
	if ($text =~ m|<$tag\b.*?/>|i) {
		$self->pushout($text);
		return;
	}
	if ($text =~ m|<$tag\b.*?>.*?</$tag>|i) {
		$self->pushout($text);
		return;
	}
	my $tag_level = 1;
	while ($self->getline) {
		my $text = $self->{line} or next;
		$self->pushout($text);
		if ($text =~ m|<$tag\b.*?/>|i) {
			next;
		}
		if ($text =~ m|<$tag\b.*?>|i) {
			$tag_level += 1;
		}
		if ($text =~ m|</$tag>|i) {
			$tag_level -= 1;
		}
		if ($tag_level <= 0) {
			last;
		}
	}
}

# 处理各级标题行
# todo: 加入 id ，用hi编号命名
sub expect_head
{
	my ($self, $level, $text) = @_;
	$self->pushout(qq{<h$level>$text</h$level>});

	# 文档标题，下一行当作标签行
	if (!$self->{title}) {
		$self->{title} = $text;
		$self->getline();
		return unless $self->{line};
		my @tags = ($self->{line} =~ /`([^`]+)`/g);
		if (@tags) {
			push(@{$self->{tags}}, @tags);
		}
	}
}

# 处理代码块
sub expect_block
{
	my ($self, $lang) = @_;
	my $css = "language-none";
	if ($lang) {
		my $css = "language-$lang";
	}
	$self->pushout(qq{<pre><code class="$css">});
	while ($self->getline) {
		if ($self->{line} =~ /^```/) {
			last;
		}
		my $text = Format($self->{line}, 1);
		$self->pushout("$text<br/>");
	}
	$self->pushout(qq{</code></pre>});
}

# 处理列表，以 *-+ 或数字开头的连续行
# 每一项可能多行，续行无前导符时合并
# 至空行结束整个列表
# todo: 多级列表
sub expect_list
{
	my ($self, $leader, $text) = @_;
	my $list = "ul";
	if ($leader =~ /\d/) {
		$list = "ol";
	}
	$self->pushout(qq{<$list>});
	while ($self->getline) {
		if ($self->{line} =~ /^\s*$/) {
			last;
		}
		$self->{line} =~ s/^\s*|\s*$//;
		if ($self->{line} =~ /^([-*+0-9])\.?\s+(.*)/) {
			$text = Format($text);
			$self->pushout(qq{<li>$text</li>});
			$text = $2;
		}
		else {
			$text = JoinLine($text, $self->{line});
		}
	}
	$text = Format($text);
	$self->pushout(qq{<li>$text</li>});
	$self->pushout(qq{</$list>});
}

# 普通段落
sub expect_paragraph
{
	my ($self) = @_;
	my $text = $self->{line};
	while ($self->getline) {
		if ($self->{line} =~ /^\s*$/) {
			last;
		}
		$text = JoinLine($text, $self->{line});
	}
	$text = Format($text);
	$self->pushout(qq{<p>$text</p>});
}

#########################
# 普通函数
# ######################

# 连接两行，英文单词间加一空格，汉字符号不加空格
sub JoinLine
{
	my ($first, $second) = @_;
	return $first unless $second;
	return $second unless $first;

	$first =~ s/\s*$//;
	$second =~ s/^\s*//;

	if ($first =~ /[a-zA-Z0-9.,]$/ || $second =~ /^[a-zA-Z0-9.,]/) {
		return "$first $second";
	}
	return $first . $second;
}

# 常规格式转换
sub Format
{
	my ($text, $only_escape) = @_;

	$text =~ s/>/&gt;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/&/&amp;/g;
	if ($only_escape) {
		return $text;
	}

	# 图片
	$text =~ s{!\[(.+?)\]\((\S+?)\)}{<img src="$2" alt="$1">}g;
	# 超链接
	$text =~ s{\[(.+?)\]\((\S+?)\)}{<a href="$1">$2</a>}g;
	$text =~ s{ (https?://\S+)( |$)}{ <a href="$1">$1</a>$2}g;

	$text =~ s{`([^`]+)`}{<code>$1</code>}g;

	# **粗体** *斜体*
	$text =~ s{ \*\*(\S[^*]*\S)\*\*( |$)}{<b>$1</b>}g;
	$text =~ s{ \*(\S[^*]*\S)\*( |$)}{<i>$1</i>}g;

	return $text;
}

sub Convert
{
	my ($file) = @_;
	my $obj = __PACKAGE__->new($file);
	return $obj->output();
}

##-- MAIN --##
sub main
{
	my ($file) = @_;
	# print Convert($file);
	my $obj = __PACKAGE__->new($file);
	print $obj->output();
	print "\n-----------\n";
	print "Title: $obj->{title}\n";
	print "Tags: ";
	print "$_ " for @{$obj->{tags}};
	print "\n";
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

#! /usr/bin/env perl
# 测试解析 txt 后代描叙文本
# 正则，把汉字当作三字节流处理，JSON 也不要用 utf8 选项
package ParseTXT;
use strict;
use warnings;
# use utf8;
use JSON;

# 全角冒号、句号、分号、逗号，顿号
my $MAOHAO = '：';
my $JUHAO = '。';
my $FENHAO = '；';
my $DOUHAO = '，';
my $DUNHAO = '、';

my @HUMBER = qw(一 二 三 四 五 六 七 八 九 十);
my @FIRBER = qw(长 次 幼);
my @SHUBER = qw(伯 仲 叔 季);

# 解析标准输入流文本，按句号分记录。
# 返回记录数组引用 [{record}]
# 先祖记录返回 {root => $name}
# 其他记录返回 {name => $name, children => [{}]}
# 每个 child 可以包含字段 { name, sex sibold, birthday, deathday, partner }
sub Parse
{
	my @argv = @_;
	local $/ = $JUHAO;
	my $result = [];
	while (<>) {
		next if /^\s*$/;
		s/^\s*//g;
		s/\s*$//g;
		print "$. $_\n";

		my $record = deal_sentence($_);

		push(@$result, $record);
	}

	return $result;
}

# 查找一个汉字表示的排行
# 假设 10 以内
sub find_humber
{
	my $str = shift or return 0;

	for (my $i = 0; $i < scalar(@FIRBER); $i++) {
		if ($str =~ $FIRBER[$i]) {
			return $i + 1;
		}
	}
	
	for (my $i = 0; $i < scalar(@HUMBER); $i++) {
		if ($str =~ $HUMBER[$i]) {
			return $i + 1;
		}
	}

	return 0;
}

# 解析一个分名，一个孩子的信息
sub parse_child
{
	my @info = @_;
	my $child = {};
	
	# 第一短句，应该包含姓名，可选男（子）或女，及排行
	my $str = shift(@info) or return {};
	# print "\t$str";
	if ($str =~ m/^(.*)(谭.+)$/) {
		$child->{name} = $2;
		my $lead = $1;
		if ($lead =~ /男/ || $lead =~ /子/) {
			$child->{sex} = 1;
		}
		elsif ($lead =~ /女/) {
			$child->{sex} = 2;
		}
		else {
			$child->{sex} = 1;
			warn "未指明男妇，假定是儿子";
		}

		$child->{sibold} = find_humber($lead);
	}

	# 其他短句
	while ($str = shift(@info)) {
		# print "\t$str";

		# 再次说明男女
		if (!$child->{sex}) {
			if ($str =~ /男/ || $str =~ /子/) {
				$child->{sex} = 1;
				next;
			}
			elsif ($str =~ /女/) {
				$child->{sex} = 2;
				next;
			}
		}
		
		# 生日忌日
		if ($str =~ /(\d{4}.\d{2}.\d{2})/) {
			if ($str =~ /(\d{4}.\d{2}.\d{2}).*至.*(\d{4}.\d{2}.\d{2})/) {
				$child->{birthday} = $1;
				$child->{deathday} = $2;
			}
			else {
				$child->{birthday} = $1;
			}
			next;
		}

		# 配偶
		if ($str =~ /(?:娶)?妻(.+)$/) {
			if ($child->{sex} == 1) {
				$child->{partner} = $1;
			}
			else {
				$child->{partner} = $1;
				$child->{sex} = 1;
			}
		}
		elsif ($str =~ /(?:嫁)?夫(.+)$/) {
			if ($child->{sex} == 2) {
				$child->{partner} = $1;
			}
			else {
				$child->{partner} = $1;
				$child->{sex} = 2;
			}
		}
	}
	
	return $child;
}

# 处理每一句，为一个父亲添加子女
sub deal_sentence
{
	my ($text) = @_;
	$text =~ s/$JUHAO$//;

	# 提取冒号前后的内容
	my ($label, $content) = split(/$MAOHAO/, $text);
	# print "parent: $label\n";

	if ($label =~ /先祖/) {
		my $record = {root => $content};
		return $record;
	}

	my @kids = ();
	# 每个子女用分号隔开，用逗号分开每个信息
	my @children = split(/$FENHAO/, $content);
	foreach my $child (@children) {
		my @info = split(/$DOUHAO/, $child);
		my $kid = parse_child(@info);
		push(@kids, $kid);
		# print "\t$_" for @info;
		# print "\n";
	}

	my $record = {name => $label, children => \@kids};
	return $record;
}

##-- MAIN --##
sub main
{
	my @argv = @_;
	local $/ = $JUHAO;
	while (<>) {
		next if /^\s*$/;
		s/^\s*//g;
		s/\s*$//g;
		print "$. $_\n";

		my $record = deal_sentence($_);
		# my $jstr = encode_json($record);
		my $jstr = JSON->new->encode($record);
		print "$jstr\n";
	}
}

##-- SUBS --##

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

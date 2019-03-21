#! /usr/bin/env perl
# package japi;
use strict;
use warnings;

# use utf8;
use FindBin qw($Bin);
use lib "$Bin";
use FamilyAPI;
use WebLog;
use JSON;
require 'sql/ParseTXT.pm';

##-- MAIN --##
sub main
{
	# my @argv = @_;

	my $req = { api=> 'create', data => {}, admin => 1 };
	my $data = ParseTXT::Parse();
	print 'parse data: ' . scalar(@$data) . "\n";
	foreach my $rawData (@$data) {
		if ($rawData->{root}) {
			print "deal with root \n";
			wlog('增加先祖：' . $rawData->{root});
			$req->{data} = {name => $rawData->{root}, root => 1, sex => 1};
			my $res = FamilyAPI::handle_request($req);
			if ($res->{error}) {
				wlog('插入先祖失败：' . $res->{errmsg});
				return;
			}
		}
		else {
			print "deal with normal \n";
			my $parent = $rawData->{name};
			wlog('开始处理父亲：' . $parent);
			foreach my $child (@{$rawData->{children}}) {
				wlog('增加子女：' . $child->{name});
				my $reqData = {father_name => $parent};
				$reqData->{name} = $child->{name} if $child->{name};
				$reqData->{sex} = $child->{sex} if $child->{sex};
				$reqData->{partner} = $child->{partner} if $child->{partner};
				$reqData->{sibold} = $child->{sibold} if $child->{sibold};
				$reqData->{birthday} = $child->{birthday} if $child->{birthday};
				$reqData->{deathday} = $child->{deathday} if $child->{deathday};

				$req->{data} = $reqData;
				my $res = FamilyAPI::handle_request($req);
				if ($res->{error}) {
					wlog('插入先祖失败：' . $res->{errmsg});
				}
			}
		}
	}
	
}

##-- SUBS --##

# 额外向终端输出日志
sub on_console
{
	# 先将标准输出刷出，再向标准错误输出
	print "\n"; 
	print STDERR "--" x 20;
	print STDERR "\n";
	print STDERR "console log:\n";
	WebLog::instance()->output_std();
}

##-- END --##
&main(@ARGV) unless defined caller;
on_console();
1;
__END__

=pod
能正确解析 sql/child.txt 批量插入
第一次导入又被 sex 0 误导，所有女的没创建成功
delete 删表所有数据重插，自增 id 还是顺延
要重置 id 还得 drop

性别还是不要用 0 1 表示了，坑多
=cut

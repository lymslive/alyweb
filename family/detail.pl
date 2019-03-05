#! /usr/bin/env perl
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use WebLog;
use ForkCGI;
use FamilyAPI;
use FamilyUtil;
use view::detail;

my $DEBUG = 0;
$DEBUG = 1 if $ENV{SCRIPT_NAME} =~ m/\.pl$/;
my $LOG = WebLog::instance();

##-- MAIN --##
sub main
{
	my @argv = @_;
	my $param = ForkCGI::Param(@argv);
	my $debug = $param->{debug} // $DEBUG;
	$LOG->{debug} = $debug;

	wlog("ENV{HTTP_COOKIE}: $ENV{HTTP_COOKIE }");
	wlog("param{HTTP_COOKIE}: $param->{HTTP_COOKIE}");

	# 当前需要操作的行
	my $operate_result = '';
	if ($param->{operate} && $param->{operate} eq 'modify') {
		$operate_result = modify_row($param);
	}

	my $uid;
	my $cookie;
	if ($ENV{HTTP_COOKIE}) {
		$cookie = ForkCGI::Cookie();
		if ($cookie->{uid} && $cookie->{uid} =~ /^(\d+)-/) {
			$uid = $1;
		}
	}

	my $id = $param->{mine_id} // $uid;
	my $detail = query_detail($id, $param);
	$detail->{operate_result} = $operate_result;
	if ($ENV{HTTP_COOKIE}) {
		$detail->{COOKIE} = $cookie;
	}

	my $html = view::detail->new();
	return $html->runout($detail, $LOG);
}

##-- SUBS --##

# 查询详情
# 输入：id
# 输出：{} ，除了本行记录，再联表查询祖先继承关系与所有子女
sub query_detail
{
	my ($id, $param) = @_;
	
	if (!$id) {
		return {error => '未提供ID，请登陆'};
	}

	my $detail = {};
	my $req = { api => "query", data => { filter => { id => $id}}};
	my $res = FamilyAPI::handle_request($req);
	my $data = $res->{data} or return {};
	my $row = $data->[0] or return {};

	$detail->{id} = $id;
	$detail->{name} = $row->{F_name};
	$detail->{sex} = $row->{F_sex};
	$detail->{level} = $row->{F_level};
	$detail->{birthday} = $row->{F_birthday};
	$detail->{deathday} = $row->{F_deathday};

	if ($row->{F_partner}) {
		my $partner = query_base($row->{F_partner});
		$detail->{partner} = $partner;
	}

	# 直系后代须查父母
	if ($detail->{level} > 1) {
		my $root = [];
		my $root_id = 0;
		if ($row->{F_father}) {
			my $parent = query_base($row->{F_father});
			$detail->{father} = $parent;
			if ($parent->{level} > 0) {
				push(@$root, $parent);
				$root_id = $row->{F_father};
			}
		}
		if ($row->{F_mother}) {
			my $parent = query_base($row->{F_mother});
			$detail->{mother} = $parent;
			if ($parent->{level} > 0) {
				push(@$root, $parent);
				$root_id = $row->{F_mother};
			}
		}

		if (!$root_id) {
			wlog("查询父/母失败");
			return {error => "查询父/母失败"};
		}

		# 继续往上查祖父……
		for (my $level = $row->{F_level} - 1; $level > 1; $level--) {
			wlog("query root_id: $root_id; level $level");
			my $parent = select_parent($root_id);
			last unless %$parent;
			push(@$root, $parent);
			$root_id = $parent->{id};
		}

		$detail->{root} = $root;
	}

	# 快捷增加子女
	if ($param->{operate} && $param->{operate} eq 'modify'
		&& $param->{child_name} && defined($param->{child_sex})) {
		create_child($detail, $param);
	}

	# 查询子女
	$detail->{child} = select_child($detail->{id}, $detail->{sex});

	return $detail;
}

# 由 id 查询基本的 id name sex level
sub query_base
{
	my ($id) = @_;
	my $base = {};
	my $fields = ['F_name', 'F_level', 'F_sex'];
	my $req = { api => "query", data => { filter => { id => $id}, fields => $fields}};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('查询数据失败：' . $res->{errmsg});
		return {};
	}
	my $data = $res->{data} or return {};
	my $row = $data->[0] or return {};
	$base->{id} = $id;
	$base->{name} = $row->{F_name};
	$base->{level} = $row->{F_level};
	$base->{sex} = $row->{F_sex};
	return $base;
}

# 选出一个继承父母，level > 0 的
# 返回父/母的信息 {id , name, sex}
sub select_parent
{
	my ($id) = @_;
	
	my $req = { api => "query", data => { filter => { id => $id}, fields => ['F_father', 'F_mother', 'F_sex']}};
	my $res = FamilyAPI::handle_request($req);
	my $data = $res->{data} or return {};
	my $row = $data->[0] or return {};
	if ($row->{F_father}) {
		my $parent = query_base($row->{F_father});
		if ($parent->{level} > 0) {
			return $parent;
		}
	}
	elsif ($row->{F_mother}) {
		my $parent = query_base($row->{F_mother});
		if ($parent->{level} > 0) {
			return $parent;
		}
	}

	wlog('查询父/母失败');
	return {};
}

# 查询所有子女
# 输入：自己的 id sex
# 输出：数组 [{id name sex}]
sub select_child
{
	my ($id, $sex) = @_;
	wlog("id: $id; sex: $sex");
	return [] unless $id;
	
	my @fields = qw[F_id F_name F_sex];
	my $filter = {};
	if ($sex == 1) {
		$filter->{father} = $id;
	}
	elsif ($sex == 0) {
		$filter->{mother} = $id;
	}
	else {
		return [];
	}

	my $req = { api => "query", data => { filter => $filter, fields => \@fields}};
	my $res = FamilyAPI::handle_request($req);
	my $data = $res->{data} or return [];

	# 复制并转化出数据
	my @child;
	foreach my $row (@$data) {
		push(@child, {id => $row->{F_id}, name => $row->{F_name}, sex => $row->{F_sex}});
	}
	
	return \@child;
}

sub modify_row
{
	wlog("Enter ...");
	my ($param) = @_;
	my $msg = '修改成功';
	my $req_data = FamilyUtil::Param2api($param);
	if (!$req_data->{id}) {
		$msg = '需要输入被修改成员的id';
		wlog($msg);
		return $msg;
	}

	my $req = { api => "modify", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		$msg = '修改数据失败：' . $res->{errmsg};
		wlog($msg);
		return $msg;
	}

	return $msg;
}

sub create_child
{
	my ($detail, $param) = @_;
	
	my $req_data = {
		name => $param->{child_name},
		sex  => $param->{child_sex},
	};

	my $partner_id = $detail->{partner}->{id} if $detail->{partner};
	if ($detail->{sex} == 1) {
		$req_data->{father_id} = $detail->{id};
		$req_data->{mother_id} = $partner_id if $partner_id;
	}
	elsif ($detail->{sex} == 0) {
		$req_data->{mother_id} = $detail->{id};
		$req_data->{father_id} = $partner_id if $partner_id;
	}
	else {
		wlog('非法性别');
		return {error => '非法性别'};
	}

	if ($param->{child_birthday}) {
		$req_data->{birthday} = $param->{child_birthday};
	}
	if ($param->{child_deathday}) {
		$req_data->{deathday} = $param->{child_deathday};
	}

	my $req = { api => "create", data => $req_data};
	my $res = FamilyAPI::handle_request($req);
	if ($res->{error} || !$res->{data}) {
		wlog('插入数据失败：' . $res->{errmsg});
		return {error => '插入数据失败：' . $res->{errmsg}};
	}

	return 0;
}

##-- END --##
&main(@ARGV) unless defined caller;

if (ForkCGI::TermTest()) {
	$LOG->output_std();
}

1;
__END__

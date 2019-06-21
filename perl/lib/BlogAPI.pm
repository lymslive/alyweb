#! /usr/bin/env perl
use utf8;
package BlogAPI;
use strict;
use warnings;

use WebLog;
use DateTime;
use Encode qw(decode encode);

use NoteBook;
NoteBook::SetBookdirs("$ENV{DOCUMENT_ROOT}/notebook");

# 数据库连接信息
my $dbcfg = {
	host => '47.106.142.119',
	user => 'blog',
	pass => 'blog',
	# port => 0,
	# flag => {},
	database => 'db_blog',
	table => 't_blog_state',
};

my @topic_order = qw(misc game opera snake art code hot);

# todo
my $TABLE_BILL = 't_family_bill';
my @FIELD_BILL = qw(F_id F_type F_subtype F_money F_date F_target F_place F_note);
my $TABLE_CONFIG = 't_type_config';
my @FIELD_CONFIG = qw(F_subtype F_typename);

# 错误码设计
my $MESSAGE_REF = {
	ERR_SUCCESS => '0. 成功',
	ERR_SYSTEM => '-1. 系统错误',
	ERR_SYSNO_API => '-2. 系统错误，缺少接口，请检查接口名',
	ERR_ARGUMENT => '1. 参数错误',
	ERR_ARGNO_API => '2. 参数错误，缺少接口名字',
	ERR_ARGNO_DATA => '3. 参数错误，缺少接口数据',
	ERR_ARGNO_ID => '5. 参数错误，缺少日志ID',
	ERR_DBI_FAILED => '10. 数据库操作失败',
	ERR_NOTE_FILE => '11. 读取日志失败',
};

sub error_msg
{
	my ($error) = @_;
	return $MESSAGE_REF->{$error} || "未知错误";
}

# 响应函数配置
# 响应函数要求返回两个值 ($error, $res_data)，错误码及实际数据
# 能接收两个参数 ($db, $req_data) ，数据库对象、请求数据
my $HANDLER = {
	topic => \& handle_topic,
	article => \& handle_article,

	query_discuss => \& handle_query_discuss,
	post_discuss => \& handle_post_discuss,
};

# 请求入口，分发响应函数
# req = {api => '接口名', data => {实际请求数据}, sess=>{会话及操作密码}}
sub handle_request
{
	my ($jreq) = @_;

	my $api = $jreq->{api}
		or return response('ERR_ARGNO_API');
	my $req_data = $jreq->{data}
		or return response('ERR_ARGNO_DATA');
	my $handler = $HANDLER->{$api}
		or return response('ERR_SYSNO_API');

	my $db = undef;
	unless ($api =~ /^(topic|article)$/) {
		require 'MYDB.pm';
		my $db = MYDB->new($dbcfg);
		if ($api =~ /config$/) {
			$db->{table} = $TABLE_CONFIG;
		}

		if ($db->{error}) {
			return response('ERR_DBI_FAILED', $db->{error});
		}
	}

	my ($error, $res_data) = $handler->($db, $req_data);

	if ($db) {
		$db->Disconnect();
	}

	return response($error, $res_data);
}

# 将派发函数返回的两个参数，发回客户端
# 只有 $error 为假时，$data 才有效，否则当作错误信息附加在 errmsg
# 不出错时，返回空 error 码与　data 数据字段
sub response
{
	my ($error, $data) = @_;

	my $res = { error => $error};
	if ($error) {
		$res->{errmsg} = error_msg($error);
		if ($data && !ref($data)) {
			$res->{errmsg} .= ": " . $data;
		}
		wlog("RES error: $res->{errmsg}");
		return $res;
	}

	$res->{data} = $data if $data;

	return $res;
}

=sub handle_topic()
  博客分类列表
请求：
  req = {
    tag => all/recent/only
  }
响应：
  res = {
    tag => 原样返回
    list => [记录列表]
  }
=cut
sub handle_topic
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	return ('ERR_ARGUMENT') unless ($jreq->{tag});

	my $search = undef;
	if ($jreq->{input}) {
		my $input = $jreq->{input};
		$search = join('|', split(/\s+/, $input));
		wlog("input: $input; search note: $search");
	}

	my $all = $jreq->{tag} =~ /^(all|recent|search)$/;
	my @result = ();
	foreach my $topic (@topic_order) {
		if ($all || $topic eq $jreq->{tag}) {
			if ($topic eq 'hot' && $jreq->{tag} ne 'hot') {
				next; # 不要重复搜索 hot
			}

			my $list = NoteBook::GetBlogList($topic);
			for (my $i = 0; $i < @{$list}; $i++) {
				chomp $list->[$i];
				$list->[$i] = decode('utf-8', $list->[$i]);
			}

			if ($search) {
				push(@result, grep {/$search/} @$list);
			}
			else {
				push(@result, @$list);
			}
		}
	}

	$jres->{tag} = $jreq->{tag};
	$jres->{list} = \@result;
	if ($jreq->{tag} =~ /^recent$/) {
		my @sorted = reverse sort @result;
		my @recent = @sorted[0..9];
		$jres->{list} = \@recent;
	}
	
	$jres->{total} = scalar(@{$jres->{list}});
	
	return ($error, $jres);
}

=sub handle_article()
  博客文章内容
请求：
  req = {
	id => 日志id
	topic => 日志所属分类，可选
  }
响应：
  res = {
    id =>
	topic => ''
	title =>
	tags => [标签]
	author =>
	date =>
	url =>
	content => []
  }
=cut
sub handle_article
{
	wlog('headle this ...');
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $id = $jreq->{id} or return ('ERR_ARGNO_ID');

	my $filemark = NoteBook::ReadBlogFile($id);
	return ('ERR_NOTE_FILE') if !$filemark;

	$jres->{title} = $filemark->{title};
	$jres->{tags} = $filemark->{tags};
	$jres->{date} = $filemark->{date};
	$jres->{url} = $filemark->{url};
	$jres->{author} = '七阶子谭';
	$jres->{content} = join('', @{$filemark->{content}});

	$jres->{title} = decode('utf-8', $jres->{title});
	$jres->{content} = decode('utf-8', $jres->{content});
	# $jres->{tags} = decode('utf-8', $jres->{tags});
	for (my $i = 0; $i < @{$jres->{tags}}; $i++) {
		$jres->{tags}->[$i] = decode('utf-8', $jres->{tags}->[$i]);
	}

	$jres->{id} = $jreq->{id};
	$jres->{topic} = $jreq->{topic} if $jreq->{topic};

	return ($error, $jres);
}

=head1 table operate
=cut

=markdown handle_query_discuss()
  查询评论
req = {
  id => 
}
res = {
  id =>
  records => []
}
=cut
sub handle_query_discuss
{
	my ($db, $jreq) = @_;
	my $error = 0;
	my $jres = {};

	my $fields = $jreq->{fields} // \@FIELD_CONFIG;
	my $where = $jreq->{where};

	my $records = $db->Query($fields, $where);
	return ('ERR_DBI_FAILED', $db->{error}) if ($db->{error});
	$jres->{records} = $records;

	return ($error, $jres);
}

=markdown handle_post_discuss()
  添加评论
req = {
  contact => 联系人
  noteID => 文章 id
  content =>
}
res = {
  noteID => 文章 id
  disID =>
}
=cut
sub handle_post_discuss
{
	return handle_create(@_);
}

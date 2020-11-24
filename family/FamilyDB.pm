#! /usr/bin/env perl
use utf8;
package FamilyDB;
use strict;
use warnings;

use DBI;
use SQL::Abstract;
use WebLog;

=head1 数据库配置
=cut

my $HOST = '47.106.142.119';
# my $DBNAME = 'db_family';
my $DBNAME = 'db_fatree';

my $driver = 'mysql';
my $dsn = "host=$HOST;database=$DBNAME";
my $username = 'family';
# my $passwd = 'family';
my $passwd = '0xFAFAFA';
my $flags = {AutoCommit => 1, mysql_enable_utf8 => 1};

my $TABLE_MEMBER = 't_family_member';
my @FIELD_MEMBER = qw(F_id F_name F_sex F_level F_father F_partner F_sibold F_birthday F_deathday);

my $TABLE_BRIEF = 't_member_brief';
my $TABLE_PASSWD = 't_member_passwd';

=head1 对象封装
=cut

sub new
{
	my ($class) = @_;
	my ($dbh, $error) = Connect();
	my $self = {dbh => $dbh, error => $error};
	$self->{sql} = SQL::Abstract->new;
	bless $self, $class;
	return $self;
}

# 连接数据库。因不能 or die，顺便返回错误信息
sub Connect
{
	my $error = '';
	my $dbh = DBI->connect("dbi:$driver:$dsn", $username, $passwd, $flags)
		or $error = "Failed to connect to database: $DBI::errstr";
	return ($dbh, $error);
}

sub Disconnect
{
	my ($self) = @_;
	$self->{dbh}->disconnect;
}

# 设置错误消息，并返回一个值
# 不带参数时将错误重置为 undef
sub Error
{
	my ($self, $ret, $msg) = @_;
	$self->{error} = $msg;
	return $ret;
}

# 执行由 SQL::Abstract 生成的 sql 语句
# 传入语句 $stmt 字符串与绑定值 $bind 数组引用
# 返回执行完语句对象 $sth ，并设置错误消息
sub Execute
{
	my ($self, $stmt, $bind) = @_;
	my $dbh = $self->{dbh};
	wlog("$stmt; ?= @$bind");
	$self->{error} = '';
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error(undef, "Fail to prepater: " . $dbh->errstr);
	$sth->execute(@$bind)
		or return $self->Error(undef, "Fail to execute: " . $dbh->errstr);
	return $sth;
}

# 入参：
# $fields, $where 符合 SQL::Abstract 参数规则，在 $order 之前插入 $limit
# 无 $order 参数时，只按默认 id 排序
# 不提供 $fields 时，使用默认的列名数组
# $limit 是一个数字，或逗号分隔的两个数字，将拼在 LIMIT 之后
# 返回：
# 查询结果数组 arraryref ，单行查询也是一个数组，每行是个 hashref
sub Query
{
	my ($self, $fields, $where, $limit, $order) = @_;

	if (!$fields || (scalar @$fields) < 1) {
		$fields = \@FIELD_MEMBER;
	}
	my($stmt, @bind) = $self->{sql}->select($TABLE_MEMBER, $fields, $where, $order);
	if ($limit) {
		$stmt .= " LIMIT $limit";
	}

	my $sth = $self->Execute($stmt, \@bind) or return undef;
	my $result = $sth->fetchall_arrayref({});
	return $result;
}

# 查找记录行数
# 入参：$where 与 Query 相同
# 出参：返回数值
sub Count
{
	my ($self, $where) = @_;
	my($stmt, @bind) = $self->{sql}->where($where);

	my $stmt_full = "SELECT count(1) FROM $TABLE_MEMBER $stmt";
	my $sth = $self->Execute($stmt_full, \@bind) or return 0;

	my $result = $sth->fetchrow_arrayref;
	return $result && $result->[0];
}

# 入参：
# hasheref 数据结构，适于 SQL::Abstract insert
# 返回：
# 影响行数，插入单行时 1 表示正常插入
sub Create
{
	my ($self, $fieldvals) = @_;

	my($stmt, @bind) = $self->{sql}->insert($TABLE_MEMBER, $fieldvals);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

# 返回最后一个自增 id
sub LastInsertID
{
	my ($self) = @_;
	my $dbh = $self->{dbh};
	return $dbh->last_insert_id(undef, $DBNAME, $TABLE_MEMBER, 'F_ID');
}

# 入参：
# hasheref 数据结构，适于 SQL::Abstract insert
# 返回：
# 影响行数，一般更新单行时 1 表示修改成功
sub Modify
{
	my ($self, $fieldvals, $where) = @_;

	my($stmt, @bind) = $self->{sql}->update($TABLE_MEMBER, $fieldvals, $where);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

# 入参：
# hasheref 数据结构，适于 SQL::Abstract insert
# 返回：
# 影响行数，一般删除单行时 1 表示修改成功
sub Remove
{
	my ($self, $where) = @_;

	my($stmt, @bind) = $self->{sql}->delete($TABLE_MEMBER, $where);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

=head1 brief table operate
=cut

# 查找简介，入参 id ，返回简单字符串，不存在时返回空串
sub QueryBrief
{
	my ($self, $id) = @_;
	return '' if !$id;

	my $where = { F_id => $id };
	my($stmt, @bind) = $self->{sql}->select($TABLE_BRIEF, ['F_text'], $where);
	my $sth = $self->Execute($stmt, \@bind) or return '';
	my $result = $sth->fetchrow_arrayref;
	return $result && $result->[0];
}

# 查找是否有简介，入参 id ，返回true/false
sub HaveBrief
{
	my ($self, $id) = @_;
	return 0 if !$id;

	my $where = { F_id => $id };
	my($stmt, @bind) = $self->{sql}->select($TABLE_BRIEF, ['F_id'], $where);
	my $sth = $self->Execute($stmt, \@bind) or return 0;
	my $result = $sth->fetchrow_arrayref;
	return $result && $result->[0];
}

# 增加简介，入参 id 与 text 字符串，返回影响行数
sub CreateBrief
{
	my ($self, $id, $text) = @_;
	return 0 if !$text || !$id;

	my $fieldvals = { F_id => $id, F_text => $text };
	my($stmt, @bind) = $self->{sql}->insert($TABLE_BRIEF, $fieldvals);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

# 修改简介，入参 id 与 text 字符串，返回影响行数
sub ModifyBrief
{
	my ($self, $id, $text) = @_;
	return 0 if !$text || !$id;

	my $fieldvals = { F_text => $text };
	my $where = { F_id => $id };
	my($stmt, @bind) = $self->{sql}->update($TABLE_BRIEF, $fieldvals, $where);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

# 修改或增加简介，入参 id 与 text 字符串
sub ReplaceBrief
{
	my ($self, $id, $text) = @_;
	if ($self->HaveBrief($id)) {
		return $self->ModifyBrief($id, $text);
	}
	else {
		return $self->CreateBrief($id, $text);
	}
}

# 删除简介，入参 id ，返回影响行数
sub RemoveBrief
{
	my ($self, $id) = @_;
	return 0 if !$id;

	my $where = { F_id => $id };
	my($stmt, @bind) = $self->{sql}->delete($TABLE_BRIEF, $where);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

=head1 passwd table operate
=cut

# 查询密码表，入参 id 与字段列表，返回记录或 undef
sub QueryPasswd
{
	my ($self, $id, $fields) = @_;
	
	my $where = { F_id => $id };
	my($stmt, @bind) = $self->{sql}->select($TABLE_PASSWD, $fields, $where);
	my $sth = $self->Execute($stmt, \@bind) or return undef;
	my $result = $sth->fetchrow_hashref;
	return $result
}

# 增加密码记录，入参 id 与其他字段值
sub CreatePasswd
{
	my ($self, $id, $fieldvals) = @_;
	return 0 if !$id || !$fieldvals;

	$fieldvals->{F_id} = $id;
	my($stmt, @bind) = $self->{sql}->insert($TABLE_PASSWD, $fieldvals);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

# 修改密码记录，入参 id 与其他字段值
sub ModifyPasswd
{
	my ($self, $id, $fieldvals) = @_;
	return 0 if !$id || !$fieldvals;

	my $where = { F_id => $id };
	my($stmt, @bind) = $self->{sql}->update($TABLE_PASSWD, $fieldvals, $where);
	my $sth = $self->Execute($stmt, \@bind);
	return $sth && $sth->rows();
}

##-- MAIN --##
sub main
{
	# $WebLog::to_std = 1;
	wlog("log start");

	my $db = FamilyDB->new();
	$db->Disconnect();
	wlog("pm error: $db->{error}");
	wlog("log end");
	WebLog::instance()->output_std();
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

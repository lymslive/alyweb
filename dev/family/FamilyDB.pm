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
my $DBNAME = 'db_family';

my $driver = 'mysql';
my $dsn = "host=$HOST;database=$DBNAME";
my $username = 'family';
my $passwd = 'family';
my $flags = {AutoCommit => 1, mysql_enable_utf8 => 1};

my $TABLE_MEMBER = 't_family_member';
my @FIELD_MEMBER = qw(F_id F_name F_sex F_level F_father F_mother F_partner F_birthday F_deathday);
# my $dbh;

=head1 对象封装
=cut

sub new
{
	my ($class) = @_;
	my ($dbh, $error) = Connect();
	my $self = {dbh => $dbh, error => $error};
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
	my $dbh = $self->{dbh};

	if (!$fields || (scalar @$fields) < 1) {
		$fields = \@FIELD_MEMBER;
	}
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->select($TABLE_MEMBER, $fields, $where, $order);
	if ($limit) {
		$stmt .= " LIMIT $limit";
	}

	wlog("$stmt; ?= @bind");
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error([], "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error([], "Fail to execute");

	my $result = $sth->fetchall_arrayref({});
	return $result;
}

# 查找记录行数
# 入参：$where 与 Query 相同
# 出参：返回数值
sub Count
{
	my ($self, $where) = @_;
	my $dbh = $self->{dbh};
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->where($where);

	my $stmt_full = "SELECT count(1) FROM $TABLE_MEMBER $stmt";
	wlog("$stmt; ?= @bind");
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error(0, "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error(0, "Fail to execute");

	my @result = $sth->fetchrow_array;
	if (@result) {
		return $result[0];
	}
	else {
		return $self->Error(0, "Fail to get count");
	}
}

# 入参：
# hasheref 数据结构，适于 SQL::Abstract insert
# 返回：
# 影响行数，插入单行时 1 表示正常插入
sub Create
{
	my ($self, $fieldvals) = @_;
	my $dbh = $self->{dbh};

	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->insert($TABLE_MEMBER, $fieldvals);

	wlog("$stmt; ?= @bind");
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error([], "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error([], "Fail to execute");

	my $affected = $sth->rows();
	return $affected;
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
	my $dbh = $self->{dbh};

	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->update($TABLE_MEMBER, $fieldvals, $where);

	wlog("$stmt; ?= @bind");
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error([], "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error([], "Fail to execute");

	my $affected = $sth->rows();
	return $affected;
}

# 入参：
# hasheref 数据结构，适于 SQL::Abstract insert
# 返回：
# 影响行数，一般删除单行时 1 表示修改成功
sub Remove
{
	my ($self, $where) = @_;
	my $dbh = $self->{dbh};

	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->delete($TABLE_MEMBER, $where);

	wlog("$stmt; ?= @bind");
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error([], "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error([], "Fail to execute");

	my $affected = $sth->rows();
	return $affected;
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

#! /usr/bin/env perl
use utf8;
package FamilyDB;
use strict;
use warnings;

use DBI;
use SQL::Abstract;
use WebLog;

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

our $error = '';

sub error
{
	my ($ret, $msg) = @_;
	$error = $msg // '';
	return $ret;
}

sub set_error
{
	my ($msg) = @_;
	$error = $msg // '';
}

sub add_error
{
	my ($msg) = @_;
	$error .= "\n$msg" if $msg;
}

sub new
{
	my ($class) = @_;
	my $dbh = Connect();
	my $self = {dbh => $dbh, error => ''};
	bless $self, $class;
	return $self;
}

# 连接数据库。暂未检测失败，不能 or die
sub Connect
{
	my $dbh = DBI->connect("dbi:$driver:$dsn", $username, $passwd, $flags)
		or set_error("Failed to connect to database: $DBI::errstr");
	return $dbh;
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
# $fields, $where 符合 SQL::Abstract 参数规则
# 无 $order 参数，只按默认 id 排序
# 不提供 $fields 时，使用默认的列名数组
# $limit 是一个数字，或逗号分隔的两个数字，将拼在 LIMIT 之后
# 返回：
# 查询结果数组 arraryref ，单行查询也是一个数组，每行是个 hashref
sub Query
{
	my ($self, $fields, $where, $limit) = @_;
	my $dbh = $self->{dbh};

	if (!$fields || (scalar @$fields) < 1) {
		$fields = \@FIELD_MEMBER;
	}
	my $sql = SQL::Abstract->new;
	my($stmt, @bind) = $sql->select($TABLE_MEMBER, $fields, $where);
	if ($limit) {
		$stmt .= " LIMIT $limit";
	}

	wlog($stmt);
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error([], "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error([], "Fail to execute");

	my $result = $sth->fetchall_arrayref({});
	return $result;
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

	wlog($stmt);
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

	wlog($stmt);
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

	wlog($stmt);
	$self->Error();
	my $sth = $dbh->prepare($stmt) 
		or return $self->Error([], "Fail to prepater");
	$sth->execute(@bind)
		or return $self->Error([], "Fail to execute");

	my $affected = $sth->rows();
	return $affected;
}

# 根据姓名查 id level sex
sub QueryByName
{
	my ($self, $name) = @_;
	set_error("OK");

	my $dbh = $self->{dbh};

	wlog("select ... where name = '$name'");
	my $result = $dbh->selectrow_hashref(
		'SELECT F_id, F_level, F_sex, F_name FROM t_family_member WHERE F_name = ?', undef, $name)
		or set_error("No member who named: $name");

	return $result;
}

sub InsertMember
{
	my ($self, $new_member) = @_;
	set_error();

	my $dbh = $self->{dbh};
	my $sql = "INSERT INTO t_family_member SET F_name = '$new_member->{F_name}', F_sex = $new_member->{F_sex}, F_level = $new_member->{F_level}, ";
	if ($new_member->{F_father}) {
		$sql .= "F_father = '$new_member->{F_father}', ";
	}
	if ($new_member->{F_mother}) {
		$sql .= "F_mother = '$new_member->{F_mother}', ";
	}
	if ($new_member->{F_partner}) {
		$sql .= "F_partner = '$new_member->{F_partner}', ";
	}
	if ($new_member->{F_birthday}) {
		$sql .= "F_birthday = '$new_member->{F_birthday}', ";
	}
	if ($new_member->{F_deathday}) {
		$sql .= "F_deathday = '$new_member->{F_deathday}', ";
	}

	$sql .= "F_create_time = now(), F_update_time = now()";
	wlog($sql);
	$dbh->do($sql) or return error(0, "Fail to inser member: " . $dbh->errstr);
	return 1;
}

sub SelectAll
{
	my ($self) = @_;
	my $dbh = $self->{dbh};

	my $fields = join(', ', @FIELD_MEMBER);
	my $sql = "SELECT $fields FROM t_family_member";
	my $result = $dbh->selectall_arrayref( $sql, { Slice => {} });
	foreach my $rs (@$result) {
		foreach my $fd (@FIELD_MEMBER) {
			$rs->{$fd} //= 'NULL';
			if ($fd eq 'F_sex') {
				if ($rs->{$fd} == 1) {
					$rs->{$fd} = '男';
				}
				else {
					$rs->{$fd} = '女';
				}
			}
		}
	}
	return $result;
}

sub PrintAll
{
	my ($self) = @_;

	my $result = $self->SelectAll();
	my $fields_head = join("\t ", @FIELD_MEMBER);
	print "$fields_head\n";
	foreach my $rs (@$result) {
		foreach my $fd (@FIELD_MEMBER) {
			print $rs->{$fd} . "\t";
		}
		print "\n";
	}
	
	my $count = scalar @$result;
	wlog("All member count: $count");
	return $result;
}

##-- MAIN --##
sub main
{
	# $WebLog::to_std = 1;
	wlog("log start");

	my ($name) = @_;
	set_error("NO ERROR");
	my $db = FamilyDB->new();
	my $rs = $db->QueryByName($name) or warn $error;
	wlog("id: $rs->{F_id}; sex: " . $rs->{F_sex});

	$db->PrintAll();
	$db->Disconnect();
	wlog("pm error: $error");
	wlog("log end");
	print WebLog::buff_as_web();
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

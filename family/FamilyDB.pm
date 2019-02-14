#! /usr/bin/env perl
package FamilyDB;
use strict;
use warnings;

use DBI;

my $driver = 'mysql';
my $dsn = 'database=db_family';
my $username = 'family';
my $passwd = 'family';
my $flags = {AutoCommit => 1};

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

# 连接数据库。暂未检测失败，不能 or die
sub Connect
{
	my $dbh = DBI->connect("dbi:$driver:$dsn", $username, $passwd, $flags)
		or set_error("Failed to connect to database: $DBI::errstr");
	return $dbh;
}

# 根据姓名查 id level sex
sub QueryByName
{
	my ($dbh, $name) = @_;
	set_error();

	$dbh = Connect() unless $dbh;
	return {} unless $dbh;

	my $sth = $dbh->prepare(q{SELECT F_id, F_level, F_sex FROM t_family_member WHERE F_name = ?})
		or return error({}, "Failed in statement prepare: " . $dbh->errstr);
	$sth->execute($name) or return error({}, "Failed to execute statement: " . $dbh->errstr);

	my $row = $sth->rows;
	return error({}, "No member who named: $name") if $row < 1;
	return error({}, "Too many members that named: $name") if $row > 1;

	return $sth->fetchrow_hashref();
}

1;
__END__

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

sub Disconnect
{
	my ($dbh) = @_;
	$dbh->disconnect;
}

# 根据姓名查 id level sex
sub QueryByName
{
	my ($dbh, $name) = @_;
	set_error();

	$dbh = Connect() unless $dbh;
	return {} unless $dbh;

	my $sth = $dbh->prepare(qq{SELECT F_id, F_level, F_sex FROM t_family_member WHERE F_name = '$name'})
		or return error({}, "Failed in statement prepare: " . $dbh->errstr);
	# $sth->execute($name) or return error({}, "Failed to execute statement: " . $dbh->errstr);
	$sth->execute() or return error({}, "Failed to execute statement: " . $dbh->errstr);

	# my $row = $sth->rows;
	# return error({}, "row: $row; No member who named: $name") if $row < 1;
	# return error({}, "row: $row; Too many members that named: $name") if $row > 1;

	my $row_ref = $sth->fetchrow_hashref() or set_error("No member who named: $name");
	return $row_ref;
}

sub InsertMember
{
	my ($dbh, $new_member) = @_;
	set_error();

	$dbh = Connect() unless $dbh;
	return 0 unless $dbh;

	my $sql = "INSERT INTO t_family_member SET F_name = '$new_member->{F_name}', F_sex = $new_member-{F_sex}, F_level = $new_member->{F_level}, ";
	if ($new_member->{father}) {
		$sql .= "F_father = $new_member->{F_father}, ";
	}
	if ($new_member->{father}) {
		$sql .= "F_father = $new_member->{F_father}, ";
	}
	if ($new_member->{partner}) {
		$sql .= "F_partner = $new_member->{F_partner}, ";
	}
	if ($new_member->{birthday}) {
		$sql .= "F_birthday = $new_member->{F_birthday}, ";
	}
	if ($new_member->{deathday}) {
		$sql .= "F_deathday = $new_member->{F_deathday}, ";
	}

	$sql .= "F_create_time = now(), F_update_time = now()";
	$dbh->do($sql) or return error(0, "Fail to inser member" . $dbh->errstr);
	return 1;
}

##-- MAIN --##
sub main
{
	my ($name) = @_;
	my $dbh = Connect() or die $error;
	my $rs = QueryByName($dbh, $name) or warn $error;
	print "id: $rs->{F_id}\n";

	Disconnect($dbh);
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

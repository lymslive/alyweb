#! /usr/bin/env perl
package FamilyDB;
use strict;
use warnings;

use DBI;

my $driver = 'mysql';
my $dsn = 'host=47.106.142.119;database=db_family';
my $username = 'family';
my $passwd = 'family';
my $flags = {AutoCommit => 1, mysql_enable_utf8 => 1};

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

	my $result = $dbh->selectrow_hashref(
		'SELECT F_id, F_level, F_sex, F_name FROM t_family_member WHERE F_name = ?', undef, $name)
		or set_error("No member who named: $name");

	return $result;
}

sub InsertMember
{
	my ($dbh, $new_member) = @_;
	set_error();

	$dbh = Connect() unless $dbh;
	return 0 unless $dbh;

	my $sql = "INSERT INTO t_family_member SET F_name = '$new_member->{F_name}', F_sex = $new_member->{F_sex}, F_level = $new_member->{F_level}, ";
	if ($new_member->{father}) {
		$sql .= "F_father = '$new_member->{F_father}', ";
	}
	if ($new_member->{mother}) {
		$sql .= "F_mother = '$new_member->{F_mother}', ";
	}
	if ($new_member->{partner}) {
		$sql .= "F_partner = '$new_member->{F_partner}', ";
	}
	if ($new_member->{birthday}) {
		$sql .= "F_birthday = '$new_member->{F_birthday}', ";
	}
	if ($new_member->{deathday}) {
		$sql .= "F_deathday = '$new_member->{F_deathday}', ";
	}

	$sql .= "F_create_time = now(), F_update_time = now()";
	$dbh->do($sql) or return error(0, "Fail to inser member: " . $dbh->errstr);
	return 1;
}

##-- MAIN --##
sub main
{
	my ($name) = @_;
	my $dbh = Connect() or die $error;
	my $rs = QueryByName($dbh, $name) or warn $error;
	print "id: $rs->{F_id}\n";

	# my $result = $dbh->selectrow_hashref('SELECT F_id, F_level, F_sex, F_name FROM t_family_member WHERE F_id = ?', undef, 10001);
	# print "id: $result->{F_id}; name: $result->{F_name}\n";

	Disconnect($dbh);
}

##-- END --##
&main(@ARGV) unless defined caller;
1;
__END__

#! /usr/bin/env perl
package FamilyDB;
use strict;
use warnings;

use DBI;
use WebLog;

my $driver = 'mysql';
my $dsn = 'host=47.106.142.119;database=db_family';
my $username = 'family';
my $passwd = 'family';
my $flags = {AutoCommit => 1, mysql_enable_utf8 => 1};

my @fields_all = qw(F_id F_name F_sex F_level F_father F_mother F_partner F_birthday F_deathday);
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
	my $self = {dbh => $dbh};
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

	my $fields = join(', ', @fields_all);
	my $sql = "SELECT $fields FROM t_family_member";
	my $result = $dbh->selectall_arrayref( $sql, { Slice => {} });
	foreach my $rs (@$result) {
		foreach my $fd (@fields_all) {
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
	my $fields_head = join("\t ", @fields_all);
	print "$fields_head\n";
	foreach my $rs (@$result) {
		foreach my $fd (@fields_all) {
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

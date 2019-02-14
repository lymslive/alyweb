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

# 连接数据库。暂未检测失败，不能 or die
sub Connect
{
	my $dbh = DBI->connect("dbi:$driver:$dsn", $usename, $passwd, $flags);
	return $dbh;
}

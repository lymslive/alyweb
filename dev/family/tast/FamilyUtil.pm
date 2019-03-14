#! /usr/bin/env perl
package FamilyUtil;
use strict;
use warnings;

# 纯数字 ID 正则表达式
my $REG_ID = qr/^\d+$/;

# 将网络参数转为 api 参数
sub Param2api
{
	my ($param) = @_;

	my $data = {};
	$data->{id} = $param->{mine_id} if $param->{mine_id};
	$data->{name} = $param->{mine_name} if $param->{mine_name};
	$data->{sex} = $param->{sex} if defined($param->{sex});
	$data->{birthday} = $param->{birthday} if $param->{birthday};
	$data->{deathday} = $param->{deathday} if $param->{deathday};
	if ($param->{father}) {
		if ($param->{father} =~ $REG_ID) {
			$data->{father_id} = $param->{father};
		}
		else {
			$data->{father_name} = $param->{father};
		}
	}
	if ($param->{mother}) {
		if ($param->{mother} =~ $REG_ID) {
			$data->{mother_id} = $param->{mother};
		}
		else {
			$data->{mother_name} = $param->{mother};
		}
	}
	if ($param->{partner}) {
		if ($param->{partner} =~ $REG_ID) {
			$data->{partner_id} = $param->{partner};
		}
		else {
			$data->{partner_name} = $param->{partner};
		}
	}

	return $data;
}


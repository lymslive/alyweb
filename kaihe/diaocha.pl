#! /usr/bin/env perl
# package japi;
# use utf8;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use DiaochaAPI;
use JAPI;

JAPI::main(\&DiaochaAPI::handle_request);

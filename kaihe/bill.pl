#! /usr/bin/env perl
# package japi;
# use utf8;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use BillAPI;
use JAPI;

JAPI::main(\&BillAPI::handle_request);

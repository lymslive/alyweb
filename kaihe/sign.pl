#! /usr/bin/env perl
# package japi;
# use utf8;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use SignAPI;
use JAPI;

JAPI::main(\&SignAPI::handle_request);

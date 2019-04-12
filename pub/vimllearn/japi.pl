#! /usr/bin/env perl
# package japi;
# use utf8;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use BookAPI;
use JAPI;

JAPI::main(\&BookAPI::handle_request);

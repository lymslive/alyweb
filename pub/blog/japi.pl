#! /usr/bin/env perl
# package japi;
# use utf8;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use BlogAPI;
use JAPI;

JAPI::main(\&BlogAPI::handle_request);

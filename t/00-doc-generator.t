#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 4;

BEGIN { use_ok('Perl::DocGenerator') }

my $generator = new_ok('Perl::DocGenerator');

isa_ok($generator, 'Perl::DocGenerator');

can_ok($generator, qw/new folders packages loaded_packages scan_packages output/);

#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 4;

BEGIN { use_ok('Perl::DocGenerator::ModuleProcessor') }

my $processor = new_ok('Perl::DocGenerator::ModuleProcessor', ['Bar']);

isa_ok($processor, 'Perl::DocGenerator::ModuleProcessor');

can_ok($processor, qw/new modules module/);

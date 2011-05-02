#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 8;
use Perl::DocGenerator::ModuleProcessor;

my $module = Perl::DocGenerator::ModuleProcessor->new('Bar');

isa_ok($module, 'Perl::DocGenerator::ModuleProcessor');

isa_ok($module->obj, 'Devel::Symdump');

can_ok($module, qw/new base_classes packages scalars functions private_functions public_functions arrays hashes ios/);

cmp_ok($module->package_name, 'eq', 'Bar');

cmp_ok($module->scalars, '==', 1);

my ($scalar) = $module->scalars;
cmp_ok($scalar, 'eq', 'global_thing');

cmp_ok($module->functions, '==', 1);

my ($func) = $module->functions;
cmp_ok($func, 'eq', 'new');

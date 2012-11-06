#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 9;
use Perl::DocGenerator::ModuleProcessor;

my $module = Perl::DocGenerator::ModuleProcessor->new('Bar');

isa_ok($module, 'Perl::DocGenerator::ModuleProcessor');

isa_ok($module->obj, 'HASH');

can_ok($module, qw/new base_classes scalars functions private_functions public_functions arrays hashes ios/);

cmp_ok($module->package_name, 'eq', 'Bar');

cmp_ok($module->scalars, '==', 2);

my @scalars = $module->scalars;
cmp_ok($scalars[0]->name, 'eq', 'BEGIN');
cmp_ok($scalars[1]->name, 'eq', 'global_thing');

cmp_ok($module->functions, '==', 1);

my ($func) = $module->functions;
cmp_ok($func->name, 'eq', 'new');

#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 6;
use Perl::DocGenerator::ModuleProcessor;

my $module = Perl::DocGenerator::ModuleProcessor->new('Bar');

isa_ok($module, 'Perl::DocGenerator::ModuleProcessor');
isa_ok($module->obj, 'Devel::Symdump');
can_ok($module, qw/new base_classes packages scalars functions private_functions public_functions arrays hashes ios/);
cmp_ok($module->package_name, 'eq', 'Bar');
cmp_ok($module->scalars, '==', 1);
cmp_ok($module->functions, '==', 1);

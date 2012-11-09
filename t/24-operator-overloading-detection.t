#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 11;
use Perl::DocGenerator::ModuleProcessor;

{
    my $processor = Perl::DocGenerator::ModuleProcessor->new('Overloader');
    my ($module) = $processor->modules;

    my @all_functions = $module->functions();
    cmp_ok(scalar $module->public_functions, '==', 5);

    cmp_ok($all_functions[0]->name, 'eq', '()');
    cmp_ok($all_functions[0]->is_operator_overload, 'eq', 'Y');

    cmp_ok($all_functions[1]->name, 'eq', 'blah');
    cmp_ok($all_functions[1]->is_operator_overload, 'eq', 'N');

    cmp_ok($all_functions[2]->name, 'eq', '<=>');
    cmp_ok($all_functions[2]->is_operator_overload, 'eq', 'Y');

    cmp_ok($all_functions[3]->name, 'eq', 'cmp');
    cmp_ok($all_functions[3]->is_operator_overload, 'eq', 'Y');

    cmp_ok($all_functions[4]->name, 'eq', '--');
    cmp_ok($all_functions[4]->is_operator_overload, 'eq', 'Y');

}

#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 12;
use Perl::DocGenerator::ModuleProcessor;

{
    my $module = Perl::DocGenerator::ModuleProcessor->new('Baz');
    
    my @classes = $module->base_classes;
    my $num_classes = scalar @classes;

    cmp_ok($num_classes, '==', 1);
    cmp_ok($classes[0], 'eq', 'Bar');
    
    my @functions = $module->functions;
    my $num_functions = scalar @functions;

    cmp_ok($num_functions, '==', 2);
    cmp_ok($functions[0], 'eq', 'new');
    cmp_ok($functions[1], 'eq', 'order_drink');
}

{
    my $module = Perl::DocGenerator::ModuleProcessor->new('Bah');

    my @scalars = $module->scalars;
    my $num_scalars = scalar @scalars;

    cmp_ok($num_scalars, '==', 2);
    cmp_ok($scalars[0], 'eq', 'global_thing');
    cmp_ok($scalars[1], 'eq', 'other_global_thing');

    my @functions = $module->functions;

    my $num_functions = scalar @functions;
    cmp_ok($num_functions, '==', 3);
    cmp_ok($functions[0], 'eq', 'ahha');
    cmp_ok($functions[1], 'eq', 'new');
    cmp_ok($functions[2], 'eq', 'order_drink');
}

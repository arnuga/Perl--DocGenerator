#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 15;
use Perl::DocGenerator::ModuleProcessor;

{
    my $module = Perl::DocGenerator::ModuleProcessor->new('Baz');
    
    my @classes = $module->base_classes;
    my $num_classes = scalar @classes;

    cmp_ok($num_classes, '==', 1);
    cmp_ok($classes[0]->name, 'eq', 'Bar');
    
    my @functions = $module->functions;
    my $num_functions = scalar @functions;

    cmp_ok($num_functions, '==', 2);
    cmp_ok($functions[0]->name, 'eq', 'order_drink');
    cmp_ok($functions[1]->name, 'eq', 'new');
}

{
    my $module = Perl::DocGenerator::ModuleProcessor->new('Bah');

    my @classes = $module->base_classes;
    my $num_classes = scalar @classes;

    cmp_ok($num_classes, '==', 2);
    cmp_ok($classes[0]->name, 'eq', 'Baz');
    cmp_ok($classes[1]->name, 'eq', 'Bar');
    
    my @scalars = $module->scalars;
    my $num_scalars = scalar @scalars;

    cmp_ok($num_scalars, '==', 2);
    cmp_ok($scalars[0]->name, 'eq', 'other_global_thing');
    cmp_ok($scalars[1]->name, 'eq', 'global_thing');

    my @functions = $module->functions;

    my $num_functions = scalar @functions;
    cmp_ok($num_functions, '==', 3);
    cmp_ok($functions[0]->name, 'eq', 'new');
    cmp_ok($functions[1]->name, 'eq', 'ahha');
    cmp_ok($functions[2]->name, 'eq', 'order_drink');
}

#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 7;
use Perl::DocGenerator::ModuleProcessor;
use Data::Dumper;

{
    my $processor = Perl::DocGenerator::ModuleProcessor->new('Child');
   
    my $module = $processor->module('Child'); 
    my @classes = $module->base_classes;
    my $num_classes = scalar @classes;

    cmp_ok($num_classes, '==', 1);
    cmp_ok($classes[0]->name, 'eq', 'Parent');
    
    my @functions = $module->functions;
    my $num_functions = scalar @functions;

    cmp_ok($num_functions, '==', 1);
    cmp_ok($functions[0]->name, 'eq', 'my_cool_function');
    # this function is inherited from Bar class
    cmp_ok($functions[0]->package, 'eq', 'Child');
    cmp_ok($functions[0]->original_package, 'eq', 'Parent');
    cmp_ok($functions[0]->is_overridden, 'eq', 'Y');
}

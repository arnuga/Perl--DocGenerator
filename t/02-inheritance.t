#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 23;
use Perl::DocGenerator::ModuleProcessor;
use Data::Dumper;

{
    my $module = Perl::DocGenerator::ModuleProcessor->new('Baz');
    
    my @classes = $module->base_classes;
    my $num_classes = scalar @classes;

    cmp_ok($num_classes, '==', 1);
    cmp_ok($classes[0]->name, 'eq', 'Bar');
    
    my @functions = $module->functions;
    my $num_functions = scalar @functions;

#    warn Data::Dumper::Dumper($module);
    cmp_ok($num_functions, '==', 2);
    cmp_ok($functions[0]->name, 'eq', 'order_drink');
    cmp_ok($functions[1]->name, 'eq', 'new');

    # this function is inherited from Bar class
    cmp_ok($functions[1]->original_package, 'eq', 'Bar');
}

{
    my $module = Perl::DocGenerator::ModuleProcessor->new('Bah');

    my @classes = $module->base_classes;
    my $num_classes = scalar @classes;

    cmp_ok($num_classes, '==', 2);
    cmp_ok($classes[0]->name, 'eq', 'Bar');
    cmp_ok($classes[1]->name, 'eq', 'Baz');
    
    my @scalars = $module->scalars;
    my $num_scalars = scalar @scalars;

    cmp_ok($num_scalars, '==', 4);
    cmp_ok($scalars[0]->name, 'eq', 'BEGIN');

    cmp_ok($scalars[1]->name, 'eq', 'ISA');

    # inherited from Bar class
    cmp_ok($scalars[2]->name, 'eq', 'global_thing');
    cmp_ok($scalars[2]->original_package, 'eq', 'Bar');

    # inherited from Bah class
    cmp_ok($scalars[3]->name, 'eq', 'other_global_thing');
    cmp_ok($scalars[3]->original_package, 'eq', 'Bah');

    my @functions = $module->functions;

    my $num_functions = scalar @functions;
    cmp_ok($num_functions, '==', 3);
    cmp_ok($functions[0]->name, 'eq', 'ahha');
    # inherited from Bah class
    cmp_ok($functions[0]->original_package, 'eq', 'Bah');
    cmp_ok($functions[1]->name, 'eq', 'order_drink');
    # inherited from Baz class
    cmp_ok($functions[1]->original_package, 'eq', 'Baz');
    cmp_ok($functions[2]->name, 'eq', 'new');
    # inherited from Bar class
    cmp_ok($functions[2]->original_package, 'eq', 'Bar');
}

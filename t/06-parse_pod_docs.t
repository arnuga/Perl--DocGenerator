#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 6;
use Perl::DocGenerator::PodReader;
use Perl::DocGenerator::ModuleProcessor;

{
    my $pod = Perl::DocGenerator::PodReader->new('t/lib/ClassWithPod.pm', ('new', 'my_func_one', 'my_func_two'));
    cmp_ok(ref($pod), 'eq', 'Perl::DocGenerator::PodReader');

    if ($pod) {
        my %methods = $pod->methods();
        cmp_ok(scalar keys %methods, '==', 3);
    }

    my $module = Perl::DocGenerator::ModuleProcessor->new('ClassWithPod');
    my $pod_obj = $module->pod();
    my %podded_methods = $pod_obj->methods();
    cmp_ok(scalar keys %podded_methods, '==', 3);

    cmp_ok($podded_methods{'new'}, 'eq', "this is the constructor");
    cmp_ok($podded_methods{'my_func_one'}, 'eq', "my first amazing function");
    cmp_ok($podded_methods{'my_func_two'}, 'eq', "twice as nice (except I\'m trying to be clever in my head2 line)\n\nAlso I have 2 lines of text with a double space in between");
}

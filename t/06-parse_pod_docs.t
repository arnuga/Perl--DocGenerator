#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 3;
use Perl::DocGenerator::PodReader;
use Perl::DocGenerator::ModuleProcessor;

$|=1;
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
}

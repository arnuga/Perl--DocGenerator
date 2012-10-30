#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 2;
use Perl::DocGenerator::PodReader;

{
    my $pod = Perl::DocGenerator::PodReader->new('t/lib/ClassWithPod.pm');
    cmp_ok(ref($pod), 'eq', 'Perl::DocGenerator::PodReader');

    if ($pod) {
        warn "Name: " . $pod->name();
        my @methods = $pod->methods();
        cmp_ok(scalar @methods, '==', 3);
    }
}

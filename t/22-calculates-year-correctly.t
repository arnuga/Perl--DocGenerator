#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 3;
use Perl::DocGenerator::Writer::HTML;

{
    my $writer = Perl::DocGenerator::Writer->new();
    my ($gen_year, $gen_month, $gen_day) = $writer->_get_date_and_time_array();
    my ($day, $month, $year) = (localtime(time))[3..5];
    $year += 1900;

    cmp_ok($gen_year,  '==', $year);
    cmp_ok($gen_month, '==', $month);
    cmp_ok($gen_day,   '==', $day);
}

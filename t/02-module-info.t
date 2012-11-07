#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 4;

BEGIN { use_ok('Perl::DocGenerator::ModuleInfo') }

my $start_data = {
    module_name  => 'Bar',
    filename     => 't/lib/Bar.pm',
    scalars      => [ qw// ],
    arrays       => [ qw// ],
    hashes       => [ qw// ],
    io_handles   => [ qw// ],
    functions    => [ qw// ],
    base_classes => [ qw// ],
};

my $module = new_ok('Perl::DocGenerator::ModuleInfo', [$start_data]);

isa_ok($module, 'Perl::DocGenerator::ModuleInfo');

can_ok($module, qw/new module_name filename scalars arrays hashes io_handles functions public_functions private_functions base_classes/);

package Overloader;

use strict;

use overload
    'cmp' => \&blah,
    '--'  => \&blah,
    '<=>' => \&blah;

sub blah { }

1;

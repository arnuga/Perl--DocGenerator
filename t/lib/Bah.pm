package Bah;

use strict;

use parent qw/Baz Bar/;

our $other_global_thing;

sub new { } # this is overridding the base-class method

sub ahha {}

1;

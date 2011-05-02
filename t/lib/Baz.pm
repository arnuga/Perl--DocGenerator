package Baz;

use strict;

use parent qw/Bar/;

our $other_global_thing;

sub new { } # this is overridding the base-class method

sub order_drink {}

1;

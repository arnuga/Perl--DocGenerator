package Baz;

use strict;

use parent qw/Bar/;

sub new { } # this is overridding the base-class method

sub order_drink {}

1;

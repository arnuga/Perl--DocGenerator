package Perl::DocGenerator::Item;

use strict;

use Sub::Signatures;
use enum qw/
    :T_=0 SCALAR ARRAY HASH FUNCTION IOS PACKAGE
/;

use Class::MethodMaker
    [
        scalar => [{ -type => 'enum' }, 'object_type' ],
        scalar => [qw/name full_name package original_package base_classes/],
        new    => 'new',
        new    => [qw/ -hash new_hash_init /],
    ];

1;

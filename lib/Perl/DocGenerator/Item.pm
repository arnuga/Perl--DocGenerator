package Perl::DocGenerator::Item;

use strict;

use enum qw/
    :T_=0 SCALAR ARRAY HASH FUNCTION IOS PACKAGE BASE_CLASS
/;

require Exporter;
use vars qw/@ISA @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/T_SCALAR T_ARRAY T_HASH T_FUNCTION T_IOS T_PACKAGE T_BASE_CLASS/;

sub new
{
    my ($class) = @_;
    my $self = {
        base_classes     => [],
        full_name        => undef,
	    is_overridden    => undef,
        name             => undef,
        object_type      => undef,
        obj              => undef,
        original_package => undef,
        package          => undef,
        anchor_href      => undef,
    };
    bless $self, $class;
    return $self;
}

sub obj
{
    my ($self, $obj) = @_;
    if ($obj) {
        $self->{obj} = $obj;
    }
    return $self->{obj};
}

sub object_type
{
    my ($self, $object_type) = @_;
    if ($object_type) {
        $self->{object_type} = $object_type;
    }
    return $self->{object_type};
}

sub name
{
    my ($self, $name) = @_;
    if ($name) {
        $self->{name} = $name;
    }
    return $self->{name};
}

sub full_name
{
    my ($self, $full_name) = @_;
    if ($full_name) {
        $self->{full_name} = $full_name;
    }
    return $self->{full_name};
}

sub is_overridden
{
	my ($self, $is_overridden) = @_;
	if ($is_overridden) {
		$self->{is_overridden} = $is_overridden eq 'Y' ? 1 : undef;
	}
	return $self->{is_overridden} ? 'Y' : 'N';
}

sub anchor_href
{
    my ($self, $anchor_href) = @_;
    if ($anchor_href) {
        $self->{anchor_href} = $anchor_href;
    }

    return $self->{anchor_href};
}

sub package
{
    my ($self, $package) = @_;
    if ($package) {
        $self->{package} = $package;
    }
    return $self->{package};
}

sub original_package
{
    my ($self, $original_package) = @_;
    if ($original_package) {
        $self->{original_package} = $original_package;
    }
    return $self->{original_package};
}

sub base_classes
{
    my ($self, @base_classes) = @_;
    if (@base_classes) {
        $self->{base_classes} = [ @base_classes ];
    }
    return @{$self->{base_classes}};
}

1;

__END__

=head1 NAME

<Module::Name> - <One-line description of module's purpose>


=head1 VERSION

This documentation refers to <Module::Name> version 0.0.1.


=head1 SYNOPSIS

    use <Module::Name>;
    # Brief but working code example(s) here showing the most common usage(s).

    # This section will be as far as many users bother reading,
    # so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

=head2 new

=head2 base_classes

=head2 full_name

=head2 is_overridden

=head2 anchor_href

=head2 name

=head2 object_type

=head2 obj

=head2 original_package

=head2 package

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.


=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to the internal limitations of Perl
(for example, many modules that use source code filters are mutually incompatible).


=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.
(example)

There are no known bugs in this module.
Please reports problems to <Maintainer name(s)> (<contact address>)
Patches are welcome.


=head1 AUTHOR

<Author name(s)> (<contact address>)


=head1 LICENSE AND COPYRIGHT

Copyright (c) <year> <copyright holder> (<contact address>). All rights reserved.

followed by whatever license you wish to release it under.
(for Perl code that is often just:)

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PATICULAR PURPOSE.

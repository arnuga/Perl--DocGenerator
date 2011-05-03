package Perl::DocGenerator::ModuleProcessor;

use 5.006;
use strict;
use warnings;

require Devel::Symdump;

use Module::Load;
use Class::MethodMaker
    [
        scalar => [qw/obj package_name/],
        hash   => [qw/-static cached_modules/],
    ];

#use aliased 'Perl::DocGenerator::Item';

our $VERSION = '0.01';

sub new
{
    my ($class, $package) = @_;
    my $self = {};
    bless $self, $class;

    $self->package_name($package);

#    if (!__PACKAGE__->cached_modules_exists($package)) {
        eval { load($package) };
        if (my $err = $@) {
            die "Unable to load package '$package': $err";
        }
        $self->obj(Devel::Symdump->new($package));
#        __PACKAGE__->cached_modules_set($package, $self->obj);
#    } else {
#        my ($package_name, $obj) = __PACKAGE__->cached_modules_get($package);
#        $self->obj($obj);
#    }

    return $self;
}

sub base_classes
{
    my ($self) = @_;
    if ($self->_arrays > 0) {
        my ($isa_class) = grep { /ISA/ } $self->_arrays;
        if (defined $isa_class) {
            no strict 'refs';
            my @base_classes = grep { ! /@{[ $self->package_name ]}/ } @{ $self->package_name . '::ISA' };
            return @base_classes;
        }
    }
    return ();
}

sub packages
{
    my ($self) = @_;
    return $self->obj->packages;
}

sub scalars
{
    my ($self) = @_;
    my @scalars = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->scalars;
    my @functions = $self->functions;

    my %seen;
    my @scalaronly;

    @seen{@functions} = ();

    foreach my $item (@scalars) {
        push(@scalaronly, $item) unless (exists $seen{$item} || $item =~ /__ANON__/);
    }

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class)->scalars();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@scalaronly);
        push @scalaronly, @base_items;
    }

    @scalaronly = sort @scalaronly;
    return @scalaronly;
}

sub functions
{
    my ($self) = @_;
    my @functions = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->functions;

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class)->functions();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@functions);
        push @functions, @base_items;
    }

    @functions = sort @functions;
    return @functions;
}

sub private_functions
{
    my ($self) = @_;
    my @private_funcs = grep { /^_/ } $self->functions;
    foreach my $base_module ($self->base_classes) {
        push @private_funcs, $self->_module_for_package($base_module)->private_funcs;
    }

    @private_funcs = sort @private_funcs;
    return @private_funcs;
}

sub public_functions
{
    my ($self) = @_;
    my @public_funcs = grep { /^[^_]/ } $self->functions;

    foreach my $base_module ($self->public_functions) {
        push @public_funcs, $self->_module_for_package($base_module)->public_functions;
    }

    @public_funcs = sort @public_funcs;
    return @public_funcs;
}

sub arrays
{
    my ($self) = @_;
    my @arrays = grep { $_ ne uc($_) } $self->_arrays;

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class)->arrays();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@arrays);
        push @arrays, @base_items;
    }

    @arrays = sort @arrays;
    return @arrays;
}

sub _arrays
{
    my ($self) = @_;
    my @arrays = map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->arrays;
    return @arrays;
}

sub hashes
{
    my ($self) = @_;
    my @hashes = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->hashes;

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class)->hashes();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@hashes);
        push @hashes, @base_items;
    }

    @hashes = sort @hashes;
    return @hashes;
}

sub ios
{
    my ($self) = @_;
    my @ios = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->ios;

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class)->ios();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@ios);
        push @ios, @base_items;
    }

    @ios = sort @ios;
    return @ios;
}

sub _module_for_package
{
    my ($self, $package) = @_;
    return __PACKAGE__->new($package);
}

sub _unique_items_from_first_list
{
    my ($self, $arrayA, $arrayB) = @_;
    my %seen;
    my @aonly = ();
    @seen{@$arrayB} = ();

    map { push(@aonly, $_) unless exists $seen{$_} } @$arrayA;

    return @aonly;
}

sub _add_base_class_unique_items_to_list
{
    my ($self, $accessor, @items) = @_;

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class)->$accessor();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@items);
        push @items, @base_items;
    }

    return @items;
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

=head2 packages

=head2 scalars

=head2 functions

=head2 private_functions

=head2 public_functions

=head2 arrays

=head2 hashes

=head2 ios


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

package Perl::DocGenerator::ModuleProcessor;

use 5.006;
use strict;
use warnings;

require Devel::Symdump;
use base qw/Class::Accessor/;

use Module::Load;

__PACKAGE__->mk_accessors(qw/
    obj package_name
/);

use Perl::DocGenerator::Item;
use aliased 'Perl::DocGenerator::Item';

our $VERSION = '0.01';

sub new
{
    my ($class, $package) = @_;
    my $self = {};
    bless $self, $class;


    eval { load($package) };
    if (my $err = $@) {
        die "Unable to load package '$package': $err";
    }

    if ($package =~ /\.pm$/) {
        my $likely_module_name = $self->_module_name_from_filename($package);
        if ($likely_module_name) {
            $package = $likely_module_name;
        } else {
            die "Unable to determine module name from file: $package.  Maybe $package is not a real package or is a mixin style module?";
        }
    }
    $self->package_name($package);
    $self->obj(Devel::Symdump->new($package));

    return $self;
}

sub set
{
    my ($self, $key) = splice(@_, 0, 2);
    $self->SUPER::set($key, @_);
    return $self;
}

sub base_classes
{
    my ($self) = @_;
    my @return_base_classes = ();
    if ($self->_arrays > 0) {
        my ($isa_class) = grep { $_->name =~ /ISA/ } $self->_arrays;
        if (defined $isa_class) {
            no strict 'refs';
            my @base_classes = grep { ! /@{[ $self->package_name ]}/ } @{ $self->package_name . '::ISA' };
            foreach my $base_item (@base_classes) {
                my $item_obj = Item->new->object_type(T_BASE_CLASS)
                                        ->name($base_item)
                                        ->package($base_item)
                                        ->original_package($base_item)
                                        ->full_name($base_item);
                push(@return_base_classes, $item_obj);
            }
        }
    }
    return @return_base_classes;
}

sub packages
{
    my ($self) = @_;
    my @return_packages = ();
    foreach my $package ($self->packages) {
        my $item_obj = Item->new->object_type(T_PACKAGE)
                                ->name($package)
                                ->package($package)
                                ->original_package($package)
                                ->full_name($package);
        push(@return_packages, $item_obj);
    }
    return @return_packages;
}

sub scalars
{
    my ($self) = @_;
    my @scalars = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->scalars;
    my @functions = $self->functions;

    my %seen;
    my @scalaronly;

    @seen{map { $_->name } @functions} = ();

    foreach my $item (@scalars) {
        next if (exists $seen{$item} || $item =~ /__ANON__/);
        my $item_obj = Item->new->object_type(T_SCALAR)
                                ->name($item)
                                ->package($self->package_name)
                                ->original_package($self->package_name)
                                ->full_name(join('::', $self->package_name, $item));
        push(@scalaronly, $item_obj);
    }

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class->name)->scalars();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@scalaronly);
        push(@scalaronly, @base_items);
    }

    return @scalaronly;
}

sub functions
{
    my ($self) = @_;
    my @return_functions = ();
    my @functions = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->functions;

    foreach my $function (@functions) {
        my $item_obj = Item->new->object_type(T_FUNCTION)
                                ->name($function)
                                ->package($self->package_name)
                                ->original_package($self->package_name)
                                ->full_name(join('::', $self->package_name, $function));
        push(@return_functions, $item_obj);
    }

        foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class->name)->functions();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@return_functions);
        push(@return_functions, @base_items);
    }

    return @return_functions;
}

sub private_functions
{
    my ($self) = @_;
    my @private_funcs = grep { $_->name =~ /^_/ } $self->functions;

    return @private_funcs;
}

sub public_functions
{
    my ($self) = @_;
    my @public_funcs = grep { $_->name =~ /^[^_]/ } $self->functions;

    return @public_funcs;
}

sub arrays
{
    my ($self) = @_;
    my @return_arrays = $self->_arrays;

    foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class->name)->arrays();
        @base_items = $self->_unique_items_from_first_list(\@base_items, [ $self->_arrays ]);
        push(@return_arrays, @base_items);
    }

    return @return_arrays;
}

sub _arrays
{
    my ($self) = @_;
    my @return_arrays;
    my @arrays = map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->arrays;
    foreach my $array (@arrays) {
        my $item_obj = Item->new->object_type(T_ARRAY)
                                ->name($array)
                                ->package($self->package_name)
                                ->original_package($self->package_name)
                                ->full_name(join('::', $self->package_name, $array));
        push(@return_arrays, $item_obj);
    }

    return @return_arrays;
}

sub hashes
{
    my ($self) = @_;
    my @return_hashes;
    my @hashes = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->hashes;

    foreach my $hash (@hashes) {
        my $item_obj = Item->new->object_type(T_HASH)
                                ->name($hash)
                                ->package($self->package_name)
                                ->original_package($self->package_name)
                                ->full_name(join('::', $self->package_name, $hash));
        push(@return_hashes, $item_obj);
    }

        foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class->name)->hashes();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@return_hashes);
        push(@return_hashes, @base_items);
    }

    return @return_hashes;
}

sub ios
{
    my ($self) = @_;
    my @return_ios;
    my @ios = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->ios;

    foreach my $ios (@ios) {
        my $item_obj = Item->new->object_type(T_IOS)
                                ->name($ios)
                                ->package($self->package_name)
                                ->original_package($self->package_name)
                                ->full_name(join('::', $self->package_name, $ios));
        push(@return_ios, $item_obj);
    }

        foreach my $base_class ($self->base_classes) {
        my @base_items = $self->_module_for_package($base_class->name)->ios();
        @base_items = $self->_unique_items_from_first_list(\@base_items, \@return_ios);
        push(@return_ios, @base_items);
    }

    return @return_ios;
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
    @seen{map { $_->name } @$arrayB} = ();

    map { push(@aonly, $_) unless exists $seen{$_->name} } @$arrayA;

    return @aonly;
}

sub _module_name_from_filename
{
    my ($self, $filename) = @_;
    if (-f $filename) {
        open(FILE, $filename) or die "Unable to open file $filename for reading";
        my $first_line = <FILE>;
        close(FILE) or die "Unable to close file $filename, that's not really supposed to happen";
        chomp($first_line);

        $first_line =~ /package\s([^;]+);/i;
        if ($1) {
            my $package_name = $1;
            $package_name =~ s/\s*//g;
            return $package_name;
        }
    }
    return undef;
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

=head2 set

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

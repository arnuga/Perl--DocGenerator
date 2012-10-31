package Perl::DocGenerator::Writer::Screen;

use strict;

use base qw/Perl::DocGenerator::Writer/;

sub new
{
    my ($class) = @_;
    my $self = {
    };

    bless $self, $class;
    return $self;
}

sub write_package_description
{
    my ($self, $package) = @_;
    print <<HERE;
    Package: @{[ $package->package_name ]}
HERE

}

sub write_scalars
{
    my ($self, $package) = @_;
    if ($package->scalars > 0) {
        print "\tScalars:\n";
        map { print "\t\t@{[ $_->name ]}\n" } $package->scalars;
    }
}

sub write_arrays
{
    my ($self, $package) = @_;
    if ($package->arrays > 0) {
        print "\tArrays:\n";
        map { print "\t\t@{[ $_->name ]}\n" } $package->arrays;
    }
}

sub write_hashes
{
    my ($self, $package) = @_;
    if ($package->hashes > 0) {
        print "\tHashes:\n";
        map { print "\t\t@{[ $_->name ]}\n" } $package->hashes;
    }
}

sub write_ios
{
    my ($self, $package) = @_;
    if ($package->ios > 0) {
        print "\tIO's:\n";
        map { print "\t\t@{[ $_->name ]}\n" } $package->ios;
    }
}

sub write_public_functions
{
    my ($self, $package) = @_;
    if ($package->public_functions > 0) {
        print "\tPublic Functions:\n";
        my @local_functions = ();
        my %inherited_functions = ();
        foreach my $function ($package->public_functions) {
            if ($function->package eq $package->package_name) {
                push(@local_functions, $function);
            } else {
                push(@{$inherited_functions{$function->original_package}}, $function);
            }
        }

        map {
            print "\t\t@{[ $_->name ]}\n"
        } @local_functions;

        foreach my $key (keys %inherited_functions) {
            my @sub_functions = @{$inherited_functions{$key}};
#            print "\tPublic Functions (from: @{[ $key ]})\n";
            map {
                print "\t\t@{[ join('::', $_->original_package, $_->name) ]}\n";
            } @sub_functions;
        }
    }
}

sub write_private_functions
{
    my ($eslf, $package) = @_;
    if ($package->private_functions > 0) {
        print "\tPrivate Functions:\n";
        my @local_functions = ();
        my %inherited_functions = ();
        foreach my $function ($package->private_functions) {
            if ($function->package eq $package->package_name) {
                push(@local_functions, $function);
            } else {
                push(@{$inherited_functions{$function->original_package}}, $function);
            }
        }

        map {
            print "\t\t@{[ $_->name ]}\n"
        } @local_functions;

        foreach my $key (keys %inherited_functions) {
            my @sub_functions = @{$inherited_functions{$key}};
#            print "\tPrivate Functions (from: @{[ $key ]})\n";
            map {
                print "\t\t@{[ join('::', $_->original_package, $_->name) ]}\n";
            } @sub_functions;
        }
    }
}

sub write_imbedded_pod
{
    print "\n";
}

1;

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

=head2 write_package_description

=head2 write_scalars

=head2 write_arrays

=head2 write_hashes

=head2 write_ios

=head2 write_public_functions

=head2 write_private_functions

=head2 write_imbedded_pod

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

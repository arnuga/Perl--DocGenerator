package Perl::DocGenerator;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/
    recursive
    folders
    packages
/);

use Perl::DocGenerator::ModuleProcessor;
use Perl::DocGenerator::Writer;

our @loaded_packages = ();

sub set
{
    my ($self, $key) = splice(@_, 0, 2);
    $self->SUPER::set($key, @_);

    return $self;
}

sub scan_packages
{
    my ($self, @packages) = @_;
    if ($self->folders || $self->packages || @packages) {
        my @locations = ($self->folders, $self->packages, @packages);
        foreach my $location (@locations) {
            if ($location) {
                my $mod_proc = Perl::DocGenerator::ModuleProcessor->new($location, $self->recursive);
                if ($mod_proc) {
                    push(@loaded_packages, $mod_proc);
                }
            }
        }
    }
}

sub output
{
    my ($self, $writer_class) = @_;

    my $writer = Perl::DocGenerator::Writer->new({writer_class => $writer_class});
    $writer->initialize_writer();
    foreach my $package (@loaded_packages) {
        $writer->write_package($package);
    }
    $writer->finish;
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

=head2 set

=head2 scan_packages

=head2 output

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

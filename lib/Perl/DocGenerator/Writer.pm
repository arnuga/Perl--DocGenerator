package Perl::DocGenerator::Writer;

use strict;

use Module::Load;

sub new
{
    my ($class) = @_;
    my $self = {
        writer_class => undef,
        writer_obj   => undef,
    };

    bless $self, $class;
    return $self;
}

sub writer_class
{
    my ($self, $writer_class) = @_;
    if ($writer_class) {
        $self->{writer_class} = $writer_class;
    }
    return $self->{writer_class};
}

sub writer_obj
{
    my ($self, $writer_obj) = @_;
    if ($writer_obj) {
        $self->{writer_obj} = $writer_obj;
    }
    return $self->{writer_obj};
}

sub initialize_writer
{
    my ($self) = @_;
    if (! $self->writer_class()) {
        $self->writer_class('Perl::DocGenerator::Writer::Screen');
    }
    if ($self->_load_and_verify_writer()) {
        if ($self->writer_obj() && $self->writer_obj()->can('init_writer')) {
            $self->writer_obj()->init_writer();
        }
        return 1;
    }
    return undef;
}

sub write_package
{
    my ($self, $package_obj) = splice(@_, 0, 2);
    if ($self->writer_obj()->can('before_package')) {
        $self->writer_obj()->before_package($package_obj);
    }
    $self->writer_obj()->write_package_description($package_obj);
    $self->writer_obj()->write_scalars($package_obj);
    $self->writer_obj()->write_arrays($package_obj);
    $self->writer_obj()->write_hashes($package_obj);
    $self->writer_obj()->write_ios($package_obj);
    $self->writer_obj()->write_public_functions($package_obj);
    $self->writer_obj()->write_private_functions($package_obj);
    $self->writer_obj()->write_extra_imbedded_pod($package_obj);

    if ($self->writer_obj()->can('after_package')) {
        $self->writer_obj()->after_package($package_obj);
    }
}

sub finish
{
    my ($self) = @_;
    if ($self->writer_obj()->can('before_finish')) {
        $self->writer_obj()->before_finish();
    }
}

sub _load_and_verify_writer
{
    my ($self) = @_;

    if ($self->writer_class()) {
        eval { load($self->writer_class()) };
        if (my $err = $@) {
            die "Ah, can't load writer class @{[ $self->writer_class() ]}: $err";
        }

        eval {
            my $writer_obj = $self->writer_class()->new;
            foreach my $required_method (qw/write_package_description
                                            write_scalars
                                            write_arrays
                                            write_hashes
                                            write_ios
                                            write_public_functions
                                            write_private_functions
                                            write_extra_imbedded_pod/) {
                die "Your writer class must define $required_method" unless ($writer_obj->can($required_method));
            }
            $self->writer_obj($writer_obj);
        };
    } else {
        die "No writer class was provided";
    }
    return 1;
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

=head2 writer_class

=head2 writer_obj

=head2 initialize_writer

=head2 init_writer

=head2 before_package

=head2 after_package

=head2 write_package

=head2 finish

=head2 _load_and_verify_writer

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

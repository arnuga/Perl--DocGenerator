package Perl::DocGenerator;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/
    recursive
    folders
    packages
/);

use Perl::DocGenerator::ModuleProcessor;
use Perl::DocGenerator::Writer;
use File::Spec;

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
    my @locations = grep { defined $_ } ($self->folders, $self->packages, @packages);
    
    # translate folder paths into perl files at said path(s)
    my @new_locations;
    foreach my $location (@locations) {
       if ($location !~ /\.pm$/) {
           my @perl_packages_at_location = glob(File::Spec->catfile($location, '*.pm'));
           push @new_locations, @perl_packages_at_location if (@perl_packages_at_location > 0);
           pop @locations; # remove this item from the locations list
       }
    }
    push @locations, @new_locations;

    foreach my $location (@locations) {
        if ($location) {
            print "Scanning $location\n";
            my $mod_proc;
            eval { $mod_proc = Perl::DocGenerator::ModuleProcessor->new($location, $self->recursive); };
            if ($mod_proc) {
                push(@loaded_packages, $mod_proc);
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

Perl::DocGenerator - Generate documentation from raw perl code


=head1 VERSION

This documentation refers to Perl::DocGenerator version 0.0.2.


=head1 SYNOPSIS

    use Perl::DocGenerator;

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

=head2 set

=head2 scan_packages

=head2 output


=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT


=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Perl::DocGenerator does not support multiple packages defined
inside the same file.  You would never do that anyway right?
Please reports problems to David Shultz (djshultz@gmail.com)
Patches are welcome.


=head1 AUTHOR

David Shultz (djshultz@gmail.com)


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 David Shultz (djshultz.@gmail.com). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PATICULAR PURPOSE.

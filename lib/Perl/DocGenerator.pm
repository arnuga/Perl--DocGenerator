package Perl::DocGenerator; 
use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Perl::DocGenerator::ModuleProcessor;
use Perl::DocGenerator::Writer;
use File::Find;
use Class::Unload;

sub new
{
    my ($class) = @_;
    my $self = {
        folders         => [],
        loaded_packages => [],
        packages        => [],
        recursive       => undef,
    };
    bless $self, $class;
    return $self;
}

sub recursive
{
    my ($self, $is_recursive) = @_;
    if ($is_recursive) {
        $self->{recursive} = $is_recursive;
    }
    return $self->{recursive};
}

sub folders
{
    my ($self, @folders) = @_;
    if (@folders > 0) {
        $self->{folders} = [@folders];
    }
    return @{$self->{folders}};
}

sub packages
{
    my ($self, @packages) = @_;
    if (@packages > 0) {
        $self->{packages} = [@packages];
    }
    return @{$self->{packages}};
}

sub loaded_packages
{
    my ($self, @loaded_packages) = @_;
    if (@loaded_packages > 0) {
        $self->{loaded_packages} = [ @loaded_packages ];
    }

    return @{$self->{loaded_packages}};
}

sub scan_packages
{
    my ($self, @packages) = @_;
    my @locations = grep { defined $_ } ($self->folders(), $self->packages(), @packages);
    $self->_find_perl_modules_at_locations(@locations); 

#    {
#        BEGIN { $^W = 0 }   # it's not my code, you make it compile clean
#        no warnings 'all';  # no seriously, I said shutup!

        print "Processing packages...\n";
        my $total_packages = scalar $self->packages();
        my $i = 1;
        foreach my $location ($self->packages()) {
            if ($location) {
                print "[$i/$total_packages] $location\n";
                my $mod_proc;
                eval { Perl::DocGenerator::ModuleProcessor->new($location, $self->recursive()); };
            }
            $i++;
        }
#    }
    $self->loaded_packages(Perl::DocGenerator::ModuleProcessor->modules);
    print "done\n";
}

sub output
{
    my ($self, $writer_class) = @_;

    my $writer = Perl::DocGenerator::Writer->new();
    if ($writer_class) {
        $writer->writer_class($writer_class);
    }
    $writer->initialize_writer();
    print "Writing packages...";
    my $total_packages = scalar $self->loaded_packages() - 1;
    my $i = 0;
    foreach my $package ($self->loaded_packages) {
        print "Writing [$i/$total_packages] " . $package->module_name() . "\n";
        $writer->write_package($package);
        Class::Unload->unload($package);
        $i++;
    }
    $writer->finish;
    print "done\n";
}

sub _find_perl_modules_at_locations
{
    my ($self, @locations) = @_;
#    if (! $self->recursive()) {
#        $File::Find::prune = 1; #disable recursive scanning
#    }
    print "Scanning for packages...";
    find(sub { $self->_perl_files_in_folder($File::Find::name) }, @locations);
    print "done\n";
}

sub _perl_files_in_folder
{
    my ($self, $filename) = @_;
    if ($filename =~ /\.pm$/) {
        my $dir = $File::Find::dir;

        my @packages = $self->packages();
        push @packages, $filename;
        $self->packages(@packages);
    }
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

=head2 new

=head2 recursive

=head2 folders

=head2 packages

=head2 loaded_packages

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

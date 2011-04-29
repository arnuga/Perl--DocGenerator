package Perl::DocGenerator::ModuleProcessor;

use 5.006;
use strict;
use warnings;

require Devel::Symdump;

use Module::Load;
use Sub::Signatures;
use Class::MethodMaker
    [
        scalar => [qw/obj package_name/],
        hash   => [qw/-static cached_modules/],
    ];

use aliased 'Perl::DocGenerator::Item';

sub new
{
    my ($class, $package) = @_;
    my $self = {};
    bless $self, $class;

    $self->package_name($package);

    if (!__PACKAGE__->cached_modules_exists($package)) {
        eval { load($package) };
        if (my $err = $@) {
            die "Unable to load package '$package': $err";
        }
        $self->obj(Devel::Symdump->new($package));
        __PACKAGE__->cached_modules_set($package, $self->obj);
    } else {
        $self->obj(__PACKAGE__->cached_modules_get($package));
    }

    return $self;
}

sub base_classes($self)
{
    if ($self->arrays > 0) {
        my ($isa_class) = grep { /ISA/ } $self->arrays;
        if ($isa_class) {
            my @base_classes = @$self::ISA;
            return @base_classes;
        }
    }
    return ();
}

sub packages($self)
{
    return $self->obj->packages;
}

sub scalars($self)
{
    my @scalars = grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->scalars;
    my @functions = $self->functions;

    my %seen;
    my @scalaronly;

    @seen{@functions} = ();

    foreach my $item (@scalars) {
        push(@scalaronly, $item) unless (exists $seen{$item} || $item =~ /__ANON__/);
    }

    @scalaronly = sort @scalaronly;
    return @scalaronly;
}

sub functions($self)
{
    my @functions = sort grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->functions;
    return @functions;
}

sub private_functions($self)
{
    my @private_funcs = sort grep { /^_/ } $self->functions;
    return @private_funcs;
}

sub public_functions($self)
{
    my @public_funcs = sort grep { /^[^_]/ } $self->functions;
    return @public_funcs;
}

sub arrays($self)
{
    my @arrays = sort grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->arrays;
    return @arrays;
}

sub hashes($self)
{
    my @hashes = sort grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->hashes;
    return @hashes;
}

sub ios($self)
{
    my @ios = sort grep { $_ ne uc($_) } map { /@{[ $self->package_name ]}::(.*)/ } $self->obj->ios;
    return @ios;
}

=head1 NAME

Perl::DocGenerator::ModuleProcessor - The great new Perl::DocGenerator::ModuleProcessor!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Perl::DocGenerator::ModuleProcessor;

    my $foo = Perl::DocGenerator::ModuleProcessor->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

David Shultz, C<< <djshultz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perl-docgenerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-DocGenerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::DocGenerator::ModuleProcessor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-DocGenerator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-DocGenerator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-DocGenerator>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-DocGenerator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Shultz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Perl::DocGenerator::ModuleProcessor

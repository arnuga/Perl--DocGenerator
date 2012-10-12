package Perl::DocGenerator::Writer::HTML;

use strict;

use base qw/Perl::DocGenerator::Writer/;
use Module::Load;
use HTML::Template;
use Module::Info;
use File::Spec;

__PACKAGE__->mk_accessors(qw/
    package_template_file
    toc_template_file
    header_template_file
    footer_template_file
    page_template
    toc_template
    header_template
    footer_template
    pages
/);

sub init_writer
{
    my ($self) = @_;

    $self->pages([]);
    my $package_info = Module::Info->new_from_loaded(__PACKAGE__);
    if ($package_info) {
        my $base_template_dir = File::Spec->catfile(
          $package_info->inc_dir,
          'Perl',
          'DocGenerator',
          'Writer',
          'html_templates'
        );

        my $default_package_template_file = File::Spec->catfile($base_template_dir, 'package.tmpl');
        if ($default_package_template_file && -f $default_package_template_file) {
            $self->package_template_file($default_package_template_file);
        }

        my $default_toc_template_file = File::Spec->catfile($base_template_dir, 'toc.tmpl');
        if ($default_toc_template_file && -f $default_toc_template_file) {
            $self->toc_template_file($default_toc_template_file);
        }

        my $default_header_template_file = File::Spec->catfile($base_template_dir, 'header.tmpl');
        if ($default_header_template_file && -f $default_header_template_file) {
            $self->header_template_file($default_header_template_file);
        }

        my $default_footer_template_file = File::Spec->catfile($base_template_dir, 'footer.tmpl');
        if ($default_footer_template_file && -f $default_footer_template_file) {
            $self->footer_template_file($default_footer_template_file);
        }
    } else {
        die "Unable to location physical html template files";
    }

    die "Missing one or more templates"
        unless ($self->package_template_file
             && $self->toc_template_file
             && $self->header_template_file
             && $self->footer_template_file);
}

sub before_package
{
    my ($self, $package) = @_;
    $self->page_template(HTML::Template->new(filename => $self->package_template_file));
}

sub after_package
{
    my ($self, $package) = @_;
    if ($self->page_template) {
        my @pages = @{$self->pages()};
        push @pages, { $package->package_name => $self->page_template->output };
        $self->pages([@pages]);
    }
}

sub write_package_description
{
    my ($self, $package) = @_;
    $self->page_template->param(PACKAGE_NAME => $package->package_name);
}

sub write_scalars
{
    my ($self, $package) = @_;
    if ($package->scalars > 0) {
        $self->page_template->param(HAS_SCALARS => 1);
        $self->page_template->param(
            SCALARS => [ map { { SCALAR => $_ } } $package->scalars ]
        );
    }
}

sub write_arrays
{
    my ($self, $package) = @_;
    if ($package->arrays > 0) {
        $self->page_template->param(HAS_ARRAYS => 1);
        $self->page_template->param(
            ARRAYS => [ map { { ARRAY => $_ } } $package->arrays ]
        );
    }
}

sub write_hashes
{
    my ($self, $package) = @_;
    if ($package->hashes > 0) {
        $self->page_template->param(HAS_HASHES => 1);
        $self->page_template->param(
            HASHES => [ map { { HASH => $_ } } $package->hashes ]
        );
    }
}

sub write_ios
{
    my ($self, $package) = @_;
    if ($package->ios > 0) {
        $self->page_template->param(HAS_IOS => 1);
        $self->page_template->param(
            IOS => [ map { { IO => $_ } } $package->ios ]
        );
    }
}

sub write_public_functions
{
    my ($self, $package) = @_;
    if ($package->public_functions > 0) {
        $self->page_template->param(HAS_PUBLIC_FUNCTIONS => 1);
        $self->page_template->param(
            PUBLIC_FUNCTIONS => [ map { { FUNCTION_NAME => $_ } } $package->public_functions ]
        );
    }
}

sub write_private_functions
{
    my ($self, $package) = @_;
    if ($package->private_functions > 0) {
        $self->page_template->param(HAS_PRIVATE_FUNCTIONS => 1);
        $self->page_template->param(
            PRIVATE_FUNCTIONS => [ map { { FUNCTION_NAME => $_ } } $package->private_functions ]
        );
    }
}

sub write_extra_imbedded_pod
{
#    print "\n";
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

=head2 init_writer
    Sets up the template files to be used for output (uses HTML::Template)

=head2 before_package
    Initializes the HTML::Template object

=head2 after_package
    Finalizes the current template file and writes output

=head2 write_package_description

=head2 write_scalars

=head2 write_arrays

=head2 write_hashes

=head2 write_ios

=head2 write_public_functions

=head2 write_private_functions

=head2 write_extra_imbedded_pod

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please reports problems to David Shultz (djshultz@gmail.com)
Patches are welcome.


=head1 AUTHOR

David Shultz (djshultz@gmail.com)


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 David Shultz (djshultz@gmail.com). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PATICULAR PURPOSE.

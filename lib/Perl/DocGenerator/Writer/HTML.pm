package Perl::DocGenerator::Writer::HTML;

use strict;

use base qw/Perl::DocGenerator::Writer/;
use HTML::Template;
use Module::Info;
use File::Spec;

sub new
{
    my ($class) = @_;
    my $self = {
        footer_template_file  => undef,
        header_template_file  => undef,
        index_template_file   => undef,
        index_template        => undef,
        packages              => [],
        package_template_file => undef,
        page_template         => undef,
    };

    bless $self, $class;
    return $self;
}

sub footer_template_file
{
    my ($self, $footer_template_file) = @_;
    if ($footer_template_file) {
        $self->{footer_template_file} = $footer_template_file;
    }
    return $self->{footer_template_file};
}

sub header_template_file
{
    my ($self, $header_template_file) = @_;
    if ($header_template_file) {
        $self->{header_template_file} = $header_template_file;
    }

    return $self->{header_template_file};
}

sub index_template_file
{
    my ($self, $index_template_file) = @_;
    if ($index_template_file) {
        $self->{index_template_file} = $index_template_file;
    }

    return $self->{index_template_file};
}

sub index_template
{
    my ($self, $index_template) = @_;
    if ($index_template) {
        $self->{index_template} = $index_template;
    }

    return $self->{index_template};
}

sub packages
{
    my ($self, @packages) = @_;
    if (@packages) {
        $self->{packages} = [ @packages ];
    }

    return @{$self->{packages}};
}

sub package_template_file
{
    my ($self, $package_template_file) = @_;
    if ($package_template_file) {
        $self->{package_template_file} = $package_template_file;
    }

    return $self->{package_template_file};
}

sub page_template
{
    my ($self, $page_template) = @_;
    if ($page_template) {
        $self->{page_template} = $page_template;
    }

    return $self->{page_template};
}

sub init_writer
{
    my ($self) = @_;

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

        my $default_header_template_file = File::Spec->catfile($base_template_dir, 'header.tmpl');
        if ($default_header_template_file && -f $default_header_template_file) {
            $self->header_template_file($default_header_template_file);
        }

        my $default_footer_template_file = File::Spec->catfile($base_template_dir, 'footer.tmpl');
        if ($default_footer_template_file && -f $default_footer_template_file) {
            $self->footer_template_file($default_footer_template_file);
        }

        my $default_index_template_file = File::Spec->catfile($base_template_dir, 'index.tmpl');
        if ($default_index_template_file && -f $default_index_template_file) {
            $self->index_template_file($default_index_template_file);
        }
    } else {
        die "Unable to location physical html template files";
    }

    die "Missing one or more templates"
        unless ($self->header_template_file
             && $self->package_template_file
             && $self->footer_template_file
             && $self->index_template_file);
}

sub before_package
{
    my ($self, $package) = @_;
    $self->page_template(HTML::Template->new(filename => $self->package_template_file));
    $self->_set_global_template_params($self->page_template);
}

sub after_package
{
    my ($self, $package) = @_;

    my @packages = $self->packages();
    push @packages, $package;
    $self->packages(@packages);

    if ($self->page_template) {
        my $page_output = $self->page_template->output();
        my $filename = $self->_filename_from_package_name($package->package_name);
        open(FILE, ">$filename") or die "Unable to create file $filename: $!\n";
        print FILE $page_output;
        close(FILE) or die "Unable to close file $filename: $!\n";
    }
}

sub before_finish
{
    my ($self) = @_;
    $self->index_template(HTML::Template->new(filename => $self->index_template_file));
    $self->_set_global_template_params($self->index_template);
    $self->write_index();
    my $index_output = $self->index_template->output();
    open(FILE, ">index.html") or die "Unable to create file: index.html: $!\n";
    print FILE $index_output;
    close(FILE) or die "Unable to close index.html: $!\n";
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
            SCALARS => [ map { { SCALAR => $_->name() } } $package->scalars ]
        );
    }
}

sub write_arrays
{
    my ($self, $package) = @_;
    if ($package->arrays > 0) {
        $self->page_template->param(HAS_ARRAYS => 1);
        $self->page_template->param(
            ARRAYS => [ map { { ARRAY => $_->name() } } $package->arrays ]
        );
    }
}

sub write_hashes
{
    my ($self, $package) = @_;
    if ($package->hashes > 0) {
        $self->page_template->param(HAS_HASHES => 1);
        $self->page_template->param(
            HASHES => [ map { { HASH => $_->name() } } $package->hashes ]
        );
    }
}

sub write_ios
{
    my ($self, $package) = @_;
    if ($package->ios > 0) {
        $self->page_template->param(HAS_IOS => 1);
        $self->page_template->param(
            IOS => [ map { { IO => $_->name() } } $package->ios ]
        );
    }
}

sub write_public_functions
{
    my ($self, $package) = @_;
    if ($package->public_functions > 0) {
        $self->page_template->param(HAS_PUBLIC_FUNCTIONS => 1);
        $self->page_template->param(
            PUBLIC_FUNCTIONS => [
                map {
                    {
                        FUNCTION_NAME => $_->name(),
                        BASE_CLASS_FUNCTION_HREF => $self->_base_class_href_from_item($_),
                        BASE_CLASS_FUNCTION_NAME => $self->_base_class_name_from_item($_),
                    }
                } $package->public_functions ]
        );
    }
}

sub write_private_functions
{
    my ($self, $package) = @_;
    if ($package->private_functions > 0) {
        $self->page_template->param(HAS_PRIVATE_FUNCTIONS => 1);
        $self->page_template->param(
            PRIVATE_FUNCTIONS => [
                map {
                    {
                        FUNCTION_NAME => $_->name(),
                        BASE_CLASS_FUNCTION_HREF => $self->_base_class_href_from_item($_),
                        BASE_CLASS_FUNCTION_NAME => $self->_base_class_name_from_item($_),
                    }
                } $package->private_functions ]
        );
    }
}

sub write_extra_imbedded_pod
{
#    print "\n";
}

sub write_index
{
    my ($self) = @_;

    my @packages = $self->packages();
    if (scalar @packages > 0) {
        $self->index_template->param(
            PACKAGES => [ map {
                {
                    PACKAGE_NAME => $_->package_name,
                    PACKAGE_HREF => $self->_filename_from_package_name($_->package_name)
                }
            } @packages ]
        );
    }
}

sub _set_global_template_params
{
    my ($self, $template) = @_;
    $template->param(PERL_DOCGENERATOR_VERSION => $Perl::DocGenerator::VERSION);
#   0    1    2     3     4    5     6     7     8
#  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    my ($sec, $min, $hr, $day, $mon, $year) = (localtime(time))[0..5];
    $template->param(GENERATED_DATE => sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $day, $hr, $min, $sec));
}

sub _filename_from_package_name
{
    my ($self, $package_name) = @_;
    $package_name =~ s/\:\:/_/g;
    $package_name .= '.html';
    return $package_name;
}

sub _base_class_href_from_item
{
    my ($self, $item) = @_;
    my $base_package_name = $self->_base_class_name_from_item($item);
    if ($base_package_name) {
        return $self->_filename_from_package_name($base_package_name);
    }
    return undef;
}

sub _base_class_name_from_item
{
    my ($self, $item) = @_;
    if ($item) {
        if ($item->package ne $item->original_package) {
            return $item->original_package;
        }
    }
    return undef;
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

=head2 footer_template_file

=head2 header_template_file

=head2 index_template_file

=head2 index_template

=head2 packages

=head2 package_template_file

=head2 page_template

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

=head2 write_index

=head2 before_finish

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

The following templates exist and can be over-written by you.
index.tmpl
header.tmpl
package.tmpl
footer.tmpl

Following is the list of each template file and what HTML::Template variables
have been defined (and thus are available to you).

Doc Generator HTML Template names:

Global:
VAR:
    generated_date
    perl_docgenerator_version

Header:
VAR:
    prev_class_href
    prev_class_href_name
    next_class_href
    next_class_href_name
    index_href

Footer:
VAR:
    prev_class_href
    prev_class_href_name
    next_class_href
    next_class_href_name
    index_href

Index:
VAR:
    package_href
    package_name

LOOP:
    packages

Package:
VAR:
    package_name
    base_class_name
    package_pod
    scalar
    array
    hash
    io
    function_name
    function_pod
    base_class_function_href
    base_class_function_href_name

BOOL:
    has_base_classes
    has_scalars
    has_arrays
    has_hashes
    has_ios
    has_public_functions
    has_private_functions

LOOP:
    base_classes
    scalars
    arrays
    hashes
    ios
    public_functions
    private_functions


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

package Perl::DocGenerator::ModuleProcessor;

use 5.006;
use strict;
use warnings;

require Devel::Symdump;

use Perl::DocGenerator::ModuleInfo;
use Module::Load;
use JSON;
use POSIX ":sys_wait_h";
use Data::Dumper;

$|=1; #disables IO buffering

our $VERSION = '0.01';

my %modules_loaded;

sub new
{
    my ($class, $package_string) = @_;
    my $self = {
        module_info       => undef,
        package_string    => $package_string,
    };
    bless $self, $class;

    #BEGIN { $^W = 0 }   # it's not my code, you make it compile clean
    #no warnings 'all';  # no seriously, I said shutup!
    if (my $child_pid = open(CHILD, "-|")) {
        # in the parent
        waitpid($child_pid, 0);
        my ($raw_result) = (<CHILD>);
        close(CHILD);
        $self->_parent_reader($raw_result);
    } else {
        die "Cannot fork: $!" unless defined $child_pid;
        # in the child
        $self->_child_extractor();
    }
    
    return $self;
}

sub package_string
{
    my ($self, $package_string) = @_;
    if ($package_string) {
        $self->{package_string} = $package_string;
    }
    return $self->{package_string};
}

sub modules
{
    my ($self) = @_;
    return values %modules_loaded;
}

sub module
{
    my ($self, $module_name) = @_;
    if ($module_name) {
        return $modules_loaded{$module_name} if (exists $modules_loaded{$module_name});
    }

    return undef;
}

sub _parent_reader
{
    my ($self, $json_result) = @_;
    my $raw_module_info = decode_json($json_result);
    my $module_info_obj = Perl::DocGenerator::ModuleInfo->new($raw_module_info);

    if ($module_info_obj) {
        # put this on the master stack
        $modules_loaded{$module_info_obj->module_name()} = $module_info_obj;

        # load all base classes since we'll need them later for inheritance details
        # we load base classes in the order in which they appeared in the file
        foreach my $base_class ($module_info_obj->base_classes()) {
            __PACKAGE__->new($base_class->name);
            my $base_class_obj = $self->module($base_class->name);
            $module_info_obj->update_links_to_base_class_data($base_class_obj);
        }
    } else {
        warn "Error reading json response: $raw_module_info\n";
    }
}

sub _child_extractor
{
    my ($self) = @_;

    my $devel_symbol;
    #use the package name as a hash key to untaint it (this is really only needed for the tests)
    my %worthless_hash;
    $worthless_hash{$self->package_string} = 1;
    my ($package_string) = keys %worthless_hash;

    eval { load($package_string); };
    if (my $load_err = $@) {
        warn "Unable to load package '" . $self->package_string . "': $load_err";
        exit;
    }

    my ($module_name, $filename) = $self->_module_name_from_package_string();

    if ($module_name && $filename) {
        eval { $devel_symbol = Devel::Symdump->new($module_name); };
        if (my $eval_err = $@) {
            warn "Unable to load package $module_name with Devel::Symdump!: $eval_err";
            exit;
        }

        no strict 'refs';
        my $module_info = {
            module_name  => $module_name,
            filename     => $filename,
            scalars      => [ $devel_symbol->scalars()                                ],
            arrays       => [ $devel_symbol->arrays()                                 ],
            hashes       => [ $devel_symbol->hashes()                                 ],
            io_handles   => [ $devel_symbol->ios()                                    ],
            functions    => [ $devel_symbol->functions()                              ],
            base_classes => [ grep { ! /$module_name/ } @{ $module_name . '::ISA' } ],
        };

        my $json_response = encode_json($module_info);
        print STDOUT $json_response;
    } else {
        warn "Unable to determine module_name: $module_name from " . $self->package_string();
        print STDOUT "this should not be valid JSON data";
    }
    exit;
}

sub _module_name_from_package_string
{
    my ($self) = @_;

    my $package_string = $self->package_string();

    # we want to find the package name but %INC will have it with a .pm at the end
    $package_string .= '.pm' unless ($package_string =~ /\.pm$/);
    # inc only carries files in the form usr/lib/blah.pm even if I loaded it as "use Blah;"
    $package_string =~ s/\:\:/\//g;

    my @possible_package_matches = grep { /$package_string$/ } values %INC;
    if (@possible_package_matches > 0) {
        if (@possible_package_matches > 1) {
            warn "I have no idea, multple matches found\n";
            return;
        } else {
            my %flipped_hash = _flip_hash(%INC);
            my $package_name = $flipped_hash{$possible_package_matches[0]};
            if ($package_name) {
                $package_name =~ s/\.pm$//;
                $package_name =~ s/\//::/g;

                return ($package_name, $possible_package_matches[0]);
            }
        }
    }
    return ();
}

sub _flip_hash
{
    my (%original_inc) = @_;

    my %new_inc;
    while (my ($key, $value) = each %original_inc) {
        $new_inc{$value} = $key;
    }

    return %new_inc;
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

=head2 package_name

=head2 modules

=head2 module

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

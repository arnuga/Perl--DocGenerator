package Perl::DocGenerator::PodReader;

use strict;

use Pod::POM;

sub new
{
    my ($class, $filename, @package_function_names) = @_;
    my $self = {
        filename               => $filename,
        pod_obj                => undef,
        pod_head1_sections     => [],
        package_function_names => [ @package_function_names ],
        _parsed_pod_nodes      => {},
    };
    bless $self, $class;

    my $parser = Pod::POM->new();
    $self->pod_obj($parser->parse_file($self->filename));
    if ($self->pod_obj()) {
        my @head1_items = $self->pod_obj()->head1();
        if (scalar @head1_items > 0) {
            $self->{pod_head1_sections} = \@head1_items;
        }
    }

    return $self;
}

sub filename
{
    my ($self, $filename) = @_;
    if ($filename) {
        $self->{filename} = $filename;
    }
    return $self->{filename};
}

sub pod_obj
{
    my ($self, $pod_obj) = @_;
    if ($pod_obj) {
        $self->{pod_obj} = $pod_obj;
    }
    return $self->{pod_obj};
}

sub head1_text
{
    my ($self, $type) = @_;
    if ($self->pod_obj()) {
        foreach my $head1 (@{ $self->{pod_head1_sections} }) {
            if ($head1->title() =~ /$type/) {
                my $name_text = join("\n", $head1->text());
                $name_text =~ s/\n+/\n/g; # cut multple newlines down to 1 each
                return $name_text;
            }
        }
    }
    return undef;
}

sub name              { (shift)->head1_text('NAME')              }
sub version           { (shift)->head1_text('VERSION')           }
sub synopsis          { (shift)->head1_text('SYNOPSIS')          }
sub description       { (shift)->head1_text('DESCRIPTION')       }
sub diagnostics       { (shift)->head1_text('DIAGNOSTICS')       }
sub configuration     { (shift)->head1_text('CONFIGURATION')     }
sub environment       { (shift)->head1_text('ENVIRONMENT')       }
sub dependencies      { (shift)->head1_text('DEPENDENCIES')      }
sub incompatibilities { (shift)->head1_text('INCOMPATIBILITIES') }
sub bugs              { (shift)->head1_text('BUGS')              }
sub limitations       { (shift)->head1_text('LIMITATIONS')       }
sub support           { (shift)->head1_text('SUPPORT')           }
sub see_also          { (shift)->head1_text('SEE_ALSO')          }
sub todo              { (shift)->head1_text('TODO')              }
sub notes             { (shift)->head1_text('NOTES')             }
sub exports           { (shift)->head1_text('EXPORTS')           }
sub copyright         { (shift)->head1_text('COPYRIGHT')         }
sub disclaimer        { (shift)->head1_text('DISCLAIMER')        }
sub acknowledgements  { (shift)->head1_text('ACKNOWLEDGEMENTS')  }
sub author            { (shift)->head1_text('AUTHOR')            }
sub subroutines       { (shift)->methods()                       }

sub methods
{
    my $self = shift;

    my %methods_pod;
    $self->_sections_for_node($self->pod_obj);
    my $parsed_pod_nodes = $self->{_parsed_pod_nodes};
    foreach my $package_function_name (@{ $self->{package_function_names} }) {
        if (exists $parsed_pod_nodes->{$package_function_name}) {
            $methods_pod{$package_function_name} = $parsed_pod_nodes->{$package_function_name};
        }
    }
    return %methods_pod;
}

sub _sections_for_node
{
    my ($self, $node) = @_;
    if ($node) {
        my @child_nodes = $node->content();
        if (scalar @child_nodes > 0) {
            foreach my $child_node (@child_nodes) {
                $self->_sections_for_node($child_node);
            }
        }

        my $title = $node->title();
        if ($title) {
            $title =~ s/^\s*//;         # strip any leading whitespace
            $title =~ s/^(\w+).*/$1/;   # strip anything after the first set of continuous word characters
        }
        my $text = $node->present();
        if ($text) {
            $text =~ s/\n\n+/\n\n/g;    # cut multiple newlines down to 1 each
            $text =~ s/^\s*=head.*\n//; # remove the head line itself, we don't want/need it
            $text =~ s/^\s*\n//;        # cut the first line if its empty
            $text =~ s/\n\s*\n$//;      # cut the last line if its empty
            $text =~ s/\n$//;           # remove the last newline at the end (if it has one)
        }
        if ( ($title && length($title) > 0) && ($text && length($text) > 0) ) {
            my $nodes_hash = $self->{_parsed_pod_nodes};
            $nodes_hash->{$title} = $text;
            $self->{_parsed_pod_nodes} = $nodes_hash;
        }
    }
}

1;

=head1 NAME

Perl::DocGenerator::PodReader - <One-line description of module's purpose>


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

=head2 filename

=head2 pod_obj

=head2 name

=head2 head1_text

=head2 version

=head2 synopsis

=head2 description

=head2 subroutines

=head2 methods

=head2 diagnostics

=head2 configuration

=head2 environment

=head2 dependencies

=head2 incompatibilities

=head2 bugs

=head2 limitations

=head2 support

=head2 todo

=head2 see_also

=head2 notes

=head2 exports

=head2 copyright

=head2 disclaimer

=head2 acknowledgements

=head2 author

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

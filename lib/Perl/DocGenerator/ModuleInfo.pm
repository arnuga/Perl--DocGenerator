package Perl::DocGenerator::ModuleInfo;

use 5.006;
use strict;
use warnings;

use Perl::DocGenerator::Item;
use Perl::DocGenerator::PodReader;
use Data::Dumper;

our $VERSION = '0.01';

sub new
{
    my ($class, $raw_module_info) = @_;
    my $module_name = $raw_module_info->{module_name};
    my $self = {
        module_name  => $module_name,
        filename     => $raw_module_info->{filename},
        arrays       => [ map { _item_class_wrap($module_name, $_, T_ARRAY)      } @{ $raw_module_info->{arrays}       } ],
        hashes       => [ map { _item_class_wrap($module_name, $_, T_HASH)       } @{ $raw_module_info->{hashes}       } ],
        io_handles   => [ map { _item_class_wrap($module_name, $_, T_IOHANDLE)   } @{ $raw_module_info->{io_handles}   } ],
        functions    => [ map { _item_class_wrap($module_name, $_, T_FUNCTION)   } @{ $raw_module_info->{functions}    } ],
        base_classes => [ map { _item_class_wrap($module_name, $_, T_BASE_CLASS) } @{ $raw_module_info->{base_classes} } ],
        # because of anonymous function refs clutering up the scalar symbols
        # we need scalars to be processed AFTER functions (and base_classes for that matter)
        scalars      => [ map { _item_class_wrap($module_name, $_, T_SCALAR)     } @{ $raw_module_info->{scalars}      } ],
    };
    bless $self, $class;

    return $self;
}

sub module_name  { return (shift)->{module_name}     }
sub filename     { return (shift)->{filename}        }
sub scalars      { return @{(shift)->{scalars}}      }
sub arrays       { return @{(shift)->{arrays}}       }
sub hashes       { return @{(shift)->{hashes}}       }
sub io_handles   { return @{(shift)->{io_handles}}   }
sub functions    { return @{(shift)->{functions}}    }
sub base_classes { return @{(shift)->{base_classes}} }

sub update_links_to_base_class_data
{
    my ($self, $base_class_obj) = @_;
    
    # for each of these items, grab all mine, grab all my parents and merge the 2 lists
    # then for each of those items flip the package name to my name (all parent items are inherited, thus are now mine)
    $self->{scalars}    = [ map { $_->package($self->module_name) && $_ } _unique($self->scalars,    $base_class_obj->scalars    ) ];
    $self->{arrays}     = [ map { $_->package($self->module_name) && $_ } _unique($self->arrays,     $base_class_obj->arrays     ) ];
    $self->{hashes}     = [ map { $_->package($self->module_name) && $_ } _unique($self->hashes,     $base_class_obj->hashes     ) ];
    $self->{io_handles} = [ map { $_->package($self->module_name) && $_ } _unique($self->io_handles, $base_class_obj->io_handles ) ];
    $self->{functions}  = [ map { $_->package($self->module_name) && $_ } _unique($self->functions,  $base_class_obj->functions  ) ];

    # remove anonymous function refs from the scalar list (and resort it)
    $self->{scalars} = [ sort { $a->name cmp $b->name } _unique_items_from_first_list($self->{scalars}, $self->{functions}) ];

    # update original_package_name for functions that exist in one or more of our base classes
    foreach my $base_function ($base_class_obj->functions) {
        foreach my $function ($self->functions) {
            if ($base_function->name eq $function->name) {
                $function->original_package($base_function->package);
                $function->is_overridden('Y');
            }
        }
    }
}

sub pod
{
    my ($self) = @_;
    if (! $self->{pod} && $self->{filename}) {
        my @functions = map { $_->name() } $self->functions();
        $self->{pod} = Perl::DocGenerator::PodReader->new($self->filename, @functions);
    }

    return $self->{pod};
}

sub private_functions
{
    my ($self) = @_;
    # private functions are those that start with an underscore '_'
    return grep { $_->name =~ /^_/ } $self->functions;
}

sub public_functions
{
    my ($self) = @_;
    # public functions are those that DO NOT start with an underscore '_'
    #warn Data::Dumper::Dumper($self->functions);
    return grep { $_->name =~ /^[^_]/ } $self->functions;
}

# private methods

sub _item_class_wrap
{
    my ($module_name, $raw_item, $item_type) = @_;
    # strip the package name portion off the item, we just want it's local name
    $raw_item =~ s/@{[ $module_name ]}::(.*)/$1/;

    if ($item_type == T_SCALAR) {

        # skip empty namespace imports (from this packages use statements)
        # side note: Isn't it bad behavior to define @EXPORT if you don't actually export anything?
        return if ($raw_item =~ /::$/);
    }

    my $is_operator_overload = undef;
    if ($item_type == T_FUNCTION) {
        if (_is_function_an_operator_overload($raw_item)) {
            $is_operator_overload = 'Y';

            # if this is an overridden operator then for some reason
            # I don't understand it's symbol table entry contains a prepended '('
            # in the case of an overridden () function then great, but for everything
            # else we really don't want it so we strip it
            if (($raw_item =~ /^\(/) && ($raw_item ne '()')) {
                $raw_item =~ s/^\(//;
            }
        }
    }

    my $item_obj = Perl::DocGenerator::Item->new();
    $item_obj->object_type($item_type);
    $item_obj->name($raw_item);
    $item_obj->package($module_name);
    $item_obj->original_package($module_name);
    $item_obj->full_name(join('::', $module_name, $raw_item));

    if ($item_type == T_FUNCTION) {
        $item_obj->anchor_href(uc($raw_item));
        $item_obj->is_operator_overload($is_operator_overload);
    }


    return $item_obj;
}

sub _unique
{
    # this is taken from the perl cookbook (1st ed.) page 102
    my @list = @_;
    no warnings 'uninitialized';
    my %seen;
    return grep { ! $seen{ $_->name }++ } @list;
}

sub _unique_items_from_first_list
{
    # this is taken from the perl cookbook (1st ed.) page 104
    my ($arrayA, $arrayB) = @_;
    my %seen;
    my @aonly = ();
    @seen{map { $_->name } @$arrayB} = ();

    map { push(@aonly, $_) unless exists $seen{$_->name} } @$arrayA;

    return @aonly;
}

sub _is_function_an_operator_overload
{
    my ($function_name) = @_;

    return 1 if ($function_name =~ /^\(/);

    return 1 if ($function_name eq '+');
    return 1 if ($function_name eq '-');
    return 1 if ($function_name eq '*');
    return 1 if ($function_name eq '/');
    return 1 if ($function_name eq '%');
    return 1 if ($function_name eq '**');
    return 1 if ($function_name eq '<<');
    return 1 if ($function_name eq '>>');
    return 1 if ($function_name eq 'x');
    return 1 if ($function_name eq '.');

    return 1 if ($function_name eq '+=');
    return 1 if ($function_name eq '-=');
    return 1 if ($function_name eq '*=');
    return 1 if ($function_name eq '/=');
    return 1 if ($function_name eq '%=');
    return 1 if ($function_name eq '**=');
    return 1 if ($function_name eq '<<=');
    return 1 if ($function_name eq '>>=');
    return 1 if ($function_name eq 'x=');
    return 1 if ($function_name eq '.=');

    return 1 if ($function_name eq '<');
    return 1 if ($function_name eq '<=');
    return 1 if ($function_name eq '>');
    return 1 if ($function_name eq '>=');
    return 1 if ($function_name eq '==');
    return 1 if ($function_name eq '!=');

    return 1 if ($function_name eq '<=>');
    return 1 if ($function_name eq 'cmp');

    return 1 if ($function_name eq 'lt');
    return 1 if ($function_name eq 'le');
    return 1 if ($function_name eq 'gt');
    return 1 if ($function_name eq 'ge');
    return 1 if ($function_name eq 'eq');
    return 1 if ($function_name eq 'ne');

    return 1 if ($function_name eq '&');
    return 1 if ($function_name eq '&=');
    return 1 if ($function_name eq '|');
    return 1 if ($function_name eq '|=');
    return 1 if ($function_name eq '^');
    return 1 if ($function_name eq '^=');

    return 1 if ($function_name eq 'neg');
    return 1 if ($function_name eq '!');
    return 1 if ($function_name eq '~');

    return 1 if ($function_name eq '++');
    return 1 if ($function_name eq '--');

    return 1 if ($function_name eq 'atan2');
    return 1 if ($function_name eq 'cos');
    return 1 if ($function_name eq 'sin');
    return 1 if ($function_name eq 'exp');
    return 1 if ($function_name eq 'abs');
    return 1 if ($function_name eq 'log');
    return 1 if ($function_name eq 'sqrt');
    return 1 if ($function_name eq 'int');

    return 1 if ($function_name eq 'bool');
    return 1 if ($function_name eq '""');
    return 1 if ($function_name eq '0+');
    return 1 if ($function_name eq 'qr');

    return 1 if ($function_name eq '<>');

    return 1 if ($function_name eq '${}');
    return 1 if ($function_name eq '@{}');
    return 1 if ($function_name eq '%{}');
    return 1 if ($function_name eq '&{}');
    return 1 if ($function_name eq '*{}');

    return 1 if ($function_name eq '~~');

    return 1 if ($function_name eq 'nomethod');
    return 1 if ($function_name eq 'fallback');
    return 1 if ($function_name eq '=');

    return undef;
}

1;

__END__

=head1 NAME

<Perl::DocGenerator::ModuleInfo> - <One-line description of module's purpose>


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

=head2 module_name

=head2 filename

=head2 scalars

=head2 arrays

=head2 hashes

=head2 io_handles

=head2 functions

=head2 base_classes

=head2 update_links_to_base_class_data

=head2 pod

=head2 private_functions

=head2 public_functions

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

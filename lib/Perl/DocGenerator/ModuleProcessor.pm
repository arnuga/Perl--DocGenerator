package Perl::DocGenerator::ModuleProcessor;

use 5.006;
use strict;
use warnings;

require Devel::Symdump;

use Module::Load;
use Perl::DocGenerator::Item;
use Perl::DocGenerator::PodReader;
use JSON;
use Data::Dumper;

our $VERSION = '0.01';

my %modules_loaded;

sub new
{
    my ($class, $package) = @_;
    my $self = {
        original_filename => undef,
        module_info       => undef,
        package_functions => undef,
        package_name      => undef,
        pod               => undef,
    };
    bless $self, $class;

    {
        BEGIN { $^W = 0 }   # it's not my code, you make it compile clean
        no warnings 'all';  # no seriously, I said shutup!
        if (my $child_pid = open(CHILD, "-|")) {
            # in the parent
            waitpid($child_pid, 0);
            my ($raw_result) = (<CHILD>);
            close(CHILD);
            $self->_parent_reader($raw_result);
        } else {
            die "Cannot fork: $!" unless defined $child_pid;
            # in the child
            _child_extractor($package);
        }
    }

    # init all items objects
    $self->scalars();
    $self->arrays();
    $self->hashes();
    $self->ios();
    $self->functions();

    return $self;
}

sub package_name
{
    my ($self, $package_name) = @_;
    if ($package_name) {
        $self->{package_name} = $package_name;
    }
    return $self->{package_name};
}

sub base_classes
{
    my ($self) = @_;
    my @return_base_classes = ();
    foreach my $base_item (sort @{$self->obj->{base_classes}}) {
        my $item_obj = Perl::DocGenerator::Item->new();
        $item_obj->object_type(T_BASE_CLASS);
        $item_obj->name($base_item);
        $item_obj->package($base_item);
        $item_obj->original_package($base_item);
        $item_obj->full_name($base_item);
        push(@return_base_classes, $item_obj);
    }
    return @return_base_classes;
}

sub packages
{
    my ($self) = @_;
    return keys %modules_loaded;
}

sub scalars
{
    my ($self) = @_;
    my @functions = $self->functions();
    # grab all the scalars that are direct members of my namespace
    my @scalars;
    foreach my $scalar_name (sort @{$self->obj->{scalars}}) {
        $scalar_name =~ s/@{[ $self->package_name() ]}::(.*)/$1/;
        push @scalars, $scalar_name;
    }

    my %seen;
    my @scalaronly;
    @seen{ map { $_->name } @functions } = ();

    foreach my $item (@scalars) {
        # skip anonymous functions refs maybe in the future we'll do something with these in the functions sections
        next if (exists $seen{$item} || $item =~ /__ANON__/);
        next if ($item =~ /::$/); # skip namespace entries, we don't care about them
        my $item_obj = Perl::DocGenerator::Item->new();
        $item_obj->object_type(T_SCALAR);
        $item_obj->name($item);
        $item_obj->package($self->package_name());
        $item_obj->original_package($self->package_name());
        $item_obj->full_name(join('::', $self->package_name(), $item));
        push(@scalaronly, $item_obj);
    }

    foreach my $base_class ($self->base_classes) {
        my $module_obj = $self->_module_for_package($base_class->name);
        if ($module_obj) {
            my @base_items = $module_obj->scalars();
            @base_items = $self->_unique_items_from_first_list(\@base_items, \@scalaronly);
            push(@scalaronly, @base_items);
        }
    }

    return @scalaronly;
}

sub functions
{
    my ($self) = @_;
    if (! $self->{package_functions}) {
        my @return_functions = ();
        # grab all the functions that are direct members of my namespace
        my @functions;
        foreach my $function_name (@{$self->obj->{functions}}) {
            $function_name =~ s/@{[ $self->package_name() ]}::(.*)/$1/;
            push @functions, $function_name;
        }

        foreach my $function (@functions) {
            my $is_operator_overload = undef;
            if (_is_function_an_operator_overload($function)) {
                if ($function =~ /^\(/ && $function ne '()') {
                    $function =~ s/^\(//; # strip the '(' off the front if it has one but is not the () function
                }
                $is_operator_overload = 'Y';
            }
            my $item_obj = Perl::DocGenerator::Item->new();
            $item_obj->object_type(T_FUNCTION);
            $item_obj->name($function);
            $item_obj->package($self->package_name());
            $item_obj->original_package($self->package_name());
            $item_obj->full_name(join('::', $self->package_name(), $function));
            $item_obj->anchor_href(uc($function));
            $item_obj->is_operator_overload($is_operator_overload);
            push(@return_functions, $item_obj);
        }

        # see which functions are defined in one or more of our base classes
        # Need to investigate if we are falsely reporting a method as overridden when in fact
        # its just beem hooked into our namespace via export, export_ok or even a direct ->import() call
        foreach my $base_class ($self->base_classes) {
            my $module_obj = $self->_module_for_package($base_class->name);
            if ($module_obj) {
                my @base_functions = $module_obj->functions();
			    foreach my $base_function (@base_functions) {
			    	foreach my $function (@return_functions) {
			    		if ($base_function->name() eq $function->name()) {
			    			$function->original_package($base_function->package());
			    			$function->is_overridden('Y');
			    		}
			    	}
			    }
                @base_functions = $self->_unique_items_from_first_list(\@base_functions, \@return_functions);
                push(@return_functions, @base_functions);
            }
        }

        $self->{package_functions} = [@return_functions];
    }

    return @{$self->{package_functions}};
}

sub obj
{
    my ($self, $obj) = @_;
    if ($obj) {
        $self->{module_info} = $obj;
    }
    return $self->{module_info};
}

sub pod
{
    my ($self) = @_;
    if (! $self->{pod} && $self->{original_filename}) {
        my @functions = map { $_->name() } $self->functions();
        $self->{pod} = Perl::DocGenerator::PodReader->new($self->original_filename, @functions);
    }

    return $self->{pod};
}

sub private_functions
{
    my ($self) = @_;
    # private functions are those that start with an underscore '_'
    my @private_funcs = grep { $_->name =~ /^_/ } $self->functions;

    return @private_funcs;
}

sub public_functions
{
    my ($self) = @_;
    # public functions are those that DO NOT start with an underscore '_'
    my @public_funcs = grep { $_->name =~ /^[^_]/ } $self->functions;

    return @public_funcs;
}

sub arrays
{
    my ($self) = @_;
    my @return_arrays = $self->_arrays;

    foreach my $base_class ($self->base_classes) {
        my $module_obj = $self->_module_for_package($base_class->name);
        if ($module_obj) {
            my @base_items = $module_obj->arrays();
            @base_items = $self->_unique_items_from_first_list(\@base_items, [ $self->_arrays ]);
            push(@return_arrays, @base_items);
        }
    }

    return @return_arrays;
}

sub _arrays
{
    my ($self) = @_;
    my @return_arrays;

    my @arrays;
    foreach my $array_name (sort @{$self->obj->{arrays}}) {
        $array_name =~ s/@{[ $self->package_name() ]}::(.*)/$1/;
        push @arrays, $array_name;
    }

    foreach my $array (@arrays) {
        my $item_obj = Perl::DocGenerator::Item->new();
        $item_obj->object_type(T_ARRAY);
        $item_obj->name($array);
        $item_obj->package($self->package_name());
        $item_obj->original_package($self->package_name());
        $item_obj->full_name(join('::', $self->package_name(), $array));
        push(@return_arrays, $item_obj);
    }

    return @return_arrays;
}

sub hashes
{
    my ($self) = @_;
    my @return_hashes;

    my @hashes;
    foreach my $hash_name (sort @{$self->obj->{hashes}}) {
        $hash_name =~ s/@{[ $self->package_name() ]}::(.*)/$1/;
        push @hashes, $hash_name;
    }

    foreach my $hash (@hashes) {
        my $item_obj = Perl::DocGenerator::Item->new();
        $item_obj->object_type(T_HASH);
        $item_obj->name($hash);
        $item_obj->package($self->package_name());
        $item_obj->original_package($self->package_name());
        $item_obj->full_name(join('::', $self->package_name(), $hash));
        push(@return_hashes, $item_obj);
    }

        foreach my $base_class ($self->base_classes) {
            my $module_obj = $self->_module_for_package($base_class->name);
            if ($module_obj) {
                my @base_items = $module_obj->hashes();
                @base_items = $self->_unique_items_from_first_list(\@base_items, \@return_hashes);
                push(@return_hashes, @base_items);
            }
    }

    return @return_hashes;
}

sub ios
{
    my ($self) = @_;
    my @return_ios;

    my @ios;
    foreach my $io_name (sort @{$self->obj->{ios}}) {
        $io_name =~ s/@{[ $self->package_name() ]}::(.*)/$1/;
        push @ios, $io_name;
    }

    foreach my $ios (@ios) {
        my $item_obj = Perl::DocGenerator::Item->new();
        $item_obj->object_type(T_IOS);
        $item_obj->name($ios);
        $item_obj->package($self->package_name());
        $item_obj->original_package($self->package_name());
        $item_obj->full_name(join('::', $self->package_name(), $ios));
        push(@return_ios, $item_obj);
    }

        foreach my $base_class ($self->base_classes) {
            my $module_obj = $self->_module_for_package($base_class->name);
            if ($module_obj) {
                my @base_items = $module_obj->ios();
                @base_items = $self->_unique_items_from_first_list(\@base_items, \@return_ios);
                push(@return_ios, @base_items);
            }
    }

    return @return_ios;
}

sub _module_for_package
{
    my ($self, $package) = @_;
    return exists $modules_loaded{$package} ? $modules_loaded{$package} : undef;
}

sub _unique_items_from_first_list
{
    # this is taken from the perl cookbook (1st ed.) page 104
    my ($self, $arrayA, $arrayB) = @_;
    my %seen;
    my @aonly = ();
    @seen{map { $_->name } @$arrayB} = ();

    map { push(@aonly, $_) unless exists $seen{$_->name} } @$arrayA;

    return @aonly;
}

sub _module_name_from_filename
{
    my ($filename) = @_;
    if (-f $filename) {
        my ($module_name) = grep { /$filename/ } values %INC;
        if ($module_name) {
            $module_name =~ s/\//::/g;
            $module_name =~ s/\.pm//g;
            return $module_name;
        }
    }
    return undef;
}

sub original_filename
{
    my ($self, $original_filename) = @_;
    if ($original_filename) {
        $self->{original_filename} = $original_filename;
    }
    return $self->{original_filename};
}

sub _original_filename_from_inc
{
    my ($package_name) = @_;

    $package_name =~ s/\:\:/\//g; # find any set of :: and convert to '/'

    if ($package_name !~ /\.pm/) {
        $package_name .= '.pm';
    }

    return exists $INC{$package_name}
        ? $INC{$package_name}
        : undef;
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

sub _child_extractor
{
    my ($package) = @_;

    my ($filename, $module_name, $devel_symbol);
    #use the package name as a hash key to untaint it
    my %worthless_hash;
    $worthless_hash{$package} = 1;
    ($package) = keys %worthless_hash;
    load($package);
    
    if (my $err = $@) {
        warn "Unable to load package '$package': $err";
        exit;
    }
    
    $filename = _original_filename_from_inc($package);
    
    if ($package =~ /\.pm$/) { # does it have a .pm at the end? (is it a filename?)
        my $likely_module_name = _module_name_from_filename($package);
        if ($likely_module_name) {
            $module_name = $likely_module_name;
        } else {
            die "Unable to determine module name from file: $package.  Maybe $package is not a real package or is a mixin style module?";
        }
    } else {
        $module_name = $package;
    }
    
    eval { $devel_symbol = Devel::Symdump->new($module_name); };

    if (my $eval_err = $@) {
        print "Unable to load package $module_name with Devel::Symdump!: $eval_err";
        exit; 
    }


    no strict 'refs';
    my $module_info = {
        scalars      => [ $devel_symbol->scalars()                               ],
        arrays       => [ $devel_symbol->arrays()                                ],
        hashes       => [ $devel_symbol->hashes()                                ],
        ios          => [ $devel_symbol->ios()                                   ],
        functions    => [ $devel_symbol->functions()                             ],
        base_classes => [ grep { ! /$module_name/ } @ { $module_name . '::ISA' } ],
#        inc_libs     => [ %INC                                                   ],
    };

    print STDOUT join('|', $filename, $module_name, encode_json($module_info));
    exit;
}

sub _parent_reader
{
    my ($self, $raw_result) = @_;
    my ($filename, $module_name, $json_response) = split(/\|/, $raw_result);
    $self->{original_filename} = $filename;
    $self->{package_name} = $module_name;
    my $module_info = decode_json($json_response);
    $self->obj($module_info);

    # put this on the master stack
    $modules_loaded{$module_name} = $self;

    # load all base classes since we'll need them later for inheritance details
    foreach my $base_class (@{$module_info->{base_classes}}) {
        ref($self)->new($base_class);
    }
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

=head2 obj

=head2 pod

=head2 package_name

=head2 base_classes

=head2 packages

=head2 scalars

=head2 functions

=head2 private_functions

=head2 public_functions

=head2 arrays

=head2 hashes

=head2 ios

=head2 set

=head2 original_filename

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

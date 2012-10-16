use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl::DocGenerator',
    license             => 'perl',
    dist_author         => q{David Shultz <djshultz@gmail.com>},
    dist_version_from   => 'lib/Perl/DocGenerator.pm',
    dist_abstract       => 'lib/Perl/DocGenerator.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'               => 5.006,
        'aliased'            => 0,
        'Devel::Symdump'     => 0,
        'enum'               => 0,
        'File::Find'         => 0,
        'File::Spec'         => 0,
        'HTML::Template'     => 0,
        'Module::Info'       => 0,
        'Module::Load'       => 0,
    },
    add_to_cleanup     => [ 'Perl-DocGenerator-*' ],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('tmpl');
$builder->create_build_script();

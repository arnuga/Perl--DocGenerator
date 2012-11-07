#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 4;
use Perl::DocGenerator;
use Data::Dumper;

my $module1 = Perl::DocGenerator::ModuleProcessor->new('Sub::File');
cmp_ok($module1->{module_info}{module_name}, 'eq', 'Sub::File');
like($module1->{module_info}{filename}, qr/Sub\/File\.pm$/);

my $module2 = Perl::DocGenerator::ModuleProcessor->new('Sub/File.pm');

warn "What I Got: " . Data::Dumper::Dumper($module2->{module_info});
cmp_ok($module2->{module_info}->{module_name}, 'eq', 'Sub::File');
like($module2->{module_info}->{filename}, qr/Sub\/File\.pm$/);

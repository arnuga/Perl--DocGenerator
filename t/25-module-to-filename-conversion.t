#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 4;
use Perl::DocGenerator;
use Data::Dumper;

{
my $processor = Perl::DocGenerator::ModuleProcessor->new('Sub::File');
my ($module) = $processor->modules;
cmp_ok($module->module_name, 'eq', 'Sub::File');
like($module->filename, qr/Sub\/File\.pm$/);
}

{
my $processor = Perl::DocGenerator::ModuleProcessor->new('Sub/File.pm');
my ($module) = $processor->modules;

cmp_ok($module->module_name, 'eq', 'Sub::File');
like($module->filename, qr/Sub\/File\.pm$/);
}

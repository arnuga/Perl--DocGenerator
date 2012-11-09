#!/usr/local/bin/perl -w

use Perl::DocGenerator;

no warnings "all";

my $builder = Perl::DocGenerator->new();
$builder->folders(($ARGV[0]));
$builder->scan_packages();
$builder->output(Perl::DocGenerator::Writer::HTML);

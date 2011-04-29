#!perl -T

use Test::More tests => 3;

use_ok( 'Perl::DocGenerator' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Item' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::ModuleProcessor' ) || print "Bail out!\n";

diag( "Testing Perl::DocGenerator $Perl::DocGenerator::VERSION, Perl $], $^X" );

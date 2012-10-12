#!perl -T

use Test::More tests => 9;

use_ok( 'Perl::DocGenerator' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Item' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::ModuleProcessor' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Writer' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Writer::XML' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Writer::HTML' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Writer::Screen' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Writer::Pod' ) || print "Bail out!\n";
use_ok( 'Perl::DocGenerator::Writer::PDF' ) || print "Bail out!\n";

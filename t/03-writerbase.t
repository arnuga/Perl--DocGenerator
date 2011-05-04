#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 6;
use Perl::DocGenerator::WriterBase;
use Perl::DocGenerator::Writer::XML;
use Perl::DocGenerator::Writer::HTML;
use Perl::DocGenerator::Writer::Screen;
use Perl::DocGenerator::Writer::Pod;
use Perl::DocGenerator::Writer::PDF;

{
    my $writer = Perl::DocGenerator::WriterBase->new();
    ok($writer);

    $writer->writer('Perl::DocGenerator::Writer::XML'); 
    ok($writer->_load_and_verify_writer());

    $writer->writer('Perl::DocGenerator::Writer::HTML'); 
    ok($writer->_load_and_verify_writer());

    $writer->writer('Perl::DocGenerator::Writer::Screen'); 
    ok($writer->_load_and_verify_writer());

    $writer->writer('Perl::DocGenerator::Writer::Pod'); 
    ok($writer->_load_and_verify_writer());

    $writer->writer('Perl::DocGenerator::Writer::PDF'); 
    ok($writer->_load_and_verify_writer());
}

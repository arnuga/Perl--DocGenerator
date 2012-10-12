#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 6;
use Perl::DocGenerator::Writer;
use Perl::DocGenerator::Writer::XML;
use Perl::DocGenerator::Writer::HTML;
use Perl::DocGenerator::Writer::Screen;
use Perl::DocGenerator::Writer::Pod;
use Perl::DocGenerator::Writer::PDF;

{
    my $writer = Perl::DocGenerator::Writer->new();
    ok($writer);
    $writer->writer_class('Perl::DocGenerator::Writer::XML'); 
    ok($writer->initialize_writer());

    $writer->writer_class('Perl::DocGenerator::Writer::Screen'); 
    ok($writer->initialize_writer());

    $writer->writer_class('Perl::DocGenerator::Writer::Pod'); 
    ok($writer->initialize_writer());

    $writer->writer_class('Perl::DocGenerator::Writer::PDF'); 
    ok($writer->initialize_writer());

    $writer->writer_class('Perl::DocGenerator::Writer::HTML'); 
    ok($writer->initialize_writer());
}

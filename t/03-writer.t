#!perl -T

use strict;
use lib 't/lib';
use Test::More tests => 13;

BEGIN {
    use_ok('Perl::DocGenerator::Writer');
    use_ok('Perl::DocGenerator::Writer::XML');
    use_ok('Perl::DocGenerator::Writer::HTML');
    use_ok('Perl::DocGenerator::Writer::Screen');
    use_ok('Perl::DocGenerator::Writer::Pod');
    use_ok('Perl::DocGenerator::Writer::PDF');
};

{
    my $writer = new_ok('Perl::DocGenerator::Writer');
    isa_ok($writer, 'Perl::DocGenerator::Writer');
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

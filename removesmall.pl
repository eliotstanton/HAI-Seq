#!/usr/bin/perl

use strict;
use warnings;

my $var_minlen = shift or die "Error: `var_minlen` parameter not provided\n";

{
    local $/=">";

    while(<>) {

        chomp;

        next unless /\w/;

        s/>$//gs;

        my @chunk = split /\n/;

        my $header = shift @chunk;

        my $seqlen = length join "", @chunk;

        print ">$_" if($seqlen >= $var_minlen);

    }

    local $/="\n";

}

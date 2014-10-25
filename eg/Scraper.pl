
=pod

=head1 NAME

Scraper.pl - Scrape data from a search engine.


=head1 SYNOPSIS

    perl Scraper.pl

=head1 DESCRIPTION

=head1 AUTHOR

C<Scraper.pl> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use WWW::Search::Scraper;
use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

    select STDERR; $| = 1; select STDOUT; $| = 1; 

    my ($engine, $query, $debug);
    $engine = 'eBay'      unless $engine = $ARGV[0];
    $query  = 'turntable' unless $query  = $ARGV[1];
    $debug = $ARGV[2];

    my $scraper = new WWW::Search::Scraper( $engine );
    
    my %resultTitles;
    $scraper->setup_query($query, {'search_debug'=>$debug} );
    my $resultCount = 0;
    while ( my $result = $scraper->next_response() ) {
        $resultCount += 1;
        %resultTitles = %{$result->resultTitles()} unless %resultTitles;
        my %results = %{$result->results()};
        for ( keys %resultTitles ) {
            print "$resultTitles{$_}: '$results{$_}'\n" if $results{$_};
        }
        print "\n";
    }

    print "\n$resultCount results found.\n";


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

use strict;
use lib './lib';
use WWW::Search::Scraper(qw(1.48));
use WWW::Search::Scraper::Request::Job;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

    select STDERR; $| = 1; select STDOUT; $| = 1; 

    my ($engine, $query, $debug);
    $engine = 'eBay'      unless $engine = $ARGV[0];
    $query  = 'turntable' unless $query  = $ARGV[1];
    $debug = $ARGV[2];

    my $scraper = new WWW::Search::Scraper( $engine );

    $scraper->techiesLocation('bayarea') if $engine eq 'techies'; # www.techies.com is special.
    $scraper->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src') if $engine eq 'Sherlock'; # Sherlock is extra special.

    my $request = new WWW::Search::Scraper::Request::Job($query);
    $request->Scraper_debug($debug);
    
    $request->skills($query);
#    $scraper->native_query($query); # This let's us test pre-v2.00 modules from here, too.

#    $request->locations([ 'CA-San Jose'
#                         ,'CA-Mountain View'
#                         ,'CA-Sunnyvale'
#                         ,'CA-Cupertino'
##                         ,'CA-Costa Mesa'
#                         ]);

    my %resultTitles;
    $scraper->request($request);

    my $resultCount = 0;
    my $limit = 100;
    while ( my $result = $scraper->next_response() ) {
        # $result->{'_scraperSkipDetailPage'} = 1;
        $resultCount += 1;
        %resultTitles = %{$result->resultTitles()};# unless %resultTitles;
        my %results = %{$result->results()};
        for ( keys %resultTitles ) {
            if ( 'ARRAY' eq ref($results{$_}) ) {
                print "$resultTitles{$_}: (";
                my $comma = '';
                my $ary = $results{$_};
                for ( @$ary ) {
                    print "$comma'$results{$_}'";# if $results{$_};
                    $comma = ', ';
                }
                print ")\n";
            } else {
                print "$resultTitles{$_}: '$results{$_}'\n";# if $results{$_};
            }
        }
        print "\n";
        last unless --$limit;
    }

    print "\n$resultCount results found.\n";

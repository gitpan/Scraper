
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
use WWW::Search::Scraper;
use WWW::Search::Scraper::Request::Job;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

    select STDERR; $| = 1; select STDOUT; $| = 1; 

    my ($engine, $query, $debug);
    $engine = 'eBay'      unless $engine = $ARGV[0];
    $query  = 'turntable' unless $query  = $ARGV[1];
    $debug = $ARGV[2];

    my $scraper = new WWW::Search::Scraper( $engine );

    my $request = new WWW::Search::Scraper::Request::Job($query); #, {'whichTech'=>'Perl'});
    $request->debug($debug);
    
#    $request->skills($query);
#    $scraper->native_query($query); # This let's us test pre-v2.00 modules from here, too.

    $request->locations([ 'CA-San Jose'
                         ,'CA-Mountain View'
                         ,'CA-Sunnyvale'
                         ,'CA-Cupertino'
#                         ,'CA-Costa Mesa'
                         ]);

    my %resultTitles;
    $scraper->request($request);

    my $resultCount = 0;
    my $limit = 100;
    while ( my $result = $scraper->next_response() ) {
        $resultCount += 1;
        %resultTitles = %{$result->resultTitles()};# unless %resultTitles;
        my %results = %{$result->results()};
        for ( keys %resultTitles ) {
            print "$resultTitles{$_}: '$results{$_}'\n";# if $results{$_};
        }
        print "\n";
        last unless --$limit;
    }

    print "\n$resultCount results found.\n";

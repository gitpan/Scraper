
use WWW::Search::Scraper;

    my $scraper = new WWW::Search::Scraper( 'eBay', {'search_debug' => 0} );
    
    my %resultTitles;
    $scraper->native_query('turntable', {'search_debug'=>0});
    my $resultCount = 0;
    while ( my $result = $scraper->next_result() ) {
        $resultCount += 1;
        %resultTitles = %{$result->resultTitles()} unless %resultTitles;
        my %results = %{$result->results()};
        for ( keys %resultTitles ) {
            print "$resultTitles{$_}: '$results{$_}'\n";
        }
        print "\n";
    }

    print "\n$resultCount results found.\n";

use WWW::Search::Scraper;


    my $scraper = new WWW::Search::Scraper( 'eBay', {'search_debug' => 0} );
    
    $scraper->native_query('turntable', {'search_debug'=>0});
    while ( my $result = $scraper->next_result() ) {
        print "ITEM#: '".$result->_elem('itemNumber')."'\n";
        print "TITLE: '".$result->title()."'\n";
#        print "DESCRIPTION: '".$result->description()."'\n";
        print "BIDS: '".$result->_elem('bids')."'\n";
        print "PRICE: '".$result->_elem('price')."'\n";
        print "URL: '".$result->url()."'\n";
        print "\n";
    }


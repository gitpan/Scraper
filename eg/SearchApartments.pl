
use WWW::Search::Scraper;


    my $scraper = new WWW::Search::Scraper( 'apartments', {'search_debug' => 0} );
    
    $scraper->native_query('New York', 
        {  'search_debug'=>0
          ,'state' => 'NY'
          ,'numbeds' => '0'   # (0-doesn't matter, 6-studio, 1-1 bed, 2-2 beds, 3-3+ bedrooms)
          ,'minrnt' => '0'
          ,'maxrnt' => '9999'
        });
    while ( my $result = $scraper->next_result() ) {
        print "ITEM#: '".$result->_elem('itemNumber')."'\n";
        print "TITLE: '".$result->title()."'\n";
        print "BIDS: '".$result->_elem('bids')."'\n";
        print "PRICE: '".$result->_elem('price')."'\n";
        print "URL: '".$result->url()."'\n";
        print "\n";
    }

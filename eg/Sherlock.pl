use WWW::Search ( qw(generic_option) ) ;

    $| = 1; # Hot-pipe!
    my $stdout = select STDERR;
    $| = 1; # Hot-pipe error messages, too!
    select $stdout;
    
    my $scraper = new WWW::Search('Sherlock');
    $scraper->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src'); # or 'file:Sherlock/yahoo.src';
    
    $scraper->native_query('Greeting Cards', {'search_debug' => 1});
    
    while ( my $result = $scraper->next_result() ) {
        print "NAME: '".$result->name()."'\n";
        print "URL: '".$result->url()."'\n";
        print "RELEVANCE: '".$result->relevance()."'\n";
        print "PRICE: '".$result->price()."'\n";
        print "AVAIL: '".$result->avail()."'\n";
        print "EMAIL: '".$result->email()."'\n";
        print "DETAIL: '".$result->detail()."'\n";
    }



=pod

=head1 NAME

SearchApartments.pl - Search for apartments.

=head1 SYNOPSIS

    perl SearchApartments.pl

Rips those annoying CRs out of all files in this folder, and all
its subfolders, that are associated with Perl. This means *.pl, *.pm,
MANIFEST and README. Others can easily be added to this list if desired.

=head1 DESCRIPTION

=head1 AUTHOR

C<SearchApartments.pl> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use WWW::Search::Scraper(qw(1.48));
use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


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

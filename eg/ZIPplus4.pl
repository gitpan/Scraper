
=pod

=head1 NAME

ZIPplus4.pl - Scrape data from a search engine.


=head1 SYNOPSIS

    perl ZIPplus4.pl 

=head1 DESCRIPTION

=head1 AUTHOR

C<ZIPplus4.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

    use WWW::Search::Scraper(qw(1.48));
    use WWW::Search::Scraper::Request::ZIPplus4;

    my $ZIPplus4 = new WWW::Search::Scraper( 'ZIPplus4' );

    my $request = new WWW::Search::Scraper::Request::ZIPplus4;
    
    # Note: DeliveryAddress(), and either ZipCode(), or City() and State(), are required.
    $request->DeliveryAddress('1600 Pennsylvannia Ave');
    $request->City('Washington');
    $request->State('DC');
    $request->ZipCode('20500');

    $ZIPplus4->request($request);
    my $response = $ZIPplus4->next_response();
    
    while ( my $response = $ZIPplus4->next_response() ) {
        for ( qw(address city state zip county carrierRoute checkDigit deliveryPoint) ) {
            print "$_: ".${$response->$_()}."\n";
        }
    }


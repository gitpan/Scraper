
package WWW::Search::Scraper::ZIPplus4;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(2.12 generic_option addURL trimTags));

use strict;

my $scraperQuery = 
        { 
            'type' => 'POST'
#            ,'formNameOrNumber' => undef
#            ,'submitButton' => 'Submit'
            
            # This is the basic URL on which to get the form to build the query.
#            ,'url' => 'http://www.usps.com/ncsc/lookups/lookup_zip+4.html'
            ,'url' => 'http://www.usps.com/cgi-bin/zip4/zip4inq2?'
           # specify defaults, by native field names
#           ,'nativeQuery' => 'Delivery+Address'
           ,'nativeDefaults' => { 
                                    'submit.x' => 1, 'submit.y' => 1 # the Process button.
                                   ,'Urbanization' => ''
                                }
            
            # specify translations from canonical fields to native fields
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {     
                                 'Firm' => 'Firm'
                                ,'Urbanization' => 'Urbanization'
                                ,'DeliveryAddress' => 'Delivery Address'
                                ,'City' => 'city'
                                ,'State' => 'state'
                                ,'ZipCode' => 'Zip Code'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
       };

my $scraperFrame =
       [ 'HTML', 
          [ 
             [ 'BODY', 'The standardized address is:', '<CENTER',
               [ 
                  [ 'HIT*' ,
                     [  
                          [ 'REGEX', '<b>(.*?<BR>.*?)<BR>\s*(.*?)\s(..)\s(\d\d\d\d\d-\d\d\d\d)<BR>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>',
                             'address', 'city', 'state', 'zip', 'carrierRoute', 'county', 'deliveryPoint' , 'checkDigit' ]
                         ,[ 'REGEX', '<b>(.*?)</b>.*?<b>(.*?)\s(..)\s(\d\d\d\d\d-\d\d\d\d)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>',
                             'address', 'city', 'state', 'zip', 'carrierRoute', 'county', 'deliveryPoint' , 'checkDigit' ]
                     ]
                  ]
               ]
             ]
           ]
       ];


sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => 'ZIPplus4 test parameters have not yet been fixed' 
                ,'TODO' => 'Uses POST: certain versions of WWW::Search (2.25 to name one) fail with POSTs.'
                ,'testNativeQuery' => '94043'
                ,'testNativeOptions' => {
                                             'Delivery Address' => '1600 Pennsylvannia Ave'
                                            ,'city' => 'Washington'
                                            ,'state' => 'DC'
                                            ,'Zip Code' => '20500'
                                        }
                ,'expectedOnePage' => 1
                ,'expectedMultiPage' => 1
                ,'expectedBogusPage' => 1
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Search::Scraper::ZIPplus4 - Get ZIP+4 code, given street address, from www.usps.com


=head1 SYNOPSIS

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
    while ( my $response = $ZIPplus4->next_response() )
    {    
        for ( qw(address city state zip county carrierRoute checkDigit deliveryPoint) ) {
            print "$_: ".${$response->$_()}."\n";
        }
    }

=head1 DESCRIPTION

This class is an ZIPplus4 specialization of WWW::Search.
It handles making and interpreting ZIPplus4 searches
F<http://www.ZIPplus4.com>.

=head1 AUTHOR and CURRENT VERSION


C<WWW::Search::Scraper::ZIPplus4> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



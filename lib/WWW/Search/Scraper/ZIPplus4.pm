
package WWW::Search::Scraper::ZIPplus4;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(2.12 generic_option addURL trimTags));

use strict;

my $scraperRequest = 
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
                                    'Firm' => ''
                                   ,'Urbanization' => ''
                                }
            
            # specify translations from canonical fields to native fields
           ,'defaultRequestClass' => 'ZIPplus4'
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {     
                                 'Firm' => 'Firm'
                                ,'Urbanization' => 'Urbanization'
                                ,'Delivery_Address' => 'Delivery Address'
                                ,'City' => 'city'
                                ,'State' => 'state'
                                ,'Zip_Code' => 'Zip Code'
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
                          [ 'REGEX', '<b>(.*?(<BR>)?.*?)<BR>\s*(.*?)\s(..)\s(\d\d\d\d\d-\d\d\d\d)<BR>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>'
                            ,'address', undef, 'city', 'state', 'zip', 'carrierRoute', 'county', 'deliveryPoint' , 'checkDigit' ]
                     ]
                  ]
                 ,[ 'HIT*' ,
                     [  
                          [ 'REGEX', '<b>(.*?)</b>.*?<b>(.*?)\s(..)\s(\d\d\d\d\d-\d\d\d\d)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>'
                            ,'address', 'city', 'state', 'zip', 'carrierRoute', 'county', 'deliveryPoint' , 'checkDigit' ]
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
                 'SKIP' => ''#'ZIPplus4 test parameters have not yet been fixed' 
                ,'testNativeQuery' => '94043'
                ,'testNativeOptions' => {
                                             'Delivery_Address' => '1600 Pennsylvannia Ave'
                                            ,'City' => 'Washington'
                                            ,'State' => 'DC'
                                            ,'Zip_Code' => '20500'
                                        }
                ,'expectedOnePage' => 8
                ,'expectedMultiPage' => 8
                ,'expectedBogusPage' => 1
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

{ package AddressDedup;
# This package helps ZipPlus4.pl to de-duplicate the address list.
# With minor or no modification, it might be useful to others, too.
use Class::Struct;
    struct ( 'AddressDedup' =>
              [
                  'Address'     => '$'
                 ,'City'        => '$'
                 ,'State'       => '$'
                 ,'Zip'         => '$'
                 ,'Name'        => '$'
                 ,'_allColumns' => '$'
                 ,'_zipColumn'  => '$'
              ]
           );

sub isEqual {
    my ($self, $other) = @_;

    return 0 unless ($self->_isEqualAddress($other->Address));
    return 0 unless ($self->_isEqualCity($other->City));
    return 0 unless ($self->_isEqualState($other->State));
    return 0 unless ($self->_isEqualZip($other->Zip));
#    return 0 unless ($self->_isEqualName($other->Name));
    
    return 1;
}
sub _isEqualAddress {
    my ($self, $str) = @_;
    return ($self->Address eq $str);
}
sub _isEqualCity {
    my ($self, $str) = @_;
    return ($self->City eq $str);
}
sub _isEqualState {
    my ($self, $str) = @_;
    return ($self->State eq $str);
}
sub _isEqualZip {
    my ($self, $str) = @_;
    return ($self->Zip eq $str);
}
sub _isEqualName {
    my ($self, $str) = @_;
    return ($self->Name eq $str);
}


sub setValue {
    my ($self, $colNums, $fullLine) = @_;
    
    chomp $fullLine;
    my @cols = split ',', $fullLine;
    $self->_allColumns(\@cols);

    $self->Address($cols[$colNums->{'colAddress'}]);
    $self->City($cols[$colNums->{'colCity'}]);
    $self->State($cols[$colNums->{'colState'}]);
    $self->Zip($cols[$colNums->{'colZip'}]);

    $self->_zipColumn($colNums->{'colZip'});
}

sub isEmpty {
    my ($self) = @_;
    return 0 if $self->Address;
    return 0 if $self->City;
    return 0 if $self->State;
    return 0 if $self->Zip;
    return 0 if $self->Name;
    return 1;
}

sub asString {
    my ($self) = @_;
    
    my $allColumns = $self->_allColumns();

    $$allColumns[$self->_zipColumn] = $self->Zip;
    
    return join ',', @$allColumns;
}
}
1;

__END__
=pod

=head1 NAME

WWW::Search::Scraper::ZIPplus4 - Get ZIP+4 code, given street address, from www.usps.com. 
Also helps de-duplicate a mailing list (see eg/ZipPlus4.pl)


=head1 SYNOPSIS

=over 1

=item Simple

 use WWW::Search::Scraper(qw(1.48));
 use WWW::Search::Scraper::Request::ZIPplus4;

 my $ZIPplus4 = new WWW::Search::Scraper(
         'ZIPplus4',
        ,{   'Delivery_Address' => '1600 Pennsylvannia Ave'
            ,'City'             => 'Washington'
            ,'State'            => 'DC'
            ,'Zip_Code'         => '20500'
         } );

 while ( my $response = $ZIPplus4->next_response() )
 {    
     print $response->zip()."\n";
 }

=item Complete

 use WWW::Search::Scraper(qw(1.48));
 use WWW::Search::Scraper::Request::ZIPplus4;

 my $ZIPplus4 = new WWW::Search::Scraper( 'ZIPplus4' );

 my $request = new WWW::Search::Scraper::Request::ZIPplus4;
 
 # Note: Delivery_Address(), and either Zip_Code(), or City() and State(), are required.
 $request->Delivery_Address('1600 Pennsylvannia Ave');
 $request->City('Washington');
 $request->State('DC');
 $request->Zip_Code('20500');

 $ZIPplus4->scraperRequest($request);
 while ( my $response = $ZIPplus4->next_response() )
 {    
     for ( qw(address city state zip county carrierRoute checkDigit deliveryPoint) ) {
         print "$_: ".${$response->$_()}."\n";
     }
 }

=back

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



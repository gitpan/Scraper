
package WWW::Search::Scraper::NorthernLight;

#####################################################################

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(1.48 generic_option addURL trimTags));
use WWW::Search::Scraper::FieldTranslation;

my $scraperQuery = 
   { 
      'type' => 'FORM'       # Type of query generation is 'QUERY'
     ,'formNameOrNumber' => 'powSearch'
     ,'submitButton' => 'search'
      # This is the basic URL on which to build the query.
     ,'url' => 'http://www.northernlight.com/power.html'
      # This is the Scraper attributes => native input fields mapping
      ,'nativeQuery' => 'qr'
      ,'nativeDefaults' => {}
      ,'fieldTranslations' =>
              {
                  '*' =>
                      {    'skills'    => 'qr'
#                            ,'payrate'   => undef
#                            ,'locations' => new WWW::Search::Scraper::FieldTranslation('NorthernLight', 'Job', 'locations')
                          ,'*'         => '*'
                      }
              }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
        [ 'HTML', 
           [ 
               [ 'COUNT', '<b>[0-9,]+ items?</b>']
              ,[ 'NEXT', 1, 'alt="Next Page"' ]
              ,[ 'BODY', '<!--NLBannerStart-->', '<!--NLResultListEnd-->',
                  [  
                     [ 'HIT*' , 'Job', #TEMP 'Job' is for testing, only. gdw.2001.08.18
                        [  
                           [ 'BODY', '<!--NLResultStart-->', '<!--NLResultEnd-->',
                             [
                               [ 'TR',
                                  [
                                     [ 'TD' ]
                                    ,[ 'TD', 
                                        [
                                           [ 'A', 'url', 'title' ]
                                          ,['REGEX', '<!--NLResultRelevanceStart-->(\d+)% -<!--NLResultRelevanceEnd-->', 'relevance']
                                          ,['REGEX', '&nbsp;</b>(.*?)<br>', 'description']
                                        ]
                                     ]
                                  ]
                               ]
                             ]
                           ]
                        ]
                     ] 
                    ,[ 'BOGUS', -1 ] # NorthernLight's last hit is bogus.
                  ]
              ]
           ]
        ];



# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

1;


=pod

=head1 NAME

WWW::Search::Scraper::NorthernLight - class for searching NorthernLight


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('NorthernLight');


=head1 DESCRIPTION

This class is an NorthernLight specialization of WWW::Search.
It handles making and interpreting NorthernLight searches
F<http://www.NorthernLight.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

None at this time (2001.05.06)

=over 8

=item search_url=URL

Specifies who to query with the NorthernLight protocol.
The default is at
http://www.northernlight.com/power.html

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back

=head1 SEARCH FIELDS

=head2 displayResultsPerPage - I<Results per Page>

=over 8

=item "5" => 5

=item "10" => 10

=item "20" => 20

=item "50" => 50

=item "100" => 100

=back

=head2 postingAge - I<Age of Posting>

=over 8

=item "0" => any time

=item "1" => 1 day

=item "3" => 3 days

=item "7" => 1 week

=item "8" => 2 weeks

=item "10" => 1 month

=back

=head2 workTermTypeIDs - I<Work Term>

=over 8

=item "1" => Full Time

=item "2" => Part Time

=item "3" => Contract

=item "4" => Temporary/Seasonal

=item "5" => Internship

=back

=head2 countyIDs - I<Job Location-County>

=over 8

=item "0" => Any

=item "1" => Alameda

=item "2" => Contra Costa

=item "3" => Marin

=item "4" => Napa

=item "5" => San Benito

=item "6" => San Francisco

=item "7" => San Mateo

=item "8" => Santa Clara

=item "9" => Santa Cruz

=item "10" => Solano

=item "11" => Sonoma

=item "12" => Other

=back

=head2 jobPostingCategoryIDs => I<Job Category>

=over 8

=item "0" => Any

=item "1" => Accounting/Finance

=item "2" => Administrative/Clerical

=item "3" => Advertising

=item "4" => Aerospace/Aviation

=item "5" => Agricultural

=item "6" => Architecture

=item "7" => Arts/Entertainment

=item "8" => Assembly

=item "9" => Audio/Visual

=item "10" => Automotive

=item "11" => Banking/Financial Services

=item "12" => Biotechnology

=item "13" => Bookkeeping

=item "14" => Business Development

=item "15" => Child Care Services

=item "16" => Colleges & Universities

=item "17" => Communications/Media

=item "18" => Computer

=item "19" => Computer - Hardware

=item "20" => Computer - Software

=item "21" => Construction

=item "22" => Consulting/Professional Services

=item "23" => Customer Service/Support

=item "24" => Data Entry/Processing

=item "25" => Education/Training

=item "26" => Engineering

=item "27" => Engineering - Civil

=item "28" => Engineering - Hardware

=item "29" => Engineering - Software

=item "30" => Environmental

=item "31" => Executive/Management

=item "32" => Fund Raising/Development

=item "33" => Government/Civil Service

=item "34" => Graphic Design

=item "35" => Health Care/Health Services

=item "36" => Hospitality/Tourism

=item "37" => Human Resources

=item "38" => Information Technology

=item "39" => Insurance

=item "40" => Internet/E-Commerce

=item "41" => Law Enforcement/Security

=item "42" => Legal

=item "43" => Maintenance/Custodial

=item "44" => Manufacturing

=item "45" => Marketing

=item "46" => Miscellaneous

=item "47" => Non-Profit

=item "48" => Pharmaceutical

=item "49" => Printing/Publishing

=item "50" => Property Management/Facilities

=item "51" => Public Relations

=item "74" => Purchasing

=item "52" => QA/QC

=item "53" => Radio/Television/Film/Video

=item "54" => Real Estate

=item "57" => Receptionist

=item "55" => Recruiting/Staffing

=item "56" => Research

=item "58" => Restaurant/Food Service

=item "59" => Retail

=item "60" => Sales

=item "61" => Sales - Inside/Telemarketing

=item "62" => Sales - Outside

=item "63" => Security/Investment

=item "64" => Shipping/Receiving

=item "65" => Social Work/Services

=item "66" => Technical Support

=item "67" => Telecommunications

=item "68" => Training

=item "69" => Transportation

=item "70" => Travel

=item "71" => Warehouse

=item "72" => Web Design

=item "73" => Writer

=back

=head1 AUTHOR

C<WWW::Search::NorthernLight> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut




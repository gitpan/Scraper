
package WWW::Search::Scraper::apartments;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
use WWW::Search::Scraper::Response;

use WWW::Search::Scraper(qw(1.48));

# SAMPLE 
# http://www.apartments.com/search/oasis.dll?mfcisapicommand=quicksearch&QSearchType=1&city=New%20York&state=NY&numbeds=0&minrnt=0&maxrnt=9999
my $scraperQuery = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,'url' => 'http://www.apartments.com/search/oasis.dll?mfcisapicommand=quicksearch&QSearchType=1&'
      # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'city'
     ,'nativeDefaults' =>
                         {    'numbeds' => 0
                             ,'minrnt'  => 0
                             ,'maxrnt'  => '9999'
                             ,'state'   => ''
                         }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'HTML', 
  [ 
      [ 'COUNT', '<strong>Matches: (\d+)</strong>' ]
     ,[ 'NEXT', 2, \&getNextPage ]
     ,[ 'BODY', '<form action="oasis.dll" method="GET" name="Form1">', undef,      # There are two forms in this
         [ [ 'BODY', '<form action="oasis.dll" method="GET" name="Form1">', undef, #  result, by the same name!
              [  
                [ 'TABLE', '#0',
                   [
                      [ 'TR' ] # "Visual Listings".
                     ,[ 'HIT*' ,
                        [ [ 'TR', 
                             [
                                [ 'TD' ,
                                    [  [ 'TABLE',  # the first sub-table is the visual image, et.al.
                                         [ 
                                             [ 'TR' ] # hmmm . . .
                                            ,[ 'TR' ] # hmmm . . .
                                            ,[ 'TR' ] # anchor to visual tour
                                       ] ]
                                    ]
                                ]
                               ,[ 'TD',
                                   [
                                      [ 'TABLE',
                                        [
                                          [ 'TR',
                                            [
                                               [ 'TD', [ [ 'A', 'url', 'title' ] ] ]
                                              ,[ 'TD', 'price' ]
                                              ,[ 'RESIDUE', 'location' ]
                                            ]
                                         ,[ 'TR' ] # ???
                                         ,[ 'TR',
                                           ,[ 'TD', 'description' ]
                                          ]
                                         ,[ 'TR' ] # this row contains anchors to images illustrating the apartment's features.
                                        ]
                                     ]
                                   ]
                                 ]
                               ]
                            ]
                          ]
                         ,[ 'TR' ] # this row contains a horizontal rule separating each result.
                        ]
                      ]
                   ]
                ] 
              ]
           ]
        ] 
    ] 
  ]
];


# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }


# www.apartment.com sets its NEXT button in a submit, with various labels.
# e.g.
# <input type="button" 
#       onclick="javascript:document.location=
#                '/search/oasis.dll?page=Results&resultpos=11&QSearchType=1&minrent=0&maxrent=9999&allsizes=1&allbaths=1&month=0&status=4&state=NY&city=NEW+YORK&prvpg=7'" 
#       value="Last 7 &gt;&gt;">
sub getNextPage {
    my ($self, $hit, $dat) = @_;
    return undef unless
        $dat =~ m-value="Modify Search Criteria".*onclick="javascript:document\.location='(/search/oasis\.dll\?page=Results[^']*?)'[^>]*?&gt;&gt;">-s;
    my $nxt = $1;
    my $url = URI::URL->new($1, $self->{'_base_url'});
    $url = $url->abs;
    return $url;
}

1;

=pod

=head1 NAME

WWW::Search::Scraper::apartments - class for searching www.apartments.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('apartments');


=head1 DESCRIPTION

This class is an apartments specialization of WWW::Search.
It handles making and interpreting apartments searches
F<http://www.apartments.com>.


=head1 OPTIONS

To do.

=head1 OPTIONS

To do

=head1 AUTHOR

C<WWW::Search::apartments> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

The best place to obtain C<WWW::Search::apartments>
is from Glenn's releases on CPAN. Because www.apartments.com
sometimes changes its format in between his releases, 
sometimes more up-to-date versions can be found at
F<http://alumni.caltech.edu/~glenwood/SOFTWARE/index.html>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut




package WWW::Search::Scraper::techies;

=pod

=head1 NAME

WWW::Search::Scraper::techies - class for searching www.techies.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('techies');

Unfortunately, this one does not work. I've included it here in the hope
that somebody can figure it out, since I can't.

It seems no matter what I do, techies.com responds with a demand that I
"enable cookies on your browser". I'm sure cookies are enabled via Search.pm
for techies.pm, so there's something fishy going on with this that I can't figure out.

=head1 DESCRIPTION

This class is an techies specialization of WWW::Search.
It handles making and interpreting techies searches
F<http://www.techies.com>.


=head1 OPTIONS

    location => a location string (becomes part of the URL).
                pick from (as of 28.May.2001)

    Alaska ( for AK )
    Midsouth ( for AL )
    Midsouth ( for AR )
    Phoenix ( for AZ )
    Bayarea ( for CA - Bay Area )   
    Losangeles ( for CA - Los Angeles Area )
    Sacramento ( for CA - Sacramento )
    Sandiego ( for CA - San Diego )
    Denver ( for CO )
    Hartford ( for CT - Hartford )
    Newyork ( for CT - NYC / Stamford )
    dc ( for DC )
    Philadelphia ( for DE )
    Southflorida ( for FL - Miami )
    Centralflorida ( for FL - Orlando / Tampa )
    Atlanta ( for GA )
    Hawaii ( for HI )
    Greatplains ( for IA )
    Mountain ( for ID )
    Chicago ( for IL - Chicago )
    Stlouis ( for IL - Southern  )
    Indianapolis ( for IN )
    Kansascity ( for KS )
    Cincinnati ( for KY )
    Midsouth ( for LA )
    Boston ( for MA )
    dc ( for MD )
    Boston ( for ME )
    Detroit ( for MI )
    Twincities ( for MN )
    Kansascity ( for MO - Kansas City )
    Stlouis ( for MO - St. Louis )
    Midsouth ( for MS )
    Mountain ( for MT )
    Northcarolina ( for NC )
    Greatplains ( for ND )
    Greatplains ( for NE )
    Boston ( for NH )
    Newyork ( for NJ - Northern / Central )
    Philadelphia ( for NJ - Southern )
    Phoenix ( for NM )
    Lasvegas ( for NV )
    Newyork ( for NY - NYC )
    Upstatenewyork ( for NY - Upstate )
    Cincinnati ( for OH - Cincinnati )
    Cleveland ( for OH - Cleveland )
    Columbus ( for OH - Columbus )
    Greatplains ( for OK )
    Portland ( for OR )
    Philadelphia ( for PA - Philadelphia )
    Pittsburgh ( for PA - Pittsburgh )
    Boston ( for RI )
    Northcarolina ( for SC )
    Greatplains ( for SD )
    Midsouth ( for TN )
    Austin ( for TX - Austin )
    Dallas ( for TX - Dallas / Ft Worth )
    Houston ( for TX - Houston )
    Saltlake ( for UT )
    dc ( for VA )
    Boston ( for VT )
    Seattle ( for WA )
    Wisconsin ( for WI )
    dc ( for WV )
    Denver ( for WY )
    headhunterjobs ( for Headhunter Jobs )


=head1 AUTHOR

C<WWW::Search::techies> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#####################################################################

@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.38));
require WWW::SearchResult;

use strict;

# SAMPLE
# "http://" + marketurl + ".techies.com/Common/Includes/Main/Search_Session_include_m.jsp?Search=" + escape(searchString)
#
sub native_setup_search
{
    my $self = shift;
    my ($native_query, $native_options_ref) = @_;
    
    $self->{'_options'}{'scraperQuery'} =
    [ 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,\&makeURL
      # This is the Scraper attributes => native input fields mapping
     ,{'scraperQuery' => 'Search'
      }
      # Some more options for the Scraper operation.
     ,{'cookies' => 1
      }
    ];

    # scraperFrame describes the format of the result page.
    $self->{'_options'}{'scrapeFrame'} = 
[ 'HTML', 
  [ 
[ 'TRACE' ],
      [ 'COUNT', '<strong>Matches: (\d+)</strong>' ]
     ,[ 'NEXT', 1, '<img src="/Common/Graphics/Buttons/Next\.gif" border="0">' ]
     # The content is framed by two NEW SEARCH buttons . . .
     ,[ 'BODY', 'src="/Common/Graphics/Buttons/NewSearch.gif"', undef,   # There are two forms in this
         [ [ 'BODY', undef, 'src="/Common/Graphics/Buttons/NewSearch.gif"', # result, by the same name!
             [  
                [ 'HIT*' ,
                    [ [ 'TR', 
                         [
                            [ 'TD', 
                                [ [ 'A', 'url', 'title' ]
                                 ,[ 'A', 'companyURL', 'company' ]
                                 ,[ 'RESIDUE', 'description', \&trimTags ]
                                ]
                             ]
                         ]
                      ]
#                     ,[ 'TR' ] # this row contains a horizontal rule separating each result.
                    ]
                ]
             ]
         ] ]
      ] 
   ]
];

    # WWW::Search::Scraper understands all that and will setup the search.
    return $self->SUPER::native_setup_search(@_);
}


sub makeURL {
    my ($self, $native_query, $native_options_ref) = @_;
    my $url = "http://$native_options_ref->{'Location'}.techies.com/Common/Includes/Main/Search_Session_include_m.jsp?";
    undef $native_options_ref->{'Location'}; # This is already in the URL, don't let Scraper.pm add it again.
    $self->{'_http_method'} = 'POST';
    return $url;
}

use WWW::Search::Scraper::Response::Job;
sub newHit {
    my $self = new WWW::Search::Scraper::Response::Job;
    return $self;
}



1;

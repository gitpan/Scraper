
package WWW::Search::Scraper::computerjobs;

=pod

=head1 NAME

WWW::Search::Scraper::computerjobs - class for searching www.computerjobs.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('computerjobs');

=head1 DESCRIPTION

This class is an computerjobs specialization of WWW::Search.
It handles making and interpreting computerjobs searches
F<http://www.computerjobs.com>.


=head1 OPTIONS

=over 8

=item siteid => a regional code

    '139' -> All regions
    '100' -> Atlanta
    '109' -> Boston
    '102' -> Carolina
    '103' -> Chicago
    '105' -> D.C. Metro
    '114' -> Denver
    '111' -> Detroit
    '104' -> Florida
    '118' -> Los Angeles
    '106' -> New York
    '108' -> Ohio
    '110' -> Philadelphia
    '107' -> Phoenix
    '116' -> Portland
    '115' -> Seattle
    '117' -> Silicon Valley
    '113' -> St. Louis
    '101' -> Texas
    '112' -> Twin Cities


=item s_jcid => a skills code

    ''    -> All categories
    '101' -> AS/400
    '116' -> Data Warehousing
    '115' -> Database Systems
    '106' -> E-Commerce / Internet
    '103' -> ERP
    '117' -> Executive Level
    '108' -> Hardware
    '112' -> Help Desk
    '100' -> Legacy Systems
    '118' -> Miscellaneous
    '107' -> Networking
    '105' -> New Media
    '109' -> Project Management
    '110' -> Quality Assurance
    '114' -> Technical Recruiting
    '113' -> Technical Sales
    '111' -> Technical Writing
    '102' -> Unix
    '104' -> Windows Development

=back                


=head1 AUTHOR

C<WWW::Search::computerjobs> is written and maintained
by Glenn Wood, <glenwood@dnai.com>.

The best place to obtain C<WWW::Search::computerjobs>
is from Glenn's releases on CPAN. Because www.computerjobs.com
sometimes changes its format in between his releases, 
sometimes more up-to-date versions can be found at
F<http://alumni.caltech.edu/~glenwood/SOFTWARE/index.html>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#####################################################################

@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.38 trimTags trimLFs trimLFLFs));
require WWW::SearchResult;

use strict;

sub native_setup_search
{
    my $self = shift;
    my ($native_query, $native_options_ref) = @_;
    
    $self->{'_options'}{'scraperQuery'} =
    [ 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,'http://www.search.computerjobs.com/job_results.asp?'
      # This is the Scraper attributes => native input fields mapping
     ,{'scraperQuery' => 's_kw'
      }
      # Some more options for the Scraper operation.
     ,{'cookies' => 1
      }
    ];

    # scraperFrame describes the format of the result page.
    $self->{'_options'}{'scrapeFrame'} = 
[ 'HTML', 
  [ 
      [ 'COUNT', '([,0-9]+)\s+Search results ' ]
     ,[ 'NEXT', 1, '/ci/page_next_page.gif' ]
     # I think there might be something in this 'BODY' segment, but I haven't seen any, yet.
     ,[ 'BODY', '<!--- featured jobs --->', '<!-- end featured jobs -->' ]
     ,[ 'BODY', 'Page \d+ of', undef,
         [
            [ 'HIT*' ,
              [
                [ 'TABLE', '#0',
                  [
                    [ 'TR', 
                      [
                        [ 'TD' ] 
                       ,[ 'TD', 'title', \&trimLFs ]
                       ,[ 'TD' ] 
                      ]
                    ]
                  ]
                ]
               ,[ 'TABLE', '#0', 
                  [ 
                    [ 'TR', 
                      [ 
                         [ 'TD', 'description', \&parseDescriptionAndAllThat ]
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

    # WWW::Search::Scraper understands all that and will setup the search.
    return $self->SUPER::native_setup_search(@_);
}

# Here we might someday do some more elaborate parsing, since the
# 'description' text contains the company, location and salary (sometimes).
sub parseDescriptionAndAllThat {
    my ($self, $hit, $dat) = @_;
    return $self->trimLFLFs($hit, $dat);
}


# www.computerjobs.com is special because the last two hits Scraper finds is bogus (a spacer gif).
sub native_retrieve_some
{
    my ($self) = @_;

    my $hits_found = $self->SUPER::native_retrieve_some();
    $hits_found -= 2;
    return undef unless $hits_found > 0;
    pop @{$self->{cache}}; pop @{$self->{cache}};
    return $hits_found;
}


1;

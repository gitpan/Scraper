
package WWW::Search::Scraper::CraigsList;

#####################################################################

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
use WWW::Search::Scraper(qw(1.48 generic_option addURL trimTags));
use WWW::Search::Scraper::FieldTranslation;

$VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

# Craigs List differs from other search engines in a few ways.
# One of them is the results page is not tablulated, or data lined.
# It returns each job listing on a single line.
# This line can be parsed with a single regular expression, which is what we do.
#
# SAMPLE :
#
# <br>Apr&nbsp;24&nbsp;-&nbsp;<a href=/sfo/eng/959347.html>Senior&nbsp;Software&nbsp;Engineer</a>&nbsp(San&nbsp;Francisco)<font size=-1>&nbsp;(internet&nbsp;engineering&nbsp;jobs)</font></br>
#
#
# private

my $scraperRequest = 
   { 
      'type' => 'POST'       # Type of query generation is 'POST'
      # This is the basic URL on which to build the query.
     ,'url' => 'http://www.craigslist.org/cgi-bin/search.cgi?'
      # This is the Scraper attributes => native input fields mapping
      ,'nativeQuery' => 'query'
      ,'nativeDefaults' =>
                      {    'areaID'     => '1'
                          ,'subAreaID'  => '0'
                          ,'group'      => 'J'
                          ,'catAbb'     => ''
                          ,'areaAbbrev' => ''
                      }
#      ,'defaultRequestClass' => 'Job'
      ,'fieldTranslations' =>
             { '*' => 
                  {    '*'         => '*'
                      ,'skills'    => 'query'
#                          ,'payrate'   => \&translatePayrate
                      ,'locations' => new WWW::Search::Scraper::FieldTranslation('CraigsList', 'Job', 'locations')
                  }
              }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'HTML', 
   [ 
      [ 'NEXT', 1, 'Next ' ]
     ,[ 'BODY', '</FORM>', '' ,
          [ 
             [ 'COUNT', 'Found: (\d+)']
            ,[ 'HIT*' ,
                [  
                   [ 'REGEX', '<p>\s*(&nbsp;)?(.*?-\d+).*?<a href=([^>]+)>(.*?)</a>.*?\((.*?)\).*?<.*?>(.*?)<', 
                      undef, 'date', 'url', 'title', 'location', 'description'
                   ]
                ]
             ]
          ]
      ]
   ]
];


sub testParameters {
    # 'POST' style scraperFrames can't be tested cause of a bug in WWW::Search(2.2[56]) !
    my $isNotTestable = WWW::Search::Scraper::isGlennWood()?0:0;
    return {
                 'SKIP' => $isNotTestable
                ,'testNativeQuery' => 'Quality'
                ,'expectedOnePage' => 50
                ,'expectedMultiPage' => 100
                ,'expectedBogusPage' => 0
                ,'usesPOST' => 1
           };
}

sub init {
    my ($self) = @_;
    $self->searchEngineHome('http://www.CraigsList.org');
    $self->searchEngineLogo('<font size=5><b>craigslist</b></font>');
    return $self;
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

1;
__END__

=pod

=head1 NAME

WWW::Search::Scraper::CraigsList - Scrapes CraigsList


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('CraigsList');


=head1 DESCRIPTION

This class is an CraigsList specialization of WWW::Search.
It handles making and interpreting CraigsList searches
F<http://www.CraigsList.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

None at this time (2001.04.25)

=over 8

=item search_url=URL

Specifies who to query with the CraigsList protocol.
The default is at
C<http://www.CraigsList.com/cgi-bin/job-search>.

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


Internet/Web Engineering Category options:
 <null> - ALL JOBS
 art - web design jobs
 bus - business jobs
 mar - marketing jobs
 eng - internet engineering jobs
 etc - etcetera jobs
 wri - writing jobs
 sof - software jobs
 acc - finance jobs
 ofc - office jobs
 med - media jobs
 hea - health science jobs
 ret - retail jobs
 npo - nonprofit jobs
 lgl - legal jobs
 egr - engineering jobs
 sls - sales jobs
 sad - sys admin jobs
 tel - network jobs
 tfr - tv video radio jobs
 hum - human resource jobs
 tch - tech support jobs
 edu - education jobs
 trd - skilled trades jobs

Checkboxes - additive to search(?)

addOne   value=telecommuting - telecommute
addTwo   value=contract      - contract
addThree value=internship    - internships
addFour  value=part-time     - part-time
addFive  value=non-profit    - non-profit


=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,
or the specialized CraigsList searches described in options.


=head1 AUTHOR

C<WWW::Search::CraigsList> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

------------------------------------------------
             
Search.pm and Search::AltaVista.pm (of which CraigsList.pm is a derivative)
is Copyright (c) 1996-1998 University of Southern California.
All rights reserved.                                            

Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation, advertising
materials, and other materials related to such distribution and use
acknowledge that the software was developed by the University of
Southern California, Information Sciences Institute.  The name of the
University may not be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut


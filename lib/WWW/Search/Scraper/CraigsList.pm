
package WWW::Search::Scraper::CraigsList;

#####################################################################

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
use WWW::Search::Scraper(qw(1.41 generic_option addURL trimTags));
$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

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
sub native_setup_search
{
   my $self = shift;
    
   $self->{'_options'}{'scraperQuery'} =
    [ 'POST'       # Type of query generation is 'QUERY', http_method = 'POST'
      # This is the basic URL on which to build the query.
     ,'http://www.craigslist.org/cgi-bin/search.cgi?'
      # This is the Scraper attributes => native input fields mapping
     ,{'scraperQuery' => 'query'
      }
      # Some more options for the Scraper operation.
     ,{'cookies' => 0
      }
    ];

   # Set up the default input field values.
   $self->{_options}{'areaID'}   = '1';
   $self->{_options}{'subAreaID'}= '0';
   $self->{_options}{'group'}    = 'J';
   $self->{_options}{'catAbb'}   =  '';
   $self->{_options}{'areaAbbrev'}= '';
    
    $self->{'_options'}{'scrapeFrame'} = 
       [ 'HTML', 
         [ [ 'BODY', '</FORM>', '' ,
           [ [ 'COUNT', 'found (\d+) entries'] ,
             [ 'HIT*' ,
                 [  [ 'REGEX', '(.*?)-.*?<a href=([^>]+)>(.*?)</a>(.*?)<.*?>(.*?)<', 
                        'date', 'url', 'title', 'location', 'description'
                 ]
             ]   ]
         ] ]
       ] ];

 
    # WWW::Search::Scraper understands all that and will setup the search.
    return $self->SUPER::native_setup_search(@_);
}

use WWW::Search::Scraper::Response;
sub newHit {
    my $self = new WWW::Search::Scraper::Response;
    return $self;
}


1;
__END__

=pod

=head1 NAME

WWW::Search::Scraper::CraigsList - class for scraping CraigsList


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
by Glenn Wood, <glenwood@alumni.caltech.edu>.

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


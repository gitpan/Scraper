
package WWW::Search::Scraper::BAJobs;

=pod

=head1 NAME

WWW::Search::Scraper::BAJobs - class for searching BAJobs


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('BAJobs');


=head1 DESCRIPTION

This class is an BAJobs specialization of WWW::Search.
It handles making and interpreting BAJobs searches
F<http://www.BAJobs.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

None at this time (2001.05.06)

=over 8

=item search_url=URL

Specifies who to query with the BAJobs protocol.
The default is at
C<http://www.BAJobs.com/cgi-bin/job-search>.

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

C<WWW::Search::BAJobs> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


#####################################################################

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(1.42 generic_option addURL trimTags));

use LWP::UserAgent;
use HTML::Form;
use HTTP::Cookies;

sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $native_query = WWW::Search::unescape_query($native_query); # Thanks, but no thanks, Search.pm!
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
	    'scraperForm_url' => ['http://www.bajobs.com/jobseeker/search.jsp', 0, 'searchKeywords', undef]
        };
    };
    
    $self->cookie_jar(HTTP::Cookies->new());
    
    my $response = $self->http_request('GET', $self->{_options}{'scraperForm_url'}[0]);
    return undef unless $response->is_success;
   
    my @forms = HTML::Form->parse($response->content(), $response->base());
    
    my $form = $forms[$self->{_options}{'scraperForm_url'}[1]];
    $self->{'_http_method'} = $form->method();

    $self->{'_options'}{'scrapeFrame'} = 
        [ 'HTML', 
           [ 
               [ 'COUNT', 'Job Postings.*?[- 0-9]+.*?of.*?<b>([,0-9]+)</b></font> total']
              ,[ 'BODY', '<!-- top prev/next -->', '<!-- end top prev/next -->',
                 [ [ 'NEXT', 1, '<b>NEXT</b>' ] ] #, \&fixNext ] ]
               ]
              ,[ 'BODY', '<!-- job list -->', '',
                 [  
                    [ 'TABLE', '#0' ,
                       [
                          [ 'TR' ] , # There's an actual title row! Imagine that!
                          [ 'HIT*' ,
                            [  
                               [ 'TR',
                                  [
                                     [ 'TD', [ [ 'A', 'corpURL', 'corporateBackground' ] ] ]
                                    ,[ 'TD', 'postingDate' ]
                                    ,[ 'A', 'url', 'title' ]
                                    ,[ 'TD', 'company' ]
                                    ,[ 'TD', '_clear_gif_' ]
                                    ,[ 'TD', 'location' ]
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

 
    my($options_ref) = $self->{_options};
    if (defined($native_options_ref)) {
    	# Copy in new options.
    	foreach (keys %$native_options_ref) {
    	    $options_ref->{$_} = $native_options_ref->{$_};
    	};
    };
    # Process the options.
    # (Now in sorted order for consistency regarless of hash ordering.)
    my($options) = '';
    foreach (sort keys %$options_ref) {
    	# printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    	next if (generic_option($_));
    	$options .= $_ . '=' . $options_ref->{$_} . '&';
    };
    $self->{_debug} = $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Finally figure out the url.
    return undef unless $form;

    my $query = $form->find_input($self->{_options}{'scraperForm_url'}[2]);
    $query->value($native_query);

    my $submit_button = $form->find_input($self->{_options}{'scraperForm_url'}[3], 'submit');
    my $req = $submit_button->click($form); #
    $self->{_options}{'scraperRequest'} = $req;

    $self->{'search_method'} = $form->method();
    $self->{_base_url} = 
	$self->{_next_url} = $req->uri().'?'.$req->content();
    print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
}


use WWW::Search::Scraper::Response::Job;
sub newHit {
    my $self = new WWW::Search::Scraper::Response::Job;
    return $self;
}

1;

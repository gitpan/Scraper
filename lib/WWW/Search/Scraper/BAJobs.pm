
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
$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(1.42 generic_option addURL trimTags));

use LWP::UserAgent;
use HTML::Form;
use HTTP::Cookies;

sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
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

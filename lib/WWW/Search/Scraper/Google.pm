
package WWW::Search::Scraper::Google;

=pod

=head1 NAME

WWW::Search::Google - class for searching Google


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('Google');


=head1 DESCRIPTION

This class is an Google specialization of WWW::Search.
It handles making and interpreting Google searches
F<http://www.Google.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::Google> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(generic_option addURL trimTags));
require WWW::SearchResult;

use LWP::UserAgent;
use HTML::Form;

use strict;

sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
	    'scraperForm_url' => ['http://www.Google.com', 0, 'q', 'btnG']
        };
    };
    
   my $ua = new LWP::UserAgent;
   $ua->agent("WWW::Search::Scraper('Google') " . $ua->agent);
   # Create a request
   my $url = $self->{_options}{'scraperForm_url'}[0];
   my $request = new HTTP::Request GET => $url;
   $request->content_type('application/x-www-form-urlencoded');
   my $response = $ua->request($request);
    
  my $formHTML = $response->content();
  my @forms = HTML::Form->parse($formHTML, $response->base());
    
  my $form = $forms[$self->{_options}{'scraperForm_url'}[1]];

#    $self->{'_http_method'} = $form->method();

    $self->{'_options'}{'scrapeFrame'} = 
       [ 'HTML', 
          [ 
             [ 'BODY', 'table>', '' ,
               [
                  [ 'NEXT', 1, '[^>]*<span class=big><b>Next</b></span>[^<]*' ],
                  [ 'COUNT', 'Results <b>[- 0-9]+</b> of about <b>([,0-9]+)</b>'] ,
                  [ 'TABLE', '#4' ],
                  [ 'HIT*' ,
                    [  
                      [ 'AN', 'url', 'title' ],
                      [ 'REGEX', '<br> <b>\.\.\.</b>(.*?)<b>\.\.\.</b>', 'description' ]
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
    my $query = $form->find_input($self->{_options}{'scraperForm_url'}[2]);
    $query->value($native_query);
    my $submit_button = $form->find_input($self->{_options}{'scraperForm_url'}[3]);
    my $req = $submit_button->click($form);
    $self->{_base_url} = 
	$self->{_next_url} = $req->uri();
    print STDERR $self->{_base_url} . "\n";# if ($self->{_debug});
}

use WWW::Search::Scraper::Response::Job;
sub newHit {
    my $self = new WWW::Search::Scraper::Response::Job;
    return $self;
}

1;

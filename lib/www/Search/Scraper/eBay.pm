
package WWW::Search::Scraper::eBay;

=pod

=head1 NAME

WWW::Search::eBay - class for searching eBay


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('eBay');


=head1 DESCRIPTION

This class is an eBay specialization of WWW::Search.
It handles making and interpreting eBay searches
F<http://www.eBay.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

None at this time (2001.05.06)

=over 8

=item search_url=URL

Specifies who to query with the eBay protocol.
The default is at
C<http://www.eBay.com/cgi-bin/job-search>.

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::eBay> is written and maintained
by Glenn Wood, <glenwood@dnai.com>.

The best place to obtain C<WWW::Search::eBay>
is from Martin Thurn's WWW::Search releases on CPAN.
Because eBay sometimes changes its format
in between his releases, sometimes more up-to-date versions
can be found at
F<http://alumni.caltech.edu/~glenwood/SOFTWARE/index.html>.


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
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(1.24 generic_option addURL trimTags));
require WWW::SearchResult;

use HTML::Form;
use HTTP::Cookies;

use strict;


sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
	    'scraperForm_url' => ['http://pages.ebay.com/search/items/search.html', 0, 'query', undef]
        };
    };
    
#    $self->cookie_jar(HTTP::Cookies->new());
    
    my $response = $self->http_request('GET', $self->{_options}{'scraperForm_url'}[0]);
    unless ( $response->is_success ) {
        print $response->error_as_HTML();
        return undef;
    };
   
    my @forms = HTML::Form->parse($response->content(), $response->base());
    
    my $form = $forms[$self->{_options}{'scraperForm_url'}[1]];
    $self->{'_http_method'} = $form->method();

    $self->{'_options'}{'scrapeFrame'} = 
        [ 'HTML', 
            [ 
               [ 'COUNT', '([,0-9]+)</b> items found  ?for']
              ,[ 'BODY', '</form>', undef,
                  [  
                     [ 'NEXT', 2, \&findNextForm ]
                    ,[ 'BODY', '<!-- eBayCacheStart -->', '<!-- eBayCacheEnd -->',
                       [ 
                           [ 'TABLE', '#0' ]
                          ,[ 'HIT*' ,
                             [ 
                                [ 'TABLE', '#0', 
                                   [  
                                      [ 'TR',
                                         [
                                            [ 'TD', 'itemNumber' ]
                                           ,[ 'TD', [ [ 'A', 'url', 'title' ] ] ] 
                                           ,[ 'TD', 'price' ]
                                           ,[ 'TD', 'bids' ]
                                           ,[ 'TD', 'endsPDT' ]
                                         ]
                                      ]
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
    my $url = $req->uri()->uri_unescape();
print "NEXT_URL: '$url'\n";
#    $url .= '?' . $req->content() if $req->content(); # THIS WAS HANDLING A SPECIAL PROBLEM WITH BAJOBS (HTTP 302).
    $self->{_base_url} = 
	$self->{_next_url} = $url;
    print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
}


# eBay is special because the last hit Scraper finds is bogus (a spacer gif).
sub native_retrieve_some
{
    my ($self) = @_;

    my $hits_found = $self->SUPER::native_retrieve_some();
    $hits_found -= 1;
    return undef unless $hits_found > 0;
    pop @{$self->{cache}};
    return $hits_found;
}



# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
sub findNextForm {
    my ($self, $hit, $dat) = @_;
    
    my $next_content = $dat;
    while ( my ($sub_content, $frm) = $self->getMarkedText('FORM', \$next_content) ) {
        last unless $sub_content;
        # Reconstruct the form that contains the NEXT data.
        my @forms = HTML::Form->parse("<form $frm>$sub_content</form>", $self->{'_base_url'});
        my $form = $forms[0];

        my $submit_button;
        for ( $form->inputs() ) {
            if ( $_->value() eq 'Next' ) {
                $submit_button = $_;
                last;
            }
        }
        if ( $submit_button ) {
            my $req = $submit_button->click($form); #
            return $req->uri();
        }
    }
    return undef;
}
1;

package WWW::Search::Scraper::eBay;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.24 generic_option addURL trimTags));

use HTML::Form;

my $defaultScraperForm_url = ['http://pages.ebay.com/search/items/search.html', 0, 'query', undef];

sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $$defaultScraperForm_url[0] = $_->{'scraperBaseURL'};
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
}


sub native_setup_search
{
    my ($self, $native_query, $native_options_ref) = @_;
    my $debug = $self->{'_debug'};

    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
    	    'scraperForm_url' => $defaultScraperForm_url
        };
    };
    
    print "GetForm: '".$self->{_options}{'scraperForm_url'}[0]."'\n" if $debug;
    my $response = $self->http_request('GET', $self->{_options}{'scraperForm_url'}[0]);
    unless ( $response->is_success ) {
        print STDERR $response->error_as_HTML() if $debug;
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
                          ,[ 'HIT*' , 'Auction',
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
                            ,[ 'BOGUS', -1 ] # eBay's last hit is bogus (a spacer gif).
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
    unless ( $form ) {
        print STDERR "Can't find a <FORM> in ".$response->content()."\n" if $debug;
        return undef;
    }
    my $query = $form->find_input($self->{_options}{'scraperForm_url'}[2]);
    $query->value($native_query);

    my $submit_button = $form->find_input($self->{_options}{'scraperForm_url'}[3], 'submit');
    my $req = $submit_button->click($form); #
    $self->{_options}{'scraperRequest'} = $req;

    $self->{'search_method'} = $form->method();
    my $url = $req->uri()->uri_unescape();

    $self->{_base_url} = 
	$self->{_next_url} = $url;
    print  STDERR "BASE_URL: '" . $self->{_base_url} . "'\n" if $debug;
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
__END__

=pod

=head1 NAME

WWW::Search::Scraper::eBay - class for searching www.eBay.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('eBay');


=head1 DESCRIPTION

This class is an eBay extension of WWW::Search::Scraper.
It handles making and interpreting eBay searches
F<http://www.eBay.com>.

=head1 OPTIONS

=over 8

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


=head1 AUTHOR

C<WWW::Search::eBay> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#####################################################################


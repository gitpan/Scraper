
package WWW::Search::Scraper::YahooFinance;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.24 generic_option addURL trimTags));

use HTML::Form;

my $scraperRequest = 
   { 
      'type' => 'FORM'
     ,'formNameOrNumber' => undef
     ,'submitButton' => undef

     # This is the basic URL on which to build the query.
     ,'url' => 'http://finance.yahoo.com/'
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'query'
     ,'nativeDefaults' => {
                            'query' => undef
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
                            ,[ 'BOGUS', -1 ] # YahooFinance's last hit is bogus (a spacer gif).
                           ] 
                       ] 
                     ]
                  ]
               ]
            ]
        ];



sub testParameters {
    return {
                 'SKIP' => 'The YahooFinance module is not yet implemented.' 
                ,'testNativeQuery' => 'turntable'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 50
                ,'expectedBogusPage' => 0
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }



my $defaultScraperForm_url = ['http://pages.ebay.com/search/items/search.html', 0, 'query', undef];
sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $scraperRequest->{'url'} = $_->{'scraperBaseURL'};  # new form
            $$defaultScraperForm_url[0] = $_->{'scraperBaseURL'}; # old form
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
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

sub getMarketSummary {
    use LWP::Simple;
    my $yahooFinance = get 'http://finance.yahoo.com/';

    my ($nasdaq) = ($yahooFinance =~ m{<small><nobr>Nasdaq</nobr></small></a></td><td nowrap><small>([\d,.]+)</small>}si);
    my ($dow) = ($yahooFinance =~ m{<nobr>Dow</nobr></small></a></td><td nowrap><small>([\d,.]+)</small>}si);
    my ($sap) = ($yahooFinance =~ m{<nobr>S&amp;P 500</nobr></small></a></td><td nowrap><small>([\d,.]+)</small>}si);
    my ($tenYrBond) = ($yahooFinance =~ m{<small>10-Yr Bond</small></a></td><td nowrap><small>([\d.%]+)</small>}si);
    my ($nyseVolume) = ($yahooFinance =~ m{<small>NYSE Volume</small></a></td><td colspan=2 nowrap><small>([\d,]+)</small>}si);
    my ($nasdaqVolume) = ($yahooFinance =~ m{<small>Nasdaq Volume</small></a></td><td colspan=2 nowrap><small>([\d,]+)</small>}si);

    return ($dow, $nasdaq, $sap, $tenYrBond, $nyseVolume, $nasdaqVolume);
    
}
1;

__END__

=pod

=head1 NAME

WWW::Search::Scraper::YahooFinance - Scrapes Finance.Yahoo.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('YahooFinance');

    ($dow, $nasdaq, $sap, $tenYrBond, $nyseVolume, $nasdaqVolume)
             = $scraper->getMarketSummary();

=head1 DESCRIPTION

This class is an YahooFinance extension of WWW::Search::Scraper.
It handles making and interpreting Yahoo Finance searches
F<http://Finance.Yahoo.com>.

The Search capabilities of module are not yet implemented; only the getMarketSummary method is implemented.

=head1 OPTIONS

=over 8

=item getMarketSummary

Gets the "Market Summary" data off of finance.yahoo.com.

    $scraper = new WWW::Search::Scraper('YahooFinance');
    ($dow, $nasdaq, $sap, $tenYrBond, $nyseVolume, $nasdaqVolume)
             = $scraper->getMarketSummary();

=back


=head1 AUTHOR

C<WWW::Search::YahooFinance> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#####################################################################


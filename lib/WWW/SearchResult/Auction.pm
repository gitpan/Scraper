package WWW::SearchResult::Auction;

no strict;
@ISA = qw(WWW::SearchResult::Scraper);
use WWW::SearchResult::Scraper;
use strict;

sub resultTitles {
    return {
                'relevance'  => 'Relevance'
               ,'itemNumber' => 'Item #'
               ,'title'      => 'Title'
               ,'price'      => 'Price'
               ,'bids'       => "# of\nBids"
           };
}

sub results {
    my $self = shift;
    return {
                'relevance'  => $self->relevance()
               ,'itemNumber' => $self->itemNumber()
               ,'title'      => $self->title()
               ,'price'      => $self->price()
               ,'bids'       => $self->bids()
           } 
}

sub relevance { return $_[0]->_elem('relevance'); }
sub itemNumber { return $_[0]->_elem('itemNumber'); }
sub title { return $_[0]->_elem('title'); }
sub price { return $_[0]->_elem('price'); }
sub bids { return $_[0]->_elem('bids'); }


package WWW::Search::Scraper::Response::Auction;


=head1 NAME

WWW::Search::Scraper::Response::Auction - result class for scrapes of Auction sites


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Search::Scraper::Response::Auction> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper::Response);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
use WWW::Search::Scraper::Response;

sub new {
    my $self = WWW::Search::Scraper::Response::new(
         'generic'
        ,{
                'relevance'  => ''
               ,'itemNumber' => ''
               ,'title'      => ''
               ,'price'      => ''
               ,'bids'       => ''
         }
        ,@_);
    return $self;
}

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


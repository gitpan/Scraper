package WWW::SearchResult::Sherlock;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::SearchResult::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
use WWW::SearchResult::Scraper;

sub resultTitles {
    return {
                'relevance'  => 'Relevance'
               ,'price'      => 'Price'
               ,'avail'      => 'Available'
               ,'date'       => 'Date'
               ,'name'       => 'Name'
               ,'email'      => 'E-mail'
               ,'detail'     => 'Detail'
               ,'url'        => 'URL'
               ,'browserResultType' => 'Browser Result Type'
           };
}

sub results {
    my $self = shift;
    return {
                'relevance'  => $self->relevance()
               ,'price'      => $self->price()
               ,'avail'      => $self->avail()
               ,'date'       => $self->date()
               ,'name'       => $self->name()
               ,'email'      => $self->email()
               ,'detail'     => $self->detail()
               ,'browserResultType' => $self->browserResultType()
           } 
}

sub relevance { return $_[0]->_elem('result_relevance'); }
sub price { return $_[0]->_elem('result_price'); }
sub avail { return $_[0]->_elem('result_avail'); }
sub date { return $_[0]->_elem('result_date'); }
sub name { return $_[0]->_elem('result_name'); }
sub email { return $_[0]->_elem('result_email'); }
sub detail { return $_[0]->_elem('result_detail'); }
sub browserResultType { return $_[0]->{'browserResultType'}; }
#  sub url() is the same as for WWW::SearchResults.

1;

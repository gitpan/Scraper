package WWW::SearchResult::Job;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::SearchResult::Scraper);
use WWW::SearchResult;
use WWW::SearchResult::Scraper;

sub resultTitles {
    return {
                'relevance'  => 'Relevance'
               ,'title'      => 'Title'
               ,'description' => 'Description'
               ,'company'    => 'Company'
               ,'location'   => 'Location'
               ,'postDate'   => 'Post-Date'
               ,'url'        => 'URL'
           };
}

sub results {
    my $self = shift;
    return {
                'relevance'  => $self->relevance()
               ,'title'      => $self->title()
               ,'description' => $self->description()
               ,'company'    => $self->company()
               ,'location'   => $self->location()
               ,'postDate'   => $self->postDate()
               ,'url'        => $self->url()
           } 
}

sub relevance { return $_[0]->_elem('relevance'); }
sub title { return $_[0]->_elem('title'); }
sub description { return $_[0]->_elem('description'); }
sub company { return $_[0]->_elem('company'); }
sub location { return $_[0]->_elem('location'); }
sub postDate { return $_[0]->_elem('postDate'); }


package WWW::Search::Scraper::Response::Job;


=head1 NAME

WWW::Search::Scraper::Response::Job - result class for scrapes of Job Listings


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Search::Scraper::Response::Job> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper::Response);
use WWW::Search::Scraper::Response;
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

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


# This is the same as the super-class, except that
#  'title' is folded into an anchor with 'url'.
sub toHTML {
    my ($self) = @_;
    
    my $result;
    my %results = %{$self->results()};
    my %resultTitles = %{$self->resultTitles()};
    
    $result .= "<DT>$resultTitles{'title'}: </DT><DD><A HREF='$results{'url'}'>$results{'title'}</A></DD>\n";
    for ( keys %resultTitles ) {
        next if $_ eq 'url' or $_ eq 'title';
        next unless $results{$_};
        $result .= "<DT>$resultTitles{$_}: </DT><DD>$results{$_}</DD>\n";
    }
    $result .= "<DT>from:</DT><DD>".$self->{'searchObject'}->getName()."</DD>\n";

    return $result;
}

1;


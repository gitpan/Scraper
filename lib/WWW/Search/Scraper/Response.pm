package WWW::Search::Scraper::Response;


=head1 NAME

WWW::Search::Scraper::Response::Scraper - result class of generic scrapes.


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS

None at this time (2001.04.25)

=head1 AUTHOR

C<WWW::Search::Scraper::Response::Scraper> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::SearchResult);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
require WWW::SearchResult;

sub new { 
    my $class = shift;
    my $self = new WWW::SearchResult;
    bless $self, $class;

    for ( keys %{$self->resultTitles()} ) {
        $self->{$_} = '';
    }
    return $self;
}


# Return a table of names and titles for all data result columns.
sub resultTitles {
    return {
                'relevance'  => 'Relevance'
               ,'url'        => 'URL'
           };
}


sub results {
    my $self = shift;
    return {
                'relevance'  => $self->relevance()
               ,'url'        => $self->url()
           } 
}

sub relevance { return $_[0]->_elem('result_relevance'); }
#  sub url () {} - identical to WWW::SearchResult.

# This gets the target document via HTTP GET, if needed.
sub response {
    my ($self) = @_;
    my $request = HTTP::Request->new(GET => $self->url());
    $self->{'_response'} = $self->{'searchObject'}->{'user_agent'}->request($request);
    return $self->{'_response'};
}


sub content {
    my ($self) = @_;

    my $response = $self->response();
    return $response->content() if $response->is_success;
    return undef;
}

sub toHTML {
    my ($self) = @_;
    
    my $result = "<DT>from:</DT><DD>".$self->{'searchObject'}->getName()."</DD>\n";
    my %results = %{$self->results()};
    my %resultTitles = %{$self->resultTitles()};
    
    for ( keys %resultTitles ) {
        $result .= "<DT>$resultTitles{$_}</DT><DD>$results{$_}</DD>\n";
    }
    return $result;
}


1;


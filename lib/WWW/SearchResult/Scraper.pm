package WWW::SearchResult::Scraper;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::SearchResult);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
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
    
    my $title = $self->title();
    my $description = $self->description();
    my $company = $self->_elem('company');
    my $location = $self->_elem('location');
    my $filename = $self->_elem('filename');
    my $relevance = $self->_elem('relevance');
    my $engineName = $self->_elem('engine');
    my $url = $self->url();
    # might handle 'relatedurl' later.
    $company .= '<BR>' if $company;
    
    return <<EOT;
<TABLE border="1" cellpadding="2" cellspacing="1"><TR><TD>
<A href="$url"><B>$title</B></A><BR>$description<BR>$company$location</TD>
<TD>Relevance: $relevance<BR>Engine: $engineName</TD>
</TR></TABLE>
EOT

}

1;


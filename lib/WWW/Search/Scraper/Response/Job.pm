package WWW::Search::Scraper::Response::Job;


=head1 NAME

WWW::Search::Scraper::Response::Job - result class for scrapes of Job Listings


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Search::Scraper::Response::Job> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Search::Scraper::Response);
use WWW::Search::Scraper::Response;
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $self = WWW::Search::Scraper::Response::new(
         'Job'
        ,{
             'relevance' => ''
            ,'title' => ''
            ,'description' => ''
            ,'companyProfileURL' => ''
            ,'company' => ''
            ,'location' => ''
            ,'postDate' => ''
            ,'url' => ''
         }
        ,@_);
    return $self;
}

sub FieldTitles {
    return {
                'relevance'  => 'Relevance'
               ,'title'      => 'Title'
               ,'description' => 'Description'
               ,'companyProfileURL'    => 'Company Profile URL'
               ,'company'    => 'Company'
               ,'location'   => 'Location'
               ,'postDate'   => 'Post-Date'
               ,'url'        => 'URL'
           };
}

1;


package WWW::Search::Scraper::Response::generic;


=head1 NAME

WWW::Search::Scraper::Response::generic - place holder.

For Response sub-class when no sub-class is declared. Not normally declared by client applications.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Search::Scraper::Response::generic> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use strict;
use vars qw($VERSION @ISA);
use lib './lib';
use WWW::Search::Scraper::Response;
@ISA = qw(WWW::Search::Scraper::Response);
#use base 'WWW::Search::Scraper::Response';
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $self = WWW::Search::Scraper::Response::new(
         'generic'
        ,@_);
    return $self;
}

1;


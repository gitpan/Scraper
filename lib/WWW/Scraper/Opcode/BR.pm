
use strict;

package WWW::Scraper::Opcode::BR;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of parames in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['content'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes('BR');
    return undef unless defined($sub_string);
    $hit->content(\$sub_string);

    return ($$scaffold[1], $sub_string);
}


1;

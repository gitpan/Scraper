
use strict;

package WWW::Scraper::Opcode::INPUT;
use base qw(WWW::Scraper::Opcode);
use vars qw($VERSION);

# new() Scraper::Opcode
#  $cls - Op class
#  $scaffold - current scaffold
#  $params - ref to array of params in the 'OP()' portion of the scaffold.
sub new {
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {};
    $self->{'fieldsDiscovered'} = ['name','type','value','caption'];
    return $self;
}

sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my $sub_string = $TidyXML->asString;
    return undef unless $$sub_string =~ s{<INPUT(\s*[^>]*)>([^<]*)}{}si;

    my $caption = $2;
    chomp $caption;
    
    my $attributes = $TidyXML->Attributes($1);
    
    return ($$scaffold[1], $$sub_string, $attributes);
}

1;

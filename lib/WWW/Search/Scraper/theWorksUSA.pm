
package WWW::Search::Scraper::theWorksUSA;

=pod

=head1 NAME

WWW::Search::Scraper::guru - class for searching guru


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('guru');


=head1 DESCRIPTION

This class is an guru specialization of WWW::Search.
It handles making and interpreting guru searches
F<http://www.guru.com>.


=head1 OPTIONS

None at this time (2001.05.06)

=over 8

=item search_url=URL

Specifies who to query with the guru protocol.
The default is at
C<http://www.guru.com/guru.jhtml>.

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::guru> is written and maintained
by Glenn Wood, <glenwood@dnai.com>.

The best place to obtain C<WWW::Search::guru>
is from Martin Thurn's WWW::Search releases on CPAN.
Because guru sometimes changes its format
in between his releases, sometimes more up-to-date versions
can be found at
F<http://alumni.caltech.edu/~glenwood/SOFTWARE/index.html>.


=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(1.34 generic_option addURL trimTags));
require WWW::SearchResult;

use HTML::Form;
use HTTP::Cookies;

use strict;


sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
	    'scraperForm_url' => ['http://www.theworksusa.com/template/jobsearch/jobsearch.cfm?appid=1', '#0', 'UserQuery', undef]
        };
    };
    
    $self->cookie_jar(HTTP::Cookies->new());
    
    my $response = $self->http_request('GET', $self->{_options}{'scraperForm_url'}[0]);
    unless ( $response->is_success ) {
        print $response->error_as_HTML();
        return undef;
    };
   
    my @forms = HTML::Form->parse($response->content(), $response->base());
    
    my $form;
    my $formIdx = $self->{_options}{'scraperForm_url'}[1];
    if ( $formIdx =~ m/^#(\d+)$/ )
    {
        $form = $forms[$1];
    } else {
        for ( @forms ) {
            if ( $_->getName() =~ m/$formIdx/i ) {
                $form = $_;
                last;
            }
        }
    }
    $self->{'_http_method'} = $form->method();

    $self->{'_options'}{'scrapeFrame'} = 
        [ 'HTML', 
          [ 
            [ 'COUNT', '>(\d+)</font> matching record' ]
           ,[ 'NEXT', 2, \&getNextPage ]
           ,[ 'TABLE', '#0',
              [
                [ 'TR', '#0' ] # The first row is column titles.
               ,[ 'HIT*' ,
                  [  
                    [ 'TD', 'relevance', \&trimLFs ]
                   ,[ 'TD', 'company',   \&trimLFs ]
                   ,[ 'TD', [ [ 'A', 'url', 'title', \&trimLFs ] ] ] 
                   ,[ 'TD', 'salary',   \&trimLFs ]
                   ,[ 'TD', 'location', \&trimLFs ]
                   ,[ 'TD', 'postDate', \&trimLFs ]
                  ]
                ]
              ] 
            ] 
          ]
        ];
 
    my($options_ref) = $self->{_options};
    if (defined($native_options_ref)) {
    	# Copy in new options.
    	foreach (keys %$native_options_ref) {
    	    $options_ref->{$_} = $native_options_ref->{$_};
    	};
    };
    # Process the options.
    # (Now in sorted order for consistency regarless of hash ordering.)
    my($options) = '';
    foreach (sort keys %$options_ref) {
    	# printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    	next if (generic_option($_));
    	$options .= $_ . '=' . $options_ref->{$_} . '&';
    };
    $self->{_debug} = $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Finally figure out the url.
    return undef unless $form;

    my $query = $form->find_input($self->{_options}{'scraperForm_url'}[2]);
    return undef unless $query;
    $query->value($native_query);

    my $submit_button = $form->find_input($self->{_options}{'scraperForm_url'}[3], 'submit');
    $submit_button = $form->find_input($self->{_options}{'scraperForm_url'}[3], 'image') unless $submit_button;
    my $req = $submit_button->click($form); #
    $self->{_options}{'scraperRequest'} = $req;

    $self->{'search_method'} = $form->method();
    my $url = $req->uri();
    $url .= '&'.$req->content() if $self->{'search_method'} eq 'POST' ;

    $self->{_base_url} = $self->{_next_url} = $url;
    print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
}


# theWorksUSA does not have a NEXT button!
# We need to get the next page via the 1.2.3.4... menu.
sub getNextPage {
    my ($self, $hit, $dat) = @_;
    my $url = $self->{'_last_url'};
    $url =~ m/CurrentPage=(\d+)/;
    my $pgNum = $1 + 1;
    $url =~ s/CurrentPage=(\d+)/CurrentPage=$pgNum/;
    return $url;
}

sub trimLFs { # Strip LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    $dat =~ s/\n//gs;
   # This simply rearranges the parameter list from the datParser form.
    return $self->trimTags($hit, $dat);
}

sub trimLFLFs { # Strip double-LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    while ( $dat =~ s/\n\n/\n/s ) {}; # Do several times, rather than /g, to handle triple, quadruple, quintuple, etc.
   # This simply rearranges the parameter list from the datParser form.
    return $self->trimTags($hit, $dat);
}

1;

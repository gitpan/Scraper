
package WWW::Search::Scraper::Google;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(generic_option addURL trimTags));

use LWP::UserAgent;
use HTML::Form;

use strict;

my $defaultScraperForm_url = ['http://www.Google.com', 'q', 'btnG', undef];

sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $$defaultScraperForm_url[0] = $_->{'scraperBaseURL'};
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
}


sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->{'_options'}{'scraperQuery'} =
    [ 'FORM'       # 
      # This is the basic URL on which to get the form to build the query.
     ,$defaultScraperForm_url
      # This names the native input field to recieve the query string.
        ,{  
            'nativeQuery' => 'q' # This is for non-Request type queries (ala Search.pm)
           ,'nativeDefaults' => { }
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {    'skills'    => 'q'
   #                            ,'payrate'   => undef
   #                            ,'locations' => new WWW::Search::Scraper::FieldTranslation('NorthernLight', 'Job', 'locations')
                               ,'native_query' => 'q'
                               ,'*'         => '*'
                           }
                   }
         }
         # Some more options for the Scraper operation.
        ,{'cookies' => 0
         }
       ];
    $self->{'_http_method'} = 'GET';

    $self->{'_options'}{'scrapeFrame'} = 
       [ 'HTML', 
          [ 
                  [ 'NEXT', 1, '[^>]>Next<' ], # Google keeps changing their formatting, so watch out!
                  [ 'COUNT', '[,0-9]+</b> of about <b>([,0-9]+)</b>'] ,
                  [ 'TABLE', '#4' ],
                  [ 'HIT*' ,
                    [  
                       [ 'BODY', '<p>', '</font></font>',
                          [
                              [ 'AN', 'url', 'title' ],
                              [ 'REGEX', '<font size=-1>(.*?)<br>', 'description'],
                              [ 'AN', 'cachedURL', 'cached' ],
                              [ 'AN', 'relatedURL', 'related' ]
                          ]
                       ]
                    ]
                  ]
           ]
       ];

    # WWW::Search::Scraper understands all that and will setup the search.
    return $self->SUPER::native_setup_search(@_);

} # native_setup_search


{ package WWW::Search::Scraper::Response;

sub moreResults {
    return $_[0]->_elem('moreResults', $_[1]);
}
}

1;


__END__
=pod

=head1 NAME

WWW::Search::Scraper::Google - class for searching www.Google.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('Google');


=head1 DESCRIPTION

This class is an Google specialization of WWW::Search.
It handles making and interpreting Google searches
F<http://www.Google.com>.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::Google> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut




package WWW::Search::Scraper::Google;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(2.27 generic_option addURL trimTags));

use strict;

my $scraperRequest = 
        { 
            # This engine is driven from it's <form> page
            'type' => 'FORM'
            ,'formNameOrNumber' => 0 # name=f, without quotes - Scraper needs a little work to make that ok.
            ,'submitButton' => 'btnG'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'http://www.Google.com'

           # specify defaults, by native field names
           ,'nativeQuery' => 'q'
           ,'nativeDefaults' => { 'hl' => 'en' }
            
            # specify translations from canonical fields to native fields
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {    'skills'    => 'q'
                               ,'*'         => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
       };

my $scraperFrame =
       [ 'HTML', 
          [ 
                  [ 'NEXT', 1, '[^>]>Next<' ], # Google keeps changing their formatting, so watch out!
                  [ 'COUNT', '[,0-9]+</b> of about <b>([,0-9]+)</b>'] ,
                  [ 'TABLE', '#4' ],
                  [ 'HIT*',
                    [  
                       [ 'BODY', '<p>', '</font></font>',
                          [
                              [ 'AN', 'url', 'title' ],
                              [ 'REGEX', '<font size=-1>(.*?)<br>', 'sampleText'],
                              [ 'REGEX', '<font size=-1>Description:(.*?)<br>', 'description'],
                              [ 'BODY',  '<span class=f>.*?Category:', '<br>',
                                [
                                  [ 'AN', 'categoryURL',  'category' ]
                                ]
                              ],
                              [ 'AN', 'cachedURL',  undef ],
                              [ 'AN', 'similarPagesURL', undef ]
                          ]
                       ]
                    ]
                  ]
           ]
       ];






sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => '' 
                ,'testNativeQuery' => 'search scraper'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 41
                ,'expectedBogusPage' => 1
           };
}


sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $scraperRequest->{'url'} = $_->{'scraperBaseURL'};
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Search::Scraper::Google - Scrapes www.Google.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('Google');


=head1 DESCRIPTION

This class is an Google specialization of WWW::Search.
It handles making and interpreting Google searches
F<http://www.Google.com>.

=head1 INTERESTING

Go to http://www.Google.com and search for "search scraper"; as in 

http://www.Google.com/search?q=search+scraper&sourceid=opera&num=0&ie=utf-8&oe=utf-8

Interesting FIRST hit !

=head1 AUTHOR and CURRENT VERSION


C<WWW::Search::Scraper::Google> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut




package WWW::Scraper::Google;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(2.27 generic_option addURL trimTags));

use strict;

my $scraperRequest = 
{
     'fieldTranslations' => {
               '*' => {
                   '*' => '*'
                 }
             },
#http://www.google.com/search?hl=en&lr=&ie=UTF-8&oe=utf-8&safe=active&q=turntable&btnG=Google+Search                 'SKIP' => '' 
     'nativeDefaults' => {
            'q' => 'turntable',
            #'as_eq' => 'turntable',
            #'oe' => 'utf-8',
            #'as_q' => '',
            'lr' => '',
            'hl' => 'en',
            'btnG' => 'Google Search',
            'safe' => 'active',
            #'as_epq' => 'google com',
            #'as_sitesearch' => '',
            #'as_oq' => '',
            'ie' => 'UTF-8'
               },
     'nativeQuery' => undef,
     'url' => 'http://www.google.com/search?',
     'cookies' => 0,
     'type' => 'QUERY',
     'defaultRequestClass' => undef
   };

my $scraperFrame =
[ 'HTML', 
  [ 
    [ 'NEXT', 1, '[^>]>Next<' ], # Google keeps changing their formatting, so watch out!
    [ 'COUNT', '[,0-9]+</b> of about <b>([,0-9]+)</b>'] ,
    [ 'TABLE', '#4' ],
    [ 'DIV',
       [
              [ 'HIT*',
                [  
                  [ 'AN', 'url', 'title' ],
                  #[ 'REGEX', '<font size=-1>(.*?)<br>', 'sampleText'],
                  [ 'REGEX', 'Description:(.*?)<br>', 'description'],
                  [ 'REGEX', '<b>...</b>\s*(.*?)<br>', 'description'],
                  [ 'BODY',  'Category:', '<br>',
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
            ,'testNativeOptions' =>
                {
                   'q' => 'turntable',
                   'lr' => '',
                   'hl' => 'en',
                   'btnG' => 'Google Search',
                   'safe' => 'active',
                   'ie' => 'UTF-8'
                }
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
    goto &WWW::Scraper::import;
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Scraper::Google - Scrapes www.Google.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('Google');


=head1 DESCRIPTION

This class is an Google specialization of WWW::Search.
It handles making and interpreting Google searches
F<http://www.Google.com>.

=head1 INTERESTING

Go to http://www.Google.com and search for "search scraper"; as in 

http://www.Google.com/search?q=search+scraper&sourceid=opera&num=0&ie=utf-8&oe=utf-8

Interesting FIRST hit !

=head1 AUTHOR and CURRENT VERSION


C<WWW::Scraper::Google> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



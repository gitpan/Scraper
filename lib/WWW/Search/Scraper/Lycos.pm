
package WWW::Search::Scraper::Lycos;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(2.12 generic_option addURL trimTags removeScriptsInHTML));

use strict;

# Example query - http://search.lycos.com/main/default.asp?lpv=1&loc=searchhp&query=Perl
my $scraperQuery = 
        { 
            # This engine is driven from it's <form> page
            'type' => 'QUERY'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'http://search.lycos.com/main/default.asp?'

           # specify defaults, by native field names
           ,'nativeQuery' => 'query'
           ,'nativeDefaults' => { 'lpv' => 'q'
                                 ,'loc' => 'searchhp'
                                }
            
            # specify translations from canonical fields to native fields
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {    'skills'    => 'query'
                               ,'*'         => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
       };

my $scraperFrame =
       [ 'TidyXML', \&removeScriptsInHTML, 
          [ 
                  [ 'NEXT', 1, '[^>]>Next<' ],
                  [ 'COUNT', 'Showing\s+Results\s+<b>[\d-]+</b>\s+of\s+([\d,]+)'] ,
                  [ 'XPath', '/html/body/table[2]/tr[3]/td[2]/table[2]',
                    [
                      [ 'HIT*' ,
                        [
                          [ 'XPath', '/table/tr[hit()]',
                            [
                             [ 'XPath', '/tr', #/td[2]/table/tr/td[2]/table/tr/td',
                              [
                                [ 'A', 'url', 'description' ],
                                [ 'XPath', '/tr/td[2]/font', 'title' ],
                                [ 'XPath', '/tr/td[3]/i/font', 'urls' ]
                              ]
                             ]
                            ]
                          ]
#                         ,[ 'XPath', '/tr' ], # this one's a spacer between data rows.
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
             'isNotTestable' => 'test is not ready yet; gdw.2001.02.19'
            ,'testNativeQuery' => 'search scraper'
            ,'expectedOnePage' => 9
            ,'expectedMultiPage' => 11
            ,'expectedBogusPage' => 0
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Search::Scraper::Lycos - class for searching www.Lycos.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('Lycos');


=head1 DESCRIPTION

This class is an Lycos specialization of WWW::Search.
It handles making and interpreting Lycos searches
F<http://www.Lycos.com>.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::Scraper::Lycos> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



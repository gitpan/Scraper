
package WWW::Scraper::Lycos;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(2.12 generic_option addURL trimTags removeScriptsInHTML));

use strict;

# Example query - (old) http://search.lycos.com/main/default.asp?lpv=1&loc=searchhp&query=Perl
#                 (new) http://search.lycos.com/default.asp?lpv=1&loc=searchhp&tab=web&query=turntable
my $scraperRequest = 
        { 
            # This engine is driven from it's <form> page
            'type' => 'QUERY'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'http://search.lycos.com/default.asp?'

           # specify defaults, by native field names
           ,'nativeQuery' => 'query'
           ,'nativeDefaults' => { 'lpv' => '1'
                                 ,'loc' => 'searchhp'
                                 ,'tab' => 'web'
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
       [ 'TidyXML', \&removeScriptsInHTML, \&removeDescriptionTags,
          [ 
                  [ 'NEXT', 1, '<b>Next</b>' ]    #<b>Next</b>

                 ,[ 'COUNT', 'Showing\s+Results\s+<b>[\d-]+</b>\s+of\s+([\d,]+)']
                 ,[ 'FOR', 'allTables', '2..6',
                    [
                      [ 'XPath', '/html/body/table[2]/tr[3]/td[2]/table[for(allTables)]',
                        [
                          [ 'HIT*' ,
                            [
                              [ 'XPath', 'tr[hit() * 2]',
                                [
                                     [ 'XPath', 'td[2]/font/a/text()', 'title' ]
                                    ,[ 'XPath', 'td[2]/font/a/@href', 'url' ]
                                    ,[ 'XPath', 'td[2]', 'description' ]
#                                    ,[ 'XPath', 'td[2]/i/font', 'urls' ]
#                                    ,[ 'A', 'url', 'description' ],
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
            ]
       ];


# Lycos has <DESCRIPTION> opening tags, but no closing ones.
#  That seems pretty handy, but gets in the way of TidyXML.
sub removeDescriptionTags {
   my ($self, $hit, $xml) = @_;
   $$xml =~ s{- <DESCRIPTION>(.*?)</\s?DESCRIPTION>}{$1}gsi;
   $$xml =~ s{- <DESCRIPTION/>}{}gsi;
   return $xml;
}

sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return { 
             'TODO' => 'Lycos is not quite right . . .'
            ,'testNativeQuery' => 'turntable'
            ,'expectedOnePage' => 9
            ,'expectedMultiPage' => 20
            ,'expectedBogusPage' => 1
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Scraper::Lycos - Scrapes www.Lycos.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('Lycos');


=head1 DESCRIPTION

This class is an Lycos specialization of WWW::Search.
It handles making and interpreting Lycos searches
F<http://www.Lycos.com>.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::Lycos> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



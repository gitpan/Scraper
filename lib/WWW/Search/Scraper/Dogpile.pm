
package WWW::Search::Scraper::Dogpile;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Search::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Search::Scraper(qw(2.14 generic_option addURL trimTags findNextFormInXML));

use strict;

# Example query - http://search.lycos.com/main/default.asp?lpv=1&loc=searchhp&query=Perl
my $scraperQuery = 
        { 
            # This engine is driven from it's <form> page
            'type' => 'QUERY'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => 'http://search.dogpile.com/texis/search?'

           # specify defaults, by native field names
           ,'nativeQuery' => 'q'
           ,'nativeDefaults' => { 'Fetch.x' => '1'
                                 ,'Fetch.y' => '1'
                                 ,'geo' => 'no'
                                 ,'fs' => 'The Web'
                                }
            
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
       [ 'TidyXML', 
          [ 
             [ 'CLEANUP', \&removeEmptyPs ]
            ,[ 'BODY', '<table border="0">\s*<TR>\s*<TD>', '</TD>\s*</TR>\s*</TABLE>', 
                [
                   [ 'NEXT', 2, \&findNextFormInXML ]
                ]
             ]
            ,[ 'XML', 'html.body',
              [
                [ 'HIT*' ,
                  [
                    [ 'XML', 'p',
                      [
                         [ 'A', 'url', 'title' ]
                        ,[ 'XML', 'i', 'company' ]
                      ]
                    ],
                  ]
                ]
              ]
            ]
          ]
       ];


sub removeEmptyPs {
    my ($self, $hit, $xml) = @_;
    
    # remove empty <P/> tags, for Dogpile.pm
    $$xml =~ s-<p>\s*?</p>--gsi;
    $$xml =~ s-<p/>--gsi;
open TMP, ">Dogpile.xml";
print TMP $$xml;
close TMP;
    return $xml;
}



sub testParameters {
    my ($self) = @_;

    return {
                 'isNotTestable' => &WWW::Search::Scraper::TidyXML::isNotTestable() 
                ,'testNativeQuery' => 'Scraper'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 50
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
            $scraperQuery->{'url'} = $_->{'scraperBaseURL'};
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }

1;


__END__
=pod

=head1 NAME

WWW::Search::Scraper::Dogpile - class for searching www.Dogpile.com


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    $search = new WWW::Search::Scraper('Dogpile');


=head1 DESCRIPTION

This class is an Dogpile specialization of WWW::Search.
It handles making and interpreting Dogpile searches
F<http://www.Dogpile.com>.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::Scraper::Dogpile> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



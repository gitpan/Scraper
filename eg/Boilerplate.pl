
use strict;
my $scraperName = 'Sample';
my $searchEngineName = 'www.Sample.com';
my $scraperQuery = 'http://search.Sample.com/search?';
my $scraperMethod = 'QUERY';
my $scraperNativeQuery = 'query';
my $defaultRequestClass = 'undef';
my $scraperCookies = 0;
my $AuthorName = 'Glenn Wood';
my $AuthorContactInfo = 'http://search.cpan.org/search?mode=author&query=GLENNWOOD';


open PM, ">$scraperName.pm" or die "Can't open $scraperName.pm to write: $!\n";

print PM <<EOT;
package WWW::Search::Scraper::$scraperName;


#####################################################################

\@ISA = qw(WWW::Search::Scraper Exporter);
# This is an appropriate VERSION calculation to use for CVS revision numbering.
\$VERSION = sprintf("%d.%02d", q\$Revision: 1.2 $ \=\~ /(\\d+)\.(\\d+)/);

use WWW::Search::Scraper(qw(2.19 generic_option trimLFs trimTags findNextFormInXML removeScriptsInHTML trimXPathHref));

use strict;

my \$scraperRequest = 
        { 
            # This engine's method is $scraperMethod
            'type' => '$scraperMethod'
            
            # This is the basic URL on which to get the form to build the query.
            ,'url' => '$scraperQuery'

           # specify defaults, by native field names
           ,'nativeQuery' => '$scraperNativeQuery'
           ,'nativeDefaults' => {
                                  'submit.x' => '1'
                                 ,'submit.y' => '1'
                                }
            
            # specify translations from canonical fields to native fields
           ,'defaultRequestClass' => '$defaultRequestClass'
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {
                                '*'         => '*'
                           }
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => $scraperCookies
       };

my \$scraperFrame =
       [ 'TidyXML', \\&removeScriptsInHTML, \\&removeEmptyPs, \\&removeDuplicateAttributes,
          [ 
            [ 'XPath', '/html/body',
              [
                [ 'HIT*' ,
                  [
                    [ 'XPath', 'p[hit()]',
                      [
                         [ 'XPath', 'a/\@href', 'url', \\&trimXPathHref ]
                        ,[ 'XPath', 'a/text()', 'title', \\&trimLFs ]
                        ,[ 'XPath', 'i', 'company', \\&trimTags ]
                      ]
                    ],
                  ]
                ]
              ]
            ]
           ,[ 'BODY', '<table border="0">\\s*<TR>\\s*<TD>', '</TD>\\s*</TR>\\s*</TABLE>', 
                [
                   [ 'NEXT', 2, \&findNextFormInXML ]
                ]
             ]

          ]
       ];


sub removeDuplicateAttributes {
    my (\$self, \$hit, \$xml) = \@_;
    \$\$xml =~ s-alt=""--gs; # this one appears from $scraperName.com
    return \$xml;
}

sub removeEmptyPs {
    my (\$self, \$hit, \$xml) = \@_;
    
    # remove empty <P/> tags
    \$\$xml =~ s-<p>\\s*?</p>--gsi;
    \$\$xml =~ s-<p/>--gsi;
    return \$xml;
}



sub testParameters {
    my (\$self) = \@_;

    if ( ref \$self ) {
        \$self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => &WWW::Search::Scraper::TidyXML::isNotTestable()
                ,'TODO' => ''
                ,'testNativeQuery' => 'turntable'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 11
                ,'expectedBogusPage' => 0
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { \$scraperRequest }
sub scraperFrame { \$_[0]->SUPER::scraperFrame(\$scraperFrame); }
sub scraperDetail { undef }

1;


__END__
=pod

=head1 NAME

WWW::Search::Scraper::$scraperName - Scrapes $searchEngineName


=head1 SYNOPSIS

    require WWW::Search::Scraper;
    \$search = new WWW::Search::Scraper('$scraperName');


=head1 DESCRIPTION

This class is an $scraperName specialization of WWW::Search.
It handles making and interpreting $scraperName searches.

=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::Scraper::$scraperName> is written and maintained
by $AuthorName, $AuthorContactInfo.

=head1 COPYRIGHT

Copyright (c) 2002 $AuthorName
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

EOT

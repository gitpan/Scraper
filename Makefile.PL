
# $Name:  $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Scraper',
    'VERSION_FROM' => "README", # finds $VERSION
    'PREREQ_PM' => { 'WWW::Search' => 2.15
                    ,'HTML::Form' => 0.02
                    ,'Text::ParseWords' => 3.2
                   },
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood <glenwood@alumni.caltech.edu>',
                     'ABSTRACT' => 'Scrape data from web search engines',
                    ) : (),
);



# $Name:  $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Scraper',
    'VERSION_FROM' => "README", # finds $VERSION
    'PREREQ_PM' => { 'WWW::Search' => 2.16
                    ,'HTML::Form' => 0.02
                    ,'HTTP::Cookies' => 1.11
                    ,'Text::ParseWords' => 3.2
                   },
    'INSTALLDIRS' => 'site',
    'PM' => {'Scraper.pm'   => 'lib/WWW/Search/Scraper.pm'
            ,'Sherlock.pm'  => 'lib/WWW/Search/Sherlock.pm'
            ,'BAJobs.pm'    => 'lib/WWW/Search/Scraper/BAJobs.pm'
            ,'CraigsList.pm' => 'lib/WWW/Search/Scraper/CraigsList.pm'
            ,'Dice.pm'      => 'lib/WWW/Search/Scraper/Dice.pm'
            ,'eBay.pm'      => 'lib/WWW/Search/Scraper/eBay.pm'
            ,'Google.pm'    => 'lib/WWW/Search/Scraper/Google.pm'
            ,'HotJobs.pm'   => 'lib/WWW/Search/Scraper/HotJobs.pm'
            ,'JustTechJobs.pm' => 'lib/WWW/Search/Scraper/JustTechJobs.pm'
            ,'Monster.pm'   => 'lib/WWW/Search/Scraper/Monster.pm'
            },
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood <glenwood@alumni.caltech.edu>',
                     'ABSTRACT' => 'Scraper data from web search engines',
                    ) : (),
    'dist'	=> { 'TAR' => 'tar', 'TARFLAGS' => 'cvfz', 'SUFFIX' => '.gz', 'COMPRESS' => 'renameTAR'}
);


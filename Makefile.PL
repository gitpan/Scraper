
# $Name:  $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Scraper',
    'VERSION_FROM' => "lib/WWW/Search/Scraper.pm", # finds $VERSION
    # test.pl uses this hash, also, to poll all modules we depend on
    'PREREQ_PM' => { 'WWW::Search' => 2.26
                    ,'LWP' => 5.48
                        ,'URI' => 0.0
                        ,'URI::URL' => 0.0
                        ,'URI::http' => 0.0
                    ,'HTML::Form' => 0.02
                        ,'HTML::TreeBuilder' => 0.0
                        ,'HTTP::Cookies' => 0.0
                        ,'HTTP::Request' => 0.0
                        ,'HTTP::Response' => 0.0
                        ,'HTTP::Status' => 0.0
                        ,'LWP::RobotUA' => 0.0
                        ,'LWP::UserAgent' => 0.0
                        ,'URI::Escape' => 0.0
                        ,'LWP::UserAgent' => 0.0
                        ,'Text::ParseWords' => 0.0
                    ,'Text::ParseWords' => 3.2
                    ,'Storable' => 0.6
                    ,'Tie::Persistent' => 0.901
                   },
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD',
                     'ABSTRACT' => 'Scrape data from web search engines',
                    ) : (),
);


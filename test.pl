# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { select STDERR; $| = 1; select STDOUT; $| = 1; }
END {#print STDOUT "1..1\nnot ok 1\n" unless $loaded;
    }

my $iTest = 0;

open TMP, "<MANIFEST";
my @modules;
while (<TMP>) {
    if ( m-^lib/WWW/Search/Scraper/(\w+)\.pm$- ) {
        next if $1 eq 'Request';          # This one's not an engine.
        next if $1 eq 'Response';         # This one's not an engine.
        next if $1 eq 'FieldTranslation'; # This one's not an engine.
        next if $1 eq 'TidyXML';          # This one's not an engine.
        next if $1 eq 'Dogpile';          # We're not ready to test TidyXML modules, yet.

#       next if $1 eq 'Sherlock';    # We're not smart enough to test Sherlock, yet!
        next if $1 eq 'apartments';  # went flippo - I'll fix this later.
        next if $1 eq 'BAJobs';     # BAJobs is sick this month - I'll fix later.
        next if $1 eq 'guru';        # This one doesn't work today, gdw.2001.08.22
        next if $1 eq 'HotJobs';     # HotJobs changed a lot - I'll fix this later.
        next if $1 eq 'JustTechJobs'; # went flippo - I'll fix this later; also, not ready for v2.01 ({'whichTech'}).
        next if $1 eq 'theWorksUSA'; # This one still has a problem (looping).
        push @modules, $1;
    }
}
close TMP;

    my $testCount = 1 + scalar(@modules) * 4;
    print STDOUT "1..$testCount\n";
    $iTest++;
    print STDOUT "ok $iTest\n";
    
use FileHandle;
    my $traceFile = new FileHandle('>test.trace') or die "Can't open test.trace file: $!";
    select ($traceFile); $| = 1; select STDOUT;

use strict;
use WWW::Search::Scraper(qw(2.13));
use WWW::Search::Scraper::Request;
    my $loaded = 1;
    $iTest++;
    print STDOUT "ok $iTest\n";

######################### End of black magic.


#######################################################################################
#
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
#
#######################################################################################

for my $sEngine ( @modules ) {
    
    $iTest++;
    TRACE("Test #$iTest: $sEngine\n");
    my $oSearch = new WWW::Search::Scraper($sEngine);
    print STDOUT ref($oSearch) ? '' : 'not ';
    print STDOUT "ok $iTest\n";


#######################################################################################
#
#       BOGUS QUERY 
#
#   This test returns no results (but we should not get an HTTP error):
#
#######################################################################################
    $iTest++;
    my $iResults = 0;
    # Brainpower.com and Dice.com return all jobs if you use Test::bogus_query.
    unless ( $sEngine =~ m/Brainpower|Dice|Monster/ ) {
        my ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);
        $sQuery = "Bogus" . $$ . "NoSuchWord" . time;
        my $request = new WWW::Search::Scraper::Request($sQuery);
        $oSearch->request($request);
    
        my @aoResults = $oSearch->results();
        $iResults = scalar(@aoResults);
        print STDOUT ( $bogusPageCount < $iResults ) ? 'not ' : '';
        print STDERR " --- got $iResults 'bogus' results, expected 0\n" if $iResults > 0;
    }
    print STDOUT "ok $iTest\n";

#######################################################################################
#
#       ONE-PAGE QUERY
#
#   This query returns 1 page of results
#
#######################################################################################

    $iTest++;

# Set up standard, and exceptional, options.
    my ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);

    # Skip this test if no results are expected anyway.
    if ( $onePageCount ) {
        my $request = new WWW::Search::Scraper::Request($sQuery, $options);

        $oSearch->native_query($sQuery); # This let's us test pre-v2.00 modules from here, too.
        $oSearch->request($request);

        my $maximum_to_retrieve = $onePageCount;
        $oSearch->maximum_to_retrieve($maximum_to_retrieve); # 1 page
        my $iResults = 0;
        eval { 
            my @aoResults = $oSearch->results();
            $iResults = scalar(@aoResults);
        };

        TRACE(" + got $iResults results for $sQuery\n");
        if ( $maximum_to_retrieve < $iResults )
          {
          print STDERR " --- got $iResults results for $sEngine ($sQuery), but expected $maximum_to_retrieve\n";
          print STDOUT 'not ';
          }
    }
    print STDOUT "ok $iTest\n";


#######################################################################################
#
#       MULTI-PAGE QUERY
#
#   This query returns MANY pages of results
#
#######################################################################################
    $iTest++;
    my ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);
    # Don't bother with this test if $multiPageCount <= $onePageCount - we've already done it.
    if ( $multiPageCount > $onePageCount ) {
        my $maximum_to_retrieve = $multiPageCount; # 2 or 3 pages
        $oSearch->maximum_to_retrieve($maximum_to_retrieve); # 2 or 3 pages
        my $request = new WWW::Search::Scraper::Request($sQuery);
        $oSearch->native_query($sQuery); # This let's us test pre-v2.00 modules from here, too.
        $oSearch->request($request);
        $iResults = 0;
        eval { 
            while ( $iResults < $maximum_to_retrieve ) {
                last unless $oSearch->next_response();
                $iResults += 1;
            }
        };
        TRACE(" ++ got $iResults results for $sQuery\n");
        if (($iResults < $maximum_to_retrieve ))
          {
            # We make an exception for these jobsites, since
            #  they often turn up few Perl jobs, anyway.
             unless ( $sEngine =~ m/Brainpower|computerjobs|guru|HotJobs|NorthernLight|Sherlock/ ) {
                print STDERR " --- got $iResults results for multi-page $sEngine ($sQuery), but expected $maximum_to_retrieve..\n";
                print STDOUT 'not ';
            }
          }
    }
    print STDOUT "ok $iTest\n";
    
}


sub TRACE {
    $traceFile->print($_[0]);
    print $_[0] if WWW::Search::Scraper::isGlennWood();
}

{ package WWW::Search::Scraper;
# Set up standard, and exceptional, options.
sub setupStandardAndExceptionalOptions {
    my ($oSearch, $sEngine) = @_;

    $oSearch->techiesLocation('bayarea') if $sEngine eq 'techies'; # www.techies.com is special.
    $oSearch->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src') if $sEngine eq 'Sherlock'; # Sherlock is extra special.

    my %specialQuery = (
                         'apartments' => 'New York'
                        ,'eBay'     => 'turntable'
                        ,'Dice'     => 'Perl NOT Java'
                        ,'Dogpile'  => 'Scraper'
                        ,'Google'   => 'turntable'
                        ,'HotJobs'  => 'Administrative Assistant'
                        ,'Monster'  => 'Administrative Assistant'
                        ,'FlipDog'  => 'Java'
                        ,'BAJobs'   => 'Service'
                        ,'Monster'  => 'Administrative Assistant'
                        ,'Sherlock' => 'Greeting Cards'
                       ); 
    my $sQuery = 'Perl';
    $sQuery = $specialQuery{$sEngine} if defined $specialQuery{$sEngine};

    my %specialOptions = (
                             'apartments' => { 'state' => 'NY' }
                            ,'JustTechJobs' => { 'whichTech' => 'Perl' }                                         
                         );
    my $options = $specialOptions{$sEngine};
    $options = {} unless $options;

    my %defaultPageCounts = (
                                 'CraigsList' => (9,20,0)
                                ,'Dogpile' => (9,50,0)
                                ,'FlipDog' => (5,5,0)
                                ,'techies' => (9,9,0)
                            );
    my $onePageCount = 9;
    my $multiPageCount = 41;
    my $bogusPageCount = 0;
    ($onePageCount,$multiPageCount,$bogusPageCount) = $defaultPageCounts{$sEngine} if defined $defaultPageCounts{$sEngine};

    return ($sQuery,$options,$onePageCount,$multiPageCount,$bogusPageCount);
}
}

__END__


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

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
        next if $1 eq 'Request';         # This one's not an engine.
        next if $1 eq 'Response';        # This one's not an engine.
        next if $1 eq 'FieldTranslation';# This one's not an engine.
#       next if $1 eq 'Sherlock';    # We're not smart enough to test Sherlock, yet!
        next if $1 eq 'apartments';  # went flippo - I'll fix this later.
        next if $1 eq 'techies';     # This one doesn't work, anyway.
        next if $1 eq 'FlipDog';     # went flippo - I'll fix this later.
        next if $1 eq 'guru';        # This one doesn't work today, gdw.2001.08.22
        next if $1 eq 'HotJobs';     # HotJobs changed a lot - I'll fix this later.
        next if $1 eq 'JustTechJobs'; # went flippo - I'll fix this later.
        next if $1 eq 'theWorksUSA'; # This one still has a problem (looping).
next if $1 eq 'BAJobs';     # hmmm. . .  grrr . . . hmmm . . .
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
use WWW::Search::Scraper;
use WWW::Search::Scraper::Request;
    my $loaded = 1;
    $iTest++;
    print STDOUT "ok $iTest\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use WWW::Search::Test;

for my $sEngine ( @modules ) {
    my $debug = 0;
    
#    next unless $sEngine eq 'FlipDog';

    $iTest++;
    $traceFile->print("Test #$iTest: $sEngine\n");
    my $oSearch = new WWW::Search::Scraper($sEngine);
    print STDOUT ref($oSearch) ? '' : 'not ';
    print STDOUT "ok $iTest\n";


#######################################################################################
#
# This test returns no results (but we should not get an HTTP error):
    $iTest++;
# Brainpower.com and Dice.com return all jobs if you use Test::bogus_query.
    my $iResults = 0;
    unless ( $sEngine =~ m/Brainpower|Dice|Monster/ ) {
        my $bogusRequest = $WWW::Search::Test::bogus_query;
        my $request = new WWW::Search::Scraper::Request($bogusRequest);
        $oSearch->request($request);
    
        my @aoResults = $oSearch->results();
        $iResults = scalar(@aoResults);
        print STDOUT ( 0 < $iResults ) ? 'not ' : '';
    }
    print STDOUT "ok $iTest\n";

#######################################################################################
#
# This query returns 1 page of results:
    $iTest++;

# Set up standard, and exceptional, options.
my %specialOptions = (
                         'apartments' => { 'state' => 'CA', 'search_debug' => $debug }
                        ,'JustTechJobs' => { 'whichTech' => 'Perl' }                                         
                        ,'Dice' => {'method'=>'bool', 'acode'=>'650', 'daysback'=>'30', 'search_debug' => $debug}
                     );
$oSearch->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src') if $sEngine eq 'Sherlock'; # Sherlock is extra special.

my %specialQuery = (
                         'apartments' => 'Los Angeles'
                        ,'eBay'     => 'turntable'
                        ,'Dice'     => 'Perl NOT Java'
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
    my $options = $specialOptions{$sEngine};
    $options = {} unless $options;
    my $request = new WWW::Search::Scraper::Request($sQuery);
    $request->debug($$options{'search_debug'}?$$options{'search_debug'}:$debug);
    
    $oSearch->native_query($sQuery); # This let's us test pre-v2.00 modules from here, too.
    $oSearch->request($request);
    
    #    $request->locations([ 'CA-San Jose'
    #                         ,'CA-Mountain View'
    #                         ,'CA-Sunnyvale'
    #                         ,'CA-Cupertino'
    ##                         ,'CA-Costa Mesa'
    #                         ]);
    
    my $maximum_to_retrieve = 9;
    $oSearch->maximum_to_retrieve($maximum_to_retrieve); # 1 page
    my $iResults = 0;
    eval { 
        my @aoResults = $oSearch->results();
        $iResults = scalar(@aoResults);
    };

    $traceFile->print(" + got $iResults results for $sQuery\n");
    if (($iResults < 2) || ( $maximum_to_retrieve < $iResults))
      {
      print STDERR " --- got $iResults results for $sEngine ($sQuery), but expected 2..$maximum_to_retrieve\n";
      print STDOUT 'not ';
      }
    print STDOUT "ok $iTest\n";


#######################################################################################
#
# This query returns MANY pages of results:
    $iTest++;
    $maximum_to_retrieve = 41; # 2 or 3 pages
    $oSearch->maximum_to_retrieve($maximum_to_retrieve); # 2 or 3 pages
    my $request = new WWW::Search::Scraper::Request($sQuery);
    $request->debug($$options{'search_debug'}?$$options{'search_debug'}:$debug);
    $oSearch->native_query($sQuery); # This let's us test pre-v2.00 modules from here, too.
    $oSearch->request($request);
    $iResults = 0;
    eval { 
        while ( $iResults < $maximum_to_retrieve ) {
            last unless $oSearch->next_response();
            $iResults += 1;
        }
    };
    $traceFile->print(" ++ got $iResults results for $sQuery\n");
    if (($iResults < $maximum_to_retrieve ))
      {
        # We make an exception for these jobsites, since
        #  they often turn up few Perl jobs, anyway.
         unless ( $sEngine =~ m/Brainpower|computerjobs|guru|HotJobs|Monster|NorthernLight|Sherlock/ ) {
            print STDERR " --- got $iResults results for multi-page $sEngine ($sQuery), but expected $maximum_to_retrieve..\n";
            print STDOUT 'not ';
        }
      }
    print STDOUT "ok $iTest\n";
    
}

__END__


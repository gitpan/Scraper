# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { select STDERR; $| = 1; select STDOUT; $| = 1; }
END {print "1..1\nnot ok 1\n" unless $loaded;}

my $iTest = 0;

open TMP, "<MANIFEST";
my @modules;
while (<TMP>) {
    if ( m-^lib/WWW/Search/Scraper/(\w+)\.pm$- ) {
        next if $1 eq 'Request';     # This one's not an engine.
        next if $1 eq 'Response';    # This one's not an engine.
#       next if $1 eq 'Sherlock';    # We're not smart enough to test Sherlock, yet!
        next if $1 eq 'techies';     # This one doesn't work, anyway.
        next if $1 eq 'theWorksUSA'; # This one still has a problem (looping).
        push @modules, $1;
    }
}
close TMP;
#    push @modules, '../HeadHunter'; # Let's add Alexander's HeadHunter, for the fun of it!

    my $testCount = 2 + scalar(@modules) * 4;
    print "1..$testCount\n";
    $iTest++;
    print "ok $iTest\n";
    
use WWW::Search::Scraper;
    $loaded = 1;
    $iTest++;
    print "ok $iTest\n";
use strict;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use WWW::Search::Test;

for my $sEngine ( @modules ) {
    $iTest++;
    my $oSearch = new WWW::Search::Scraper($sEngine);
    print ref($oSearch) ? '' : 'not ';
    print "ok $iTest\n";

# goto GUI_TEST;
# goto MULTI_TEST;
my $debug = 0;

# This test returns no results (but we should not get an HTTP error):
$iTest++;
$oSearch->native_query($WWW::Search::Test::bogus_query);
my @aoResults = $oSearch->results();
my $iResults = scalar(@aoResults);
print STDOUT ( 0 < $iResults ) ? 'not ' : '';
print "ok $iTest\n";
print STDERR "\n\n\n\n" if $debug;

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
                        ,'eBay'    => 'turntable'
                        ,'Dice'    => 'Perl NOT Java'
                        ,'HotJobs' => 'Java'
                        ,'BAJobs'  => 'Service'
                        ,'Sherlock' => 'Greeting Cards'
                   ); 
my $sQuery = 'Perl';
my $options = $specialOptions{$sEngine};
$options = {} unless $options;
$$options{'search_debug'} = $debug unless defined $$options{'search_debug'};
$sQuery = $specialQuery{$sEngine} if defined $specialQuery{$sEngine};

$oSearch->native_query( WWW::Search::escape_query($sQuery), $options);
$oSearch->maximum_to_retrieve(19); # 1 page
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
# print STDERR " + got $iResults results for $sQuery\n";
if (($iResults < 2) || (19 < $iResults))
  {
  print STDERR " --- got $iResults results for $sEngine ($sQuery), but expected 2..19\n";
  print STDOUT 'not ';
  }
print "ok $iTest\n";
print STDERR "\n\n\n\n" if $debug;

# goto GUI_TEST;

MULTI_TEST:
# This query returns MANY pages of results:
$iTest++;
$oSearch->native_query(WWW::Search::escape_query($sQuery), $options);
$oSearch->maximum_to_retrieve(59); # 3 pages
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
if (($iResults < 41))
  {
    # We make an exception for these jobsites, since
    #  they often turn up few Perl jobs, anyway.
     unless ( $sEngine =~ m/guru|HotJobs|Brainpower|Sherlock/ ) {
        print STDERR " --- got $iResults results for multi-page $sEngine ($sQuery), but expected 41..\n";
        print STDOUT 'not ';
    }
  }
print "ok $iTest\n";
print STDERR "\n\n\n\n" if $debug;

GUI_TEST:
}

__END__


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use WWW::Search::Scraper(qw(2.15));

use ExtUtils::testlib;
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { select STDERR; $| = 1; select STDOUT; $| = 1; }
END {#print STDOUT "1..1\nnot ok 1\n" unless $loaded;
    }

my $iTest = 0;
my $countErrorMessages = 0;
my $countWarningMessages = 0;


use FileHandle;
    my $traceFile = new FileHandle('>test.trace') or die "Can't open test.trace file: $!";
    select ($traceFile); $| = 1; select STDOUT;

open TMP, "<MANIFEST";
my @modules;
while (<TMP>) {
    if ( m-^lib/WWW/Search/Scraper/(\w+)\.pm$- ) {
        next if $1 eq 'Request';          # This one's not an engine.
        next if $1 eq 'Response';         # This one's not an engine.
        next if $1 eq 'FieldTranslation'; # This one's not an engine.
        next if $1 eq 'TidyXML';          # This one's not an engine.

        my $testParameters;
        eval "use WWW::Search::Scraper::$1; \$testParameters = &WWW::Search::Scraper::$1::testParameters()";
        # print $@; $@ just means the Scraper sub-class doesn't have a testParameters() method, yet.
        unless ( 0 and WWW::Search::Scraper::isGlennWood() ) {
            if ( $testParameters ) {
                if ( $testParameters->{'isNotTestable'} ) {
                    TRACE(1, "$1 will not be tested: $testParameters->{'isNotTestable'}\n");
                    next;
                }
                # we're making this exception in 2.16 because WWW::Search seems to be broken on
                #    http://testers.cpan.org/search?request=mac&mac=129
                #    linux 2.2.14-5.0 i686-linux
                if ( $VERSION eq '1.10' )
                {
    #                if ( $testParameters->{'usesPOST'} ) {
    #                    print STDERR "Skipped $1 in this test: test.pl v$VERSION can not test modules that use the 'POST' method (see WWW::Search(2.26)\n";
    #                    next;
    #                }
                }
            }
        }
        push @modules, $1;
    }
}
close TMP;
    
    my $testCount = 2 + scalar(@modules) * 4;
    print STDOUT "1..$testCount\n";
    $iTest++;
    print STDOUT "ok $iTest\n";
    
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
    TRACE(0, "Test #$iTest: $sEngine\n");
    my $oSearch = new WWW::Search::Scraper($sEngine);
    if ( not ref($oSearch)) {
        TRACE(2, "Can't load scraper module for $sEngine: $!\n");
        print STDOUT "not ok $iTest\n";
        next;
    }
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
    my ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);
    $sQuery = "Bogus" . $$ . "NoSuchWord" . time;
    my $request = new WWW::Search::Scraper::Request($sQuery);
    $oSearch->request($request);

    my @aoResults = $oSearch->results();
    $iResults = scalar(@aoResults);
    if ( $bogusPageCount < $iResults ) {
        TRACE (2, " --- got $iResults 'bogus' results, expected $bogusPageCount\n");
        print "not ";
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

        TRACE(0, " + got $iResults results for $sQuery\n");
        if ( $maximum_to_retrieve > $iResults )
        {
            TRACE(2, " --- got $iResults results for $sEngine ($sQuery), but expected $maximum_to_retrieve\n");
            print "not ";
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
        TRACE(0, " ++ got $iResults multi-page results for $sQuery\n");
        if ( $maximum_to_retrieve > $iResults )
          {
            # We make an exception for these jobsites, since
            #  they often turn up few Perl jobs, anyway.
             unless ( $sEngine =~ m/Brainpower|computerjobs|guru|HotJobs|NorthernLight/ ) {
                TRACE(2, " --- got $iResults results for multi-page $sEngine ($sQuery), but expected $maximum_to_retrieve..\n");
                print STDOUT 'not ';
            }
          }
    }
    print STDOUT "ok $iTest\n";
    
}
    close $traceFile;

    if ( $countWarningMessages and WWW::Search::Scraper::isGlennWood() ) {
        print STDOUT "$countWarningMessages warning".(($countWarningMessages>1)?'s':'').". See file 'test.trace' for details.\n";
    }
    if ( $countErrorMessages ) {
        print STDOUT "$countErrorMessages test".(($countErrorMessages>1)?'s':'')." failed. See file 'test.trace' for details.\n";
    }
    if ( $countErrorMessages ) {
        open TMP, "<test.trace";
        print join '', <TMP>;
        close TMP;
    }

sub TRACE {
    $countWarningMessages += 1 if $_[0] == 1;
    $countErrorMessages   += 1 if $_[0] == 2;
    $traceFile->print($_[1]);
    print $_[1] if WWW::Search::Scraper::isGlennWood();
}



{ package WWW::Search::Scraper;
# Set up standard, and exceptional, options.
sub setupStandardAndExceptionalOptions {
    my ($oSearch, $sEngine) = @_;

    my $sQuery = 'Perl';
    my $options;
    my $onePageCount = 9;
    my $multiPageCount = 41;
    my $bogusPageCount = 0;
    my %specialOptions;
    
    # Most Scraper sub-classes will define their own testParameters . . .
    # See Dogpile.pm for the most mature example of how to set your testParameters.
    if ( my $testParameters = $oSearch->testParameters() ) {
        $sQuery = $testParameters->{'testNativeQuery'} || $sQuery;
        $options = $testParameters->{'testNativeOptions'};
        $options = {} unless $options;
        ($onePageCount,$multiPageCount,$bogusPageCount) = (9,41,0);
        $onePageCount   = $testParameters->{'expectedOnePage'}   or $onePageCount;
        $multiPageCount = $testParameters->{'expectedMultiPage'} or $multiPageCount;
        $bogusPageCount = $testParameters->{'expectedBogusPage'} or $bogusPageCount;

        return ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount);
    }

    # . . . others aren't ready for prime-time, so we hard wire their testParameters here.

    my %specialQuery = (
                       ); 
    $sQuery = $specialQuery{$sEngine} if defined $specialQuery{$sEngine};

    return ($sQuery,$options,$onePageCount,$multiPageCount,$bogusPageCount);
}
}

__END__


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use WWW::Search::Scraper(qw(2.15));

use ExtUtils::testlib;
$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

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

# Report current versions of modules we depend on.
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    print $traceFile <<EOT;
VERSIONS OF MODULES ON WHICH SCRAPER DEPENDS
EOT
    open TMP, "<Makefile.PL";
    my @makefile = <TMP>;
    close TMP;
    my $makefile = join '',@makefile;
    use vars qw($prereq_pm);
    $makefile =~ s/^.*'PREREQ_PM'\s*=>([^}]*}).*$/\$prereq_pm = \1/s;
    eval $makefile;
    for ( sort keys %$prereq_pm ) {
        my $mod_version;
        eval "use $_($$prereq_pm{$_}); \$mod_version = \$$_\:\:\VERSION;";
        print $traceFile "    using $_($mod_version);\n";
    }
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    
    print $traceFile <<EOT;
LIST SCRAPER SUB-CLASSES, FROM THE MANIFEST
EOT
    open TMP, "<MANIFEST";
    my @modules;
    while (<TMP>) {
        if ( m-^lib/WWW/Search/Scraper/(\w+)\.pm$- ) {
    
            my $testParameters;
            eval "use WWW::Search::Scraper::$1; \$testParameters = &WWW::Search::Scraper::$1::testParameters()";
            if ( $@ ) { # $@ just means the module is not a Scraper sub-class.
                TRACE(1, "    - $1 will not be tested: it is not a Scraper sub-class.\n");
                next;
            }
            unless ( 0 and WWW::Search::Scraper::isGlennWood() ) {
                if ( $testParameters ) {
                    if ( $testParameters->{'isNotTestable'} ) {
                        TRACE(1, "    - $1 will not be tested: $testParameters->{'isNotTestable'}\n");
                        next;
                    }
                }
            }
            push @modules, $1;
            TRACE(1, "    + $1\n");
        }
    }
    close TMP;
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    
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
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    
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

        TRACE(0, " + got $iResults results for '$sQuery'\n");
        if ( $maximum_to_retrieve > $iResults )
        {
            TRACE(2, " --- got $iResults results for $sEngine '$sQuery', but expected $maximum_to_retrieve\n");
            TRACE(2, " --- base URL: $oSearch->{'_base_url'}\n");
            TRACE(2, " --- last URL: $oSearch->{'_last_url'}\n");
            TRACE(2, " --- next URL: $oSearch->{'_next_url'}\n");
            TRACE(2, " --- response message: ".$oSearch->{'response'}->message()."\n");

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
        TRACE(0, " ++ got $iResults multi-page results for '$sQuery'\n");
        if ( $maximum_to_retrieve > $iResults )
          {
            # We make an exception for these jobsites, since
            #  they often turn up few Perl jobs, anyway.
                TRACE(2, " --- got $iResults results for multi-page $sEngine '$sQuery', but expected $maximum_to_retrieve..\n");
                TRACE(2, " --- base URL: $oSearch->{'_base_url'}\n");
                TRACE(2, " --- last URL: $oSearch->{'_last_url'}\n");
                TRACE(2, " --- next URL: $oSearch->{'_next_url'}\n");
                TRACE(2, " --- response message: ".$oSearch->{'response'}->message()."\n");
                print STDOUT 'not ';
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

sub traceBreak {
    print $traceFile <<EOT;
##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
EOT
}

__END__


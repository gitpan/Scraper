=pod

=head1 NAME

ZipPlus4Fixer.pl

=head1 Synopsis

Reads a spreadsheet (in .csv format), discovers the address columns
(by headers eq 'Address', 'City', 'State', and 'Zip'; see @HeaderCodes, case insensitive).
then writes it out with correct ZipPlus4 zip codes.

The output filename has ".ZipPlus4" inserted after the filename, before the extension.

This script eliminates lines that don't have all of Address, City, State and Zip.
(It should be enhanced to accept (Address, City and State) or (Address and Zip).)

This primitive form parses the CSV without Text::CSV - left as an exercise for the reader.

For best results, we need Address, City and State (or Zip instead of City and State).
Otherwise this script can not find the ZipPlus4 value.

=head1 AUTHOR

C<ZipPlus4Fixer.pl> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use WWW::Search::Scraper;
use WWW::Search::Scraper::ZIPplus4;
use WWW::Search::Scraper::Request::ZIPplus4;
use Getopt::Long;

# %HeaderCodes binds your column h
    
    
     eaders to address parameters.
#
#                    uc 'Your header' => 'address parameter'
my %HeaderCodes = (  'ADDRESS'     => 'colAddress'
                    ,'CITY'        => 'colCity'
                    ,'STATE'       => 'colState'
                    ,'ZIP'         => 'colZip'
                    ,'ZIP_VERIFIED'         => 'colZipVerified'
                  );
my %colNums; # To be filled in by "Discover headers" loop, below.
my ($dedupMethod, $dedupOnly, $noVerify) = ('..', 0, 0); # 'AddressDedup'; # See WWW::Search::Scraper::ZIPplus4.pm, where this class lives.
my @allAddresses;
my ($inFilename, $Verbose, $Version, $VERSION);

select STDERR; $| = 1; select STDOUT; $| = 1; 

    my %optionsList =
    print "\nDocSetCopy v$VERSION\n\n" if $Version;
    Usage(1) unless ( GetOptions(
                        (
                            'i=s'      => \$inFilename
                           ,'d:s'      => \$dedupMethod
                           ,'x!'      => \$dedupOnly
                           ,'y!'      => \$noVerify
                           ,'verbose!' => \$Verbose
                           ,'version!' => \$Version
                         ) ) and
                      $inFilename );

my $outFilename = $inFilename;
$outFilename =~ s/(.*)\.(\w+)$/$1.ZipPlus4.$2/; # convert filename.csv to filename.ZipPlus4.csv.


$dedupMethod = 'AddressDedup' if ( $dedupMethod eq '' ); # This lets -d default to 'AddressDedup'
$dedupMethod = '' if ( $dedupMethod eq '..' );
$outFilename =~ s{\.ZipPlus4\.}{.dedup.ZipPlus4.} if $dedupMethod;

open IN,  "<$inFilename"  or die "Can't open '$inFilename': $!";
open OUT, ">$outFilename" or die "Can't open '$outFilename': $!";
my $duplicateFilename = $inFilename;
$duplicateFilename =~ s/(.*)\.(\w+)$/$1.duplicates.$2/;
if ( $dedupMethod  ) { open DUP, ">$duplicateFilename" or die "Can't open '$duplicateFilename': $!"; }

# Discover headers loop
    my $i = 0;
    my $Header = <IN>;
    print OUT $Header;
    print DUP $Header if $dedupMethod;
    for my $colHeader ( split ',', $Header ) {
        for ( keys %HeaderCodes ) {
            if ( $colHeader =~ m{^$_$}i ) {
                $colNums{$HeaderCodes{$_}} = $i;
            }
        }
        $i += 1;
    }

    my $rowCount;
    ADDRESS:
    while ( <IN> ) {
        #last if $rowCount > 100;
        my $Adr = new $dedupMethod;
        $Adr->setValue(\%colNums, $_);
        
        # Eliminate empty lines.
        next if $Adr->isEmpty();
        
        if ( $dedupMethod ) {
            for ( @allAddresses ) {
                if ( $Adr->isEqual($_) ) {
                    print DUP "\n";
                    print DUP $_->asString()."\n";
                    print DUP $Adr->asString()."\n";
                    next ADDRESS;
                }
            }
            push @allAddresses, $Adr;
        }
        my $ZipPlus4;
    
        if ( $noVerify and $Adr->Zip =~ m/^\d\d\d\d\d-|\s+\d\d\d\d$/ ) { # if zip is already "nnnnn-nnnn" or "nnnnn nnnn"
            $ZipPlus4 = $Adr->Zip;
            print "ALREADY:  ".$Adr->asString()." => ".$ZipPlus4."\n" if $Verbose;
        }
        else {
            $Adr->Zip('') if ( $Adr->Zip !~ m/^\d\d\d\d\d((-|\s+)\d\d\d\d)?$/ ); # If not five/nine digits, then we don't know *what* it is.

            my $zip4 = new WWW::Search::Scraper('ZIPplus4');
            my $request = new WWW::Search::Scraper::Request::ZIPplus4;
            $request->Delivery_Address($Adr->Address);
            $request->City($Adr->City);
            $request->State($Adr->State);
            $request->Zip_Code($Adr->Zip);
            $zip4->SetRequest($request);
    
            if ( my @newZips = $zip4->responses() ) {
                if ( @newZips == 1 ) {
                    $ZipPlus4 = ${$newZips[0]->zip()};
                    print "FOUND:    ".$Adr->asString()." => $ZipPlus4\n" if $Verbose;
                } else {
                    $ZipPlus4 = $Adr->Zip;
                    if ( $Verbose ) {
                        print "FOUND TOO MANY: ".$Adr->asString()." => $ZipPlus4\n                ";
                        for ( @newZips ) { print ${$_->zip()}.","; }
                        print "\n";
                    }
                }
            } else {
                print "NOT FOUND: ".$Adr->asString()." => $ZipPlus4 ".$Adr->Zip()."\n" if $Verbose;
                $ZipPlus4 = $Adr->Zip;
            }
            $Adr->Zip($ZipPlus4);
        }
        print OUT $Adr->asString()."\n" if $Verbose;
        $rowCount += 1;
    }

    close OUT;
    close DUP if $dedupMethod;

    print STDOUT "$rowCount rows written.\n";



sub Usage {
die <<EOT

USAGE: ZipPlus4Fixer.pl -i=<csv filename> [ -d[=dedupMethod] ] [ -x ]
       
       -i - input file name.
       -d - dedup method (default is "AddressDedup" - see ZIPplus4.pm)
       -x - dedup only (don't lookup and correct zip codes)
       -y - "no verify" - if Zip is already 9 digits, then don't look it up again.
       
       Output goes to a file named after the -i parameter, by inserting "ZipPlus4" in.
       
       try 'ZipPlus4Fixer.pl -i=zipPlus4.csv', for example.
       
       Apologizes that none of these are real addresses - I wouldn't what to single anyone o...
       
EOT
}




package WWW::Search::Scraper::FlipDog;


#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.48 trimLFs trimLFLFs removeScriptsInXML));

sub resultsX
  {
  my $self = shift;
  print STDERR " + results(",$self->{'native_query'},")\n" if $self->{debug};
  Carp::croak "search not yet specified" if (!defined($self->{'native_query'}));
  # Put all the SearchResults into the cache:
  print "1\n" while ($self->retrieve_some());
  if ($#{$self->{cache}} >= $self->{maximum_to_retrieve})
    {
    return @{$self->{cache}}[0..($self->{maximum_to_retrieve}-1)];
    }
  else 
    {
    return @{$self->{cache}};
    }
  } # results

# SAMPLE
# http://www.flipdog.com/js/jobsearch-results.html?loc=CA-San+Jose+Area&cat=Computing%2FMIS-Software+Development&srch=Perl&job=1
my $scraperQuery = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
     # This is the basic URL on which to build the query.
     ,'url' => 'http://www.flipdog.com/js/jobsearch-results.html?'
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'srch'
     ,'nativeDefaults' =>
                      {    'loc' => 'CA-San Jose Area'
                          ,'cat' => 'Computing/MIS-Software Development'
                          ,'job' => '1'
                      }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'TidyXML', \&removeScriptsInXML, 
    [ 
        [ 'COUNT', 'var jobTotal = (\d+)' ]
       ,[ 'NEXT', \&getNextPage ]
       ,[ 'XML', 'html.body.table(5)', 
            [  
                [ 'HIT*', 'Job',
                    [ 
                        [ 'XML', 'tr' ] # waste one leading row . . .
                       ,[ 'XML', 'tr' ] # waste two leading rows . . .
                       ,[ 'XML', 'tr',
                            [
                                [ 'XML', 'td(3)', 
                                    [
                                        [ 'A', 'url', 'title', \&trimLFs ]
                                       ,[ 'A', 'companyProfileURL', 'company', \&trimLFs ]
                                       ,[ 'XML', 'div', 'description' ]
                                    ]
                                ]
                               ,[ 'TD', 'location', \&parseLocation ]
                               ,[ 'XML', 'td', 'postingDate' ]
                            ]
                        ]
                       ,[ 'XML', 'tr' ] # waste one trailing row . . .
                    ]
                ]
            ]
        ]
       ,[ 'XML', 'html.body.table(5)', 
            [  
                [ 'HIT*', 'Job',
                    [ 
                        [ 'XML', 'tr' ] # waste one leading row . . .
                       ,[ 'XML', 'tr' ] # waste two leading rows . . .
                       ,[ 'XML', 'tr',
                            [
                               [ 'XML', 'td(3)', 
                                [
                                   [ 'A', 'url', 'title', \&trimLFs ]
                                  ,[ 'A', 'companyProfileURL', 'company', \&trimLFs ]
                                ]
                              ,[ 'XML', 'div', 'description' ]
                            ]
                           ,[ 'TD', 'location', \&parseLocation ]
                           ,[ 'XML', 'td', 'postingDate' ]
                            ]
                        ]
                       ,[ 'XML', 'tr' ] # waste one trailing row . . .
                    ]
                ]
            ]
        ]
    ]
];


sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'isNotTestable' => &WWW::Search::Scraper::TidyXML::isNotTestable() 
                ,'testNativeQuery' => 'Java'
                ,'expectedOnePage' => 5
                ,'expectedMultiPage' => 11
                ,'expectedBogusPage' => 0
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }



##############################################################
# The text in this <TD> element are four lines representing
# postDate, location, jobCategory and jobType. Parse that here.
sub parseLocation {
    my ($self, $hit, $dat) = @_;
    $dat = $self->trimLFLFs($hit, $dat);
    $dat =~ m/\n(.*?)\n(.*?)\n(.*?)\n(.*)/s;
    $hit->_elem('postDate', $1);
#    $self->_elem('location', $2);
    $hit->_elem('jobCategory', $3);
    $hit->_elem('jobType', $4);
    return $2;
}


###############################################
#
# nextURL - calculate the next page's URL.
#
# Here is the JavaScript that FlipDog uses to
# create it's "More Results" link. So it's
# pretty obvious what we need to do!
#
# var jobCount = 25;
# var jobStart = 1;
# var jobTotal = 221;
# function PageResults( bNext )
# {
# var szQS = "";
# if ( bNext )
# szQS = document.location.search.replace( /&job=\d+/, "" ) + "&job=" + String(jobStart + jobCount);
# else
# szQS = document.location.search.replace( /&job=\d+/, "" ) + "&job=" + String(jobStart - jobCount);
# location.href = "/js/jobsearch-results.html" + szQS;
# }
sub getNextPage {
    my ($self, $hit, $dat) = @_;
    
    return undef unless $dat = $self->{'removedScripts'};
    return undef unless 
        $$dat =~ m/var jobCount = (\d+).*?var jobStart = (\d+).*?var jobTotal = (\d+)/s;
    my ($jobCount, $jobStart, $jobTotal) = ($1,$2,$3);
    my $url = $self->{'_last_url'};
    $jobStart += $jobCount;
    return undef if $jobStart > $jobTotal; # (not represented in the JavaScript, but necessary)
    $url =~ s/\&job=(\d+)/\&job=$jobStart/;
    return $url;
}

sub newHitX {
    my $self = new WWW::Search::Scraper::Response::Job::FlipDog;
    return $self;
}
    

{ package WWW::Search::Scraper::Response::Job::FlipDog;
use vars qw(@ISA);
@ISA = qw(WWW::Search::Scraper::Response::Job);

sub resultTitles {
    my $self = shift;
    my $resultT = $self->SUPER::resultTitles();
    $$resultT{'companyProfileURL'} = 'companyProfileURL';
    $$resultT{'companyURL'} = 'companyURL';
    $$resultT{'jobCategory'} = 'Job Category';
    $$resultT{'jobType'} = 'Job Type';
    return $resultT;
}

sub results {
    my $self = shift;
    my $results = $self->SUPER::results();
    $$results{'companyProfileURL'} = $self->companyProfileURL();
    $$results{'companyURL'} = $self->companyURL();
    $$results{'jobCategory'} = $self->jobCategory();
    $$results{'jobType'} = $self->jobType();
    return $results;
}

sub companyProfileURL { return $_[0]->_elem('title'); }
sub companyURL { return $_[0]->_elem('title'); }
sub jobCategory { return $_[0]->_elem('jobCategory'); }
sub jobType { return $_[0]->_elem('jobType'); }
}


1;

__END__
=pod

=head1 NAME

WWW::Search::Scraper::FlipDog - class for searching www.FlipDog.com


=head1 SYNOPSIS

    use WWW::Search::Scraper;
    use WWW::Search::Scraper::Response::Job;

    $search = new WWW::Search::Scraper('FlipDog');

    $search->setup_query($query, {options});

    while ( my $response = $scraper->next_response() ) {
        # $response is a WWW::Search::Scraper::Response::Job.
    }

=head1 DESCRIPTION

FlipDog extends WWW::Search::Scraper.

It handles making and interpreting FlipDog searches of F<http://www.FlipDog.com>.


=head1 OPTIONS

=over 8

=item loc

Many, many strings are allowed. Locations are categorized by state.
See FlipDog.com for these option values ("3648 locations!" as of June 2001)

=item cat

      --- All Categories ---
      Clerical/Administrative
      Computing/MIS
      Customer Service/Support
      Education/Training
      Engineering
      Financial Services
      Government/Non Profit
      Health Care
      Human Resources
      Manufacturing/Business Operations
      Marketing/Advertising
      Media
      Other
      Professional Services
      Sales
      Travel/Hospitality

To this you need to add a "-" and the "job function", or
you may specify "All Job Functions in Category" by leaving off the "-" and "job function".
 
The options for job function are dependant on the Job Category, so
for some of the categories the functions are:

=back

=over 16

=item Clerical/Administrative

    Other

=item Computing/MIS

    Database Administration
    Internet Development
    Network/System Administration
    Other
    Quality Assurance/Testing
    Software Development
    Systems Analysis
    Technical Support/Help Desk

=item Customer Service/Support

    Other

=item Education/Training

  Colleges/Universities
  K to 12 Education
  Other
  Technical/Trade Schools
  Training   

=item Engineering

  Chemical
  Civil
  Design/Industrial
  Electrical/Hardware
  Mechanical
  Operations
  Other   

=item Financial Services

  Accounting
  Banking
  Finance
  Insurance
  Other
  Securities/Asset Management   

=item Government/Non Profit

    Other

=item Health Care
 
  Administration
  Medical
  Nursing
  Other
  Pharmaceutical   

=item Human Resources

    Other

=item Manufacturing/Business Operations
 
  Construction/Trades
  Facilities Management
  Logistics/Distribution
  Manufacturing
  Other
  Program/Project Management
  Purchasing   

=item Marketing/Advertising
 
  Advertising
  Market Research
  Marketing Communications
  Other
  Product Management
  Public Relations   

=item Media
 
  Broadcasting
  Graphic Arts/Design
  Journalism
  Other
  Publishing/Technical Writing   

=item Other

    Other

=item Professional Services
 
  Legal Services
  Management Consulting
  Other   

=item Sales
 
  Account Management
  Business Development
  Direct Sales
  Merchandising/Retail
  Other   

=item Travel/Hospitality
 
  Other
  Restaurant/Food Services
  Travel/Recreation/Lodging   

=back

=head1 AUTHOR

C<WWW::Search::FlipDog> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



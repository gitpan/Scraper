
package WWW::Search::Scraper::FlipDog;

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

To this you need to add a "-" and the "job function". 
The options for job function are dependant on the Job Category, so
for some of the categories the functions are:

=back

=over 16

=item Clerical/Administrative

    --- All Job Functions in Category ---
    Other

=item Computing/MIS

    --- All Job Functions in Category ---
    Database Administration
    Internet Development
    Network/System Administration
    Other
    Quality Assurance/Testing
    Software Development
    Systems Analysis
    Technical Support/Help Desk

=item Customer Service/Support

    --- All Job Functions in Category ---
    Other

=item Education/Training

  --- All Job Functions in Category ---
  Colleges/Universities
  K to 12 Education
  Other
  Technical/Trade Schools
  Training   

=item Engineering

  --- All Job Functions in Category ---
  Chemical
  Civil
  Design/Industrial
  Electrical/Hardware
  Mechanical
  Operations
  Other   

=item Financial Services

  --- All Job Functions in Category ---
  Accounting
  Banking
  Finance
  Insurance
  Other
  Securities/Asset Management   

=item Government/Non Profit

    --- All Job Functions in Category ---
    Other

=item Health Care
 
  --- All Job Functions in Category ---
  Administration
  Medical
  Nursing
  Other
  Pharmaceutical   

=item Human Resources

    --- All Job Functions in Category ---
    Other

=item Manufacturing/Business Operations
 
  --- All Job Functions in Category ---
  Construction/Trades
  Facilities Management
  Logistics/Distribution
  Manufacturing
  Other
  Program/Project Management
  Purchasing   

=item Marketing/Advertising
 
  --- All Job Functions in Category ---
  Advertising
  Market Research
  Marketing Communications
  Other
  Product Management
  Public Relations   

=item Media
 
  --- All Job Functions in Category ---
  Broadcasting
  Graphic Arts/Design
  Journalism
  Other
  Publishing/Technical Writing   

=item Other

    --- All Job Functions in Category ---
    Other

=item Professional Services
 
  --- All Job Functions in Category ---
  Legal Services
  Management Consulting
  Other   

=item Sales
 
  --- All Job Functions in Category ---
  Account Management
  Business Development
  Direct Sales
  Merchandising/Retail
  Other   

=item Travel/Hospitality
 
  --- All Job Functions in Category ---
  Other
  Restaurant/Food Services
  Travel/Recreation/Lodging   

=back

=head1 AUTHOR

C<WWW::Search::FlipDog> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.41 trimLFs trimLFLFs));
require WWW::SearchResult;


# SAMPLE
# http://www.flipdog.com/js/jobsearch-results.html?loc=CA-San+Jose+Area&cat=Computing%2FMIS-Software+Development&srch=Perl&job=1
#
sub native_setup_search
{
    my $self = shift;
    my ($native_query, $native_options_ref) = @_;
    
    $self->{'_options'}{'scraperQuery'} =
    [ 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,'http://www.flipdog.com/js/jobsearch-results.html?'
      # This names the native input field to recieve the query string.
     ,{'scraperQuery' => 'srch'
      }
      # Some more options for the Scraper operation.
     ,{'cookies' => 0
      }
    ];

    # Initialize other optional fields, for completeness and edification.
    $self->{'_options'}{'loc'} = 'CA-San Jose Area';
    $self->{'_options'}{'cat'} = 'Computing/MIS-Software Development';
    $self->{'_options'}{'job'} = '1'; # this is the initial index into the job list.

    # scraperFrame describes the format of the result page.
    $self->{'_options'}{'scrapeFrame'} = 
[ 'HTML', 
    [ 
        [ 'COUNT', 'var jobTotal = (\d+)' ]
       ,[ 'NEXT', \&getNextPage ]
       ,[ 'BODY', 'jobs shown below', undef,
            [  
                [ 'TR', '#1' ]
               ,[ 'HIT*', 
                    [ 
                        [ 'TR', 
                            [
                                [ 'TD', [ [ 'A', 'companyProfileURL', undef ] ] ]
                               ,[ 'TD', 
                                   [
                                      [ 'A', 'url', 'title', \&trimLFs ]
                                     ,[ 'A', 'companyURL', undef ]
                                     ,[ 'DIV' ]
                                     ,[ 'DIV', 'description' ]
                                   ]
                                ]
                               ,[ 'TD' ]
                               ,[ 'TD', 'location', \&parseLocation ]
                               ]
                        ]
                       ,[ 'TR', '#1' ]
                    ]
                ]
               ,[ 'BOGUS', -2 ] # The last two hits are bogus.
            ]
        ]
    ]
];            

    # WWW::Search::Scraper understands all that and will setup the search.
    return $self->SUPER::native_setup_search(@_);
}



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
    
    return undef unless 
        $dat =~ m/var jobCount = (\d+).*?var jobStart = (\d+).*?var jobTotal = (\d+)/s;
    my ($jobCount, $jobStart, $jobTotal) = ($1,$2,$3);
    my $url = $self->{'_last_url'};
    $jobStart += $jobCount;
    return undef if $jobStart > $jobTotal; # (not represented in the JavaScript, but necessary)
    $url =~ s/\&job=(\d+)/\&job=$jobStart/;
    return $url;
}


# We're going to subclass this response since there are some extra fields on FlipDog.
use WWW::Search::Scraper::Response::Job;
sub newHit {
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

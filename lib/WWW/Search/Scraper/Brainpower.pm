
package WWW::Search::Scraper::Brainpower;

#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.43 trimLFs trimLFLFs));
use WWW::Search::Scraper::FieldTranslation(1.00);


# SAMPLE
# http://www.flipdog.com/js/jobsearch-results.html?loc=CA-San+Jose+Area&cat=Computing%2FMIS-Software+Development&srch=Perl&job=1
#
sub native_setup_search
{
    my $self = shift;
    my ($native_query, $native_options_ref) = @_;
    
    $self->{'_options'}{'scraperQuery'} =
    [ 'QUERY'       # Queries should be 'QUERY', not 'POST', otherwise 2nd, 3rd, etc pages are "Object Moved".
      # This is the basic URL on which to build the query.
     ,'http://www.brainpower.com/IndListProject.asp?'
      # This names the native input field to recieve the query string.
     ,{  'nativeQuery' => 'skills'
        ,'nativeDefaults' =>
                        {    'navItem' => 'searchprojects'  # This is a hidden field, presumably declares "search"
                            ,'submit1' => 1                 # This is the actual submit button.
                            ,'title'   => 'ALL'             # All job designations.
                            #,'title' => 'AP'               # Application Programmer.
                            ,'searchType' => 1              # searchType = ANY words.
                            ,'state'      => 80             # All US States
                            #,'state' => 5                  # California (North)
                            ,'rate' => ''
                        }
        ,'fieldTranslations' =>
                { '*' => 
                        {    'skills'    => 'skills'
                            ,'payrate'   => \&translatePayrate
                            ,'locations' => new WWW::Search::Scraper::FieldTranslation('Brainpower', 'Job', 'locations')
                            ,'native_query' => 'skills'
                            ,'*'         => '*'
                        }
                }
      }
      # Some more options for the Scraper operation.
     ,{'cookies' => 1
      }
    ];

    # scraperFrame describes the format of the result page.
    $self->{'_options'}{'scrapeFrame'} = 
[ 'HTML', 
    [ 
        [ 'COUNT', 'Your search resulted in <b>([0-9,]+)</b> jobs.' ]
       ,[ 'NEXT', 'Next&nbsp;' ]
       ,[ 'BODY', '<!-- Begin Nested Right Table Cell -->', undef,
            [  
               [ 'TABLE', 
                 [
                   [ 'TABLE', 
                      [
                          ['TR', '#1' ],
                         ,[ 'HIT*', 'Job',
                             [ 
                                 [ 'TR', 
                                     [
                                         [ 'TD', [ [ 'A', 'url', undef ] ] ]
                                        ,[ 'TD' ] # There's a TD in a COMMENT, here ! ! ! all are "Any Designation".
                                        ,[ 'TD', 'title' ]
                                        ,[ 'TD', 'status' ]
                                        ,[ 'TD', 'location' ]
                                     ]
                                 ]
                                ,[ 'TR' ]
                             ]
                            ,[ 'BOGUS', -1 ]
                          ]
                      ]
                   ]
                 ]
               ]
            ]
        ]
    ]
];            

    # scrapeDetail describes the format of the detail page.
    $self->{'_options'}{'scrapeDetail'} = 
        [ 'HTML', 
            [ 
                [ 'BODY', '<!-- Begin Nested Right Table Cell -->', undef,
                    [  
                        [ 'TABLE', 
                           [
                              [ 'TABLE', 
                              [
                                  [ 'TR', '#3' ]
                                 ,[ 'HIT', 'Job',
                                     [ 
                                         [ 'TR', [[ 'TD' ],[ 'TD', 'title'    ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'role'     ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'skillSet' ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'type'     ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'payrate'  ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'length'   ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'city'     ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'state'    ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'postDate' ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'description' ]] ]
                                     ]
                                  ]
                              ]
                              ]
                           ]
                        ]
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

# Translate from the canonical Request->payrate to Brainpower's 'rate' option.
sub translatePayrate {
    my ($self, $rqst, $val) = @_;
    return ('rate', $val);
}



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Given a candidate hit, do post-selection.
# Return 1 to keep this hit, 0 to cast it away.
sub postSelect {
    my ($scraper, $rqst, $rslt) = @_;
    
    # Do the base postSelect, sans locations.
    return 0 unless $rqst->postSelect($scraper, $rslt, ['locations']);
    
    # Go scrape the data from the details page.
    my $detail = $rslt->content;
    $scraper->scraper($scraper->{'_options'}{'scrapeDetail'}[1], \$detail, $rslt, 0);
    
    # Brainpower's too dumb to put the location in the results, we have to look at details!
    return $scraper->SUPER::postSelect($rqst, $rslt);
}


{ package WWW::Search::Scraper::Response::Job::Brainpower;
use vars qw(@ISA);
@ISA = qw(WWW::Search::Scraper::Response::Job);

sub resultTitles {
    my $self = shift;
    my $resultT = {}; #$self->SUPER::resultTitles();
    $$resultT{'url'}      = 'url';
    $$resultT{'title'}    = 'Title';
    $$resultT{'status'}   = 'Status';
    $$resultT{'location'} = 'Location';
    $$resultT{'city'}     = 'City';
    return $resultT;
}

sub results {
    my $self = shift;
    my $results = {}; #$self->SUPER::results();
    $$results{'url'} = $self->url();
    $$results{'title'} = $self->title();
    $$results{'status'} = $self->status();
    $$results{'location'} = $self->location();
    $$results{'city'} = $self->city();
    return $results;
}

sub city     { return $_[0]->_elem('city'); }
sub status   { return $_[0]->_elem('status'); }
sub location { my $x = $_[0]->SUPER::location(); $x =~ s/\s+$//g; return $x;}
}


1;
__END__

=head1 NAME

WWW::Search::Scraper::Brainpower - class for searching www.Brainpower.com


=head1 SYNOPSIS

    use WWW::Search::Scraper;
    use WWW::Search::Scraper::Response::Job;

    $search = new WWW::Search::Scraper('Brainpower');

    $search->setup_query($query, {options});

    while ( my $response = $scraper->next_response() ) {
        # $response is a WWW::Search::Scraper::Response::Job.
    }

=head1 DESCRIPTION

Brainpower extends WWW::Search::Scraper.

It handles making and interpreting Brainpower searches of F<http://www.Brainpower.com>.


=head1 OPTIONS

=over 8

=head2 title

=over 8

=item ALL => Any Designation

=item AP  => Application Programmer                            

=item BA  => Business Analyst                                  

=item CS  => Communications Programmer                         

=item DBA => DataBase Administrator                            

=item DSP => DataBase Programmer                               

=item GCD => Graphic Designer                                  

=item HAD => Hardware/ASIC Programmer                          

=item JD  => Java Developer                                    

=item LAN => LAN/Network Administrator                         

=item PML => Project Manager/leader                            

=item QAT => Quality Assurance/Tester                          

=item SPS => Systems Programmer                                

=item SYA => Systems Administrator                             

=item TR  => Technical Recruiter                               

=item TW  => Technical Writer                                  

=item WEB => Web Developer                                     

=back

=head2 skills

This is the query string. You do not explicitly set this; it's set by Scraper.

=head2 searchType

A RADIO button.

=over 8

=item 0 - All of the words

=item 1 - Any of the words

=back

=head2 rate

Hourly rate, limit 3 digits. Optional.

=head2 state (MULTIPLE - maximum 5 states)

=over 8

=item 80 => All US States                                     

=item 1 => Alabama                                           

=item 2 => Alaska                                            

=item 3 => Arizona                                           

=item 4 => Arkansas                                          

=item 5 => California(North)                                 

=item 6 => California(South)                                 

=item 7 => Colorado                                          

=item 8 => Connecticut                                       

=item 9 => Delaware                                          

=item 10 => District of Columbia                              

=item 11 => Florida                                           

=item 12 => Georgia                                           

=item 13 => Hawaii                                            

=item 14 => Idaho                                             

=item 15 => Illinois                                          

=item 16 => Indiana                                           

=item 17 => Iowa                                              

=item 18 => Kansas                                            

=item 19 => Kentucky                                          

=item 20 => Louisiana                                         

=item 21 => Maine                                             

=item 22 => Maryland                                          

=item 23 => Massachusetts                                     

=item 24 => Michigan                                          

=item 25 => Minnesota                                         

=item 26 => Mississippi                                       

=item 27 => Missouri                                          

=item 28 => Montana                                           

=item 29 => Nebraska                                          

=item 30 => Nevada                                            

=item 31 => New Hampshire                                     

=item 32 => New Jersey                                        

=item 33 => New Mexico                                        

=item 34 => New York                                          

=item 35 => North Carolina                                    

=item 36 => North Dakota                                      

=item 37 => Ohio                                              

=item 38 => Oklahoma                                          

=item 39 => Oregon                                            

=item 40 => Pennsylvania                                      

=item 41 => Rhode Island                                      

=item 42 => South Carolina                                    

=item 43 => South Dakota                                      

=item 44 => Tennessee                                         

=item 45 => Texas                                             

=item 46 => Utah                                              

=item 47 => Vermont                                           

=item 48 => Virginia                                          

=item 49 => Washington                                        

=item 50 => West Virginia                                     

=item 51 => Wisconsin                                         

=item 52 => Wyoming                                           

=back

=head1 AUTHOR

C<WWW::Search::Brainpower> is written and maintained
by Glenn Wood, <glenwood@alumni.caltech.edu>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



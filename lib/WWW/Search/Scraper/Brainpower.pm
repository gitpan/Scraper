
package WWW::Search::Scraper::Brainpower;

#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.48 trimLFs trimLFLFs));
use WWW::Search::Scraper::FieldTranslation(1.00);
use WWW::Search::Scraper::Request::Job(1.00);

my $scraperQuery = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
      ,'url' => 'http://www.brainpower.com/IndListProject.asp?'
      # This is the Scraper attributes => native input fields mapping
      ,'nativeQuery' => 'skills'
      ,'nativeDefaults' =>
                      {    'navItem' => 'searchProjects'  # This is a hidden field, presumably declares "search"
                          ,'submit1' => 1                 # This is the actual submit button.
                          #,'pageSize' => 100              # pageSize has no effect on Brainpower.com
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
                          ,'*'         => '*'
                      }
              }
      # Some more options for the Scraper operation.
     ,'cookies' => 1
   };

my $scraperFrame =
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
                         ,[ 'HIT*', #'Job::Brainpower',
                             [ 
                                 [ 'TR', 
                                     [
                                         [ 'TD', [ [ 'A', 'url', 'jobID' ] ] ]
                                        ,[ 'TD' ] # There's a TD in a <!--COMMENT-->, here ! ! ! all are "Any Designation". E.G., <!--<TD><H6>&nbsp;&nbsp;&nbsp;&nbsp;TITLE</H6></TD>-->
                                        ,[ 'TD', 'skills' ]
                                        ,[ 'TD', 'payrate' ]
                                        ,[ 'TD', 'location' ]
                                     ]
                                 ]
                                ,[ 'TR' ]
                             ]
                          ]
#                         ,[ 'BOGUS', 1 ]  #Bogus result at the beginning . . .
                         ,[ 'BOGUS', -1 ] # and at the end!
                      ]
                   ]
                 ]
               ]
            ]
        ]
    ]
];            


    # scraperDetail describes the format of the detail page.
my $scraperDetail = 
        [ 'HTML', 
            [ 
                [ 'BODY', '<!-- Begin Nested Right Table Cell -->', undef,
                    [  
                        [ 'TABLE', 
                           [
                              [ 'TABLE', 
                              [
                                  [ 'TR', '#3' ]
                                 ,[ 'HIT', 
                                     [ 
                                         [ 'TR', [[ 'TD' ],[ 'TD', 'title'    ]] ] # this is a more descriptive title than from the results page.
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'role'     ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'skillSet' ]] ] # this replaces the lost results page 'title'.
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'type'     ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'city'     ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'state'    ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'postDate' ]] ]
                                        ,[ 'TR' ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'description' ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'FX' ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'FY' ]] ]
                                        ,[ 'TR', [[ 'TD' ],[ 'TD', 'FZ' ]] ]
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



sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'isNotTestable' => '' 
                ,'testNativeQuery' => 'Perl'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 41
                ,'expectedBogusPage' => 3
                ,'usesPOST' => 1
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperQuery { $scraperQuery }
sub scraperFrame { $scraperFrame }
sub scraperDetail{ $scraperDetail }

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
    
    # Brainpower's too dumb to put the location in the results, we have to look at details!
    return $scraper->SUPER::postSelect($rqst, $rslt);
}


{ package WWW::Search::Scraper::Response::Job::Brainpower;
use vars qw(@ISA);
@ISA = qw(WWW::Search::Scraper::Response::Job);
use WWW::Search::Scraper::Response::Job;

sub resultTitles {
    my $self = shift;
    my $resultT = {}; #$self->SUPER::resultTitles();
    
    # These fields are from the results page.
    $$resultT{'url'}      = 'url';
    $$resultT{'skills'}    = 'Skills';
    $$resultT{'jobID'}   = 'Job ID';
    $$resultT{'location'} = 'Location';
    
    return $resultT if $self->{'_scraperSkipDetailPage'};
    
    # The following fields come from the detail page.
    $$resultT{'role'}     = 'Role';
    $$resultT{'skillSet'} = 'Skill Set';
    $$resultT{'type'}     = 'Type';
    $$resultT{'payrate'}  = 'Payrate';
    $$resultT{'city'}     = 'City';
    $$resultT{'state'}    = 'State';
    $$resultT{'postDate'} = 'Post Date';
    $$resultT{'description'} = 'Description';

    return $resultT;
}

sub results {
    my $self = shift;
    my $results = {}; #$self->SUPER::results();
    
    # These fields are from the results page.
    $$results{'url'} = $self->url();
    $$results{'jobID'} = $self->jobID();
    $$results{'skills'} = $self->skills();
    $$results{'location'} = $self->location();
    $$results{'city'} = $self->city();
    return $results if $self->{'_scraperSkipDetailPage'};
    
    # The following fields come from the detail page.
    for ( qw(role skillSet type payrate state postDate description) ) {
        $$results{$_} = $self->$_();
    }
    return $results;
}

sub jobID     { return $_[0]->_elem('jobID'); }
sub skills     { return $_[0]->_elem('skills'); }
sub location { my $x = $_[0]->SUPER::location(); $x =~ s/\s+$//g; return $x;}

# 'title' is bi-modal, since detail page may give a better title that the results page.
sub title { $_[0]->ScrapeDetailPage('title'); return $_[0]->_elem('title'); }

# The following fields come from the detail page.
sub role        { return $_[0]->ScrapeDetailPage('role') }
sub skillSet    { return $_[0]->ScrapeDetailPage('skillSet') }
sub type        { return $_[0]->ScrapeDetailPage('type') }
sub payrate     { return $_[0]->ScrapeDetailPage('payrate') }
sub length      { return $_[0]->ScrapeDetailPage('length') }
sub city        { return $_[0]->ScrapeDetailPage('city') }
sub state       { return $_[0]->ScrapeDetailPage('state') }
sub postDate    { return $_[0]->ScrapeDetailPage('postDate') }
sub description { my $rslt = $_[0]->ScrapeDetailPage('description');
# Hey, if some of those bubble-heads at the KBDs want to put in a few hundred spaces, then !%^&!* them!
    $rslt =~ s/\s\s\s\s\s\s\s/\s/g;
# The same goes for massive doses of <br>s. What is it with these people?
    $rslt =~ s/\n\n/\n/g;
    return $rslt;
 }

sub FX { return $_[0]->ScrapeDetailPage('FX') }
sub FY { return $_[0]->ScrapeDetailPage('FY') }
sub FZ { return $_[0]->ScrapeDetailPage('FZ') }

}


1;
__END__

=pod

=head1 NAME

WWW::Search::Scraper::Brainpower -  Brainpower.com(skills,locations,payrate) => (title,role,skillSet,type,city,state,postDate,description,FX,FY,FZ)


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
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


